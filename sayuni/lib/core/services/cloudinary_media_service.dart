import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Uploads church media (sermon audio, kwaya recordings, tenzi, photos) to
/// Cloudinary using an **unsigned upload preset** — the same account and preset
/// used by the Sayuni web portal (`sayuni-portal/src/services/cloudinaryService.ts`).
///
/// Design rules (do not regress these):
///  * An upload either returns a real `https://res.cloudinary.com/...` URL or it
///    throws [CloudinaryUploadException]. There is deliberately **no** fallback to
///    a local device path: a local path plays for the admin only and is dead for
///    every other member.
///  * Every network call has a timeout, so the admin sheet can never hang on
///    "Inapakia…" forever.
///  * Credentials are not secrets (unsigned preset = public, write-scoped by the
///    preset itself), but they are configurable so a church can point at its own
///    cloud without rebuilding:
///      1. in-app admin settings (SharedPreferences),
///      2. `--dart-define=CLOUDINARY_CLOUD_NAME=... --dart-define=CLOUDINARY_UPLOAD_PRESET=...`,
///      3. the built-in defaults below.
///  * Unsigned uploads cannot report byte-level progress through `package:http`,
///    so the UI shows size + elapsed time instead of a fake percentage.
///
/// Before production: create the preset in Cloudinary → Settings → Upload →
/// Upload presets → *Add upload preset* (Signing mode: **unsigned**),
/// tick "Raw file uploads", set a Max file size, and restrict Origins to the app
/// domain so the browser CORS pre-flight is accepted. Move privileged uploads to
/// a signed Cloud Function (see PLAN.md).

/// Which kind of asset is being uploaded; maps to Cloudinary's resource type.
enum CloudinaryMediaKind { audio, video, image }

/// Why an upload failed, in a form the UI can explain in Swahili.
enum CloudinaryFailureKind {
  notConfigured,
  fileTooLarge,
  network,
  timeout,
  badPreset,
  forbidden,
  badFile,
  rateLimited,
  server,
  rejected,
  unreadable,
}

/// A failure that can be shown to an admin verbatim.
class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.kind, this.message, {this.detail});

  final CloudinaryFailureKind kind;
  final String message;
  final String? detail;

  @override
  String toString() =>
      detail == null || detail!.isEmpty ? message : '$message — $detail';
}

/// Result of a successful upload.
class CloudinaryUploadOutcome {
  const CloudinaryUploadOutcome({
    required this.url,
    required this.publicId,
    required this.resourceType,
    required this.bytes,
    required this.elapsed,
    this.format,
  });

  /// Playable/downloadable `https://res.cloudinary.com/...` URL.
  final String url;
  final String publicId;
  final String resourceType;
  final int bytes;
  final Duration elapsed;
  final String? format;

  bool get isPlayable => url.startsWith('https://');
  String get sizeLabel {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Resolved Cloudinary destination.
class CloudinaryConfig {
  const CloudinaryConfig({required this.cloudName, required this.uploadPreset});

  static const String defaultCloudName = 'zion-fellowship';
  static const String defaultUploadPreset = 'zion_unsigned';

  /// SharedPreferences keys (also editable from the admin settings sheet).
  static const String cloudNameKey = 'setting_cloudinary_cloud_name';
  static const String uploadPresetKey = 'setting_cloudinary_upload_preset';

  final String cloudName;
  final String uploadPreset;

  /// True when both halves exist and look like identifiers, i.e. an upload can
  /// realistically succeed. Anything else must be reported, not guessed around.
  bool get isUsable =>
      cloudName.trim().isNotEmpty &&
      uploadPreset.trim().isNotEmpty &&
      !cloudName.contains(' ') &&
      !uploadPreset.contains(' ');

  String get label => '$cloudName / $uploadPreset';

  static String _clean(String? raw, String fallback) {
    final value = (raw ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  /// Reads prefs first, then `--dart-define`, then the defaults.
  static Future<CloudinaryConfig> load() async {
    const fromDefineCloud =
        String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: '');
    const fromDefinePreset =
        String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: '');
    try {
      final prefs = await SharedPreferences.getInstance();
      return CloudinaryConfig(
        cloudName: _clean(
          prefs.getString(cloudNameKey),
          fromDefineCloud.isNotEmpty ? fromDefineCloud : defaultCloudName,
        ),
        uploadPreset: _clean(
          prefs.getString(uploadPresetKey),
          fromDefinePreset.isNotEmpty ? fromDefinePreset : defaultUploadPreset,
        ),
      );
    } catch (_) {
      // Prefs can be unavailable in a sandboxed web frame; fall back to defaults
      // instead of blocking the upload screen.
      return const CloudinaryConfig(
        cloudName: defaultCloudName,
        uploadPreset: defaultUploadPreset,
      );
    }
  }

  static Future<void> save({String? cloudName, String? uploadPreset}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (cloudName != null) {
        final value = cloudName.trim();
        if (value.isEmpty) {
          await prefs.remove(cloudNameKey);
        } else {
          await prefs.setString(cloudNameKey, value);
        }
      }
      if (uploadPreset != null) {
        final value = uploadPreset.trim();
        if (value.isEmpty) {
          await prefs.remove(uploadPresetKey);
        } else {
          await prefs.setString(uploadPresetKey, value);
        }
      }
    } catch (_) {
      // Saving settings must never break the media UI.
    }
  }

  /// Cloudinary resource type segment for [kind]. Audio must go through `raw`:
  /// Cloudinary does not transcode audio and `image`/`video` would reject mp3.
  static String resourceTypeFor(CloudinaryMediaKind kind) {
    switch (kind) {
      case CloudinaryMediaKind.audio:
        return 'raw';
      case CloudinaryMediaKind.video:
        return 'video';
      case CloudinaryMediaKind.image:
        return 'image';
    }
  }
}

class CloudinaryMediaService {
  const CloudinaryMediaService._();

  /// Kept for existing call sites that referenced the built-in defaults.
  static const String cloudName = CloudinaryConfig.defaultCloudName;
  static const String uploadPreset = CloudinaryConfig.defaultUploadPreset;

  /// Cloudinary's unsigned endpoint refuses very large files; presets usually
  /// cap far below this. Anything above is rejected locally with an explanation.
  static const int maxUploadBytes = 200 * 1024 * 1024;

  /// Audio can be a long sermon; a 3-minute timeout killed good uploads on slow
  /// connections, so the budget scales with the file size.
  static Duration timeoutFor(int bytes) {
    final minutes = 4 + (bytes / (6 * 1024 * 1024)).ceil();
    return Duration(minutes: minutes.clamp(4, 20));
  }

  /// Uploads [bytes] and returns the playable URL, or throws
  /// [CloudinaryUploadException] with a message that is safe to display.
  static Future<CloudinaryUploadOutcome> uploadBytes({
    required Uint8List bytes,
    required String filename,
    required CloudinaryMediaKind kind,
    String folder = 'zion_church_media',
    CloudinaryConfig? config,
  }) async {
    if (filename.trim().isEmpty) {
      throw const CloudinaryUploadException(
        CloudinaryFailureKind.badFile,
        'Faili halina jina. Chagua faili tena.',
      );
    }
    if (bytes.isEmpty) {
      throw const CloudinaryUploadException(
        CloudinaryFailureKind.unreadable,
        'Faili hili halina maudhui (0 KB). Chagua faili tena.',
      );
    }
    if (bytes.length > maxUploadBytes) {
      throw CloudinaryUploadException(
        CloudinaryFailureKind.fileTooLarge,
        'Faili ni kubwa mno kwa Cloudinary (${(bytes.length / (1024 * 1024)).toStringAsFixed(0)} MB). '
        'Upeo wa juu ni ${(maxUploadBytes / (1024 * 1024)).toStringAsFixed(0)} MB — '
        'punguza saizi (compress) kwanza.',
      );
    }

    final cfg = config ?? await CloudinaryConfig.load();
    if (!cfg.isUsable) {
      throw const CloudinaryUploadException(
        CloudinaryFailureKind.notConfigured,
        'Cloudinary haijapangwa: weka Cloud Name na Upload Preset kwenye '
        'Mipangilio ya Upakiaji (au --dart-define).',
      );
    }

    final resourceType = CloudinaryConfig.resourceTypeFor(kind);
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${cfg.cloudName}/$resourceType/upload',
    );
    final deadline = timeoutFor(bytes.length);
    final stopwatch = Stopwatch()..start();

    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = cfg.uploadPreset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename),
        );

      final streamed = await request.send().timeout(deadline);
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 20));
      stopwatch.stop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = _tryDecode(response.body);
        final url =
            (decoded?['secure_url'] ?? decoded?['url'] ?? '').toString();
        if (!url.startsWith('http')) {
          throw const CloudinaryUploadException(
            CloudinaryFailureKind.rejected,
            'Cloudinary imetujibu lakini bila kiungo cha faili.',
          );
        }
        return CloudinaryUploadOutcome(
          url: url,
          publicId: (decoded?['public_id'] ?? '').toString(),
          resourceType: (decoded?['resource_type'] ?? resourceType).toString(),
          format: decoded?['format']?.toString(),
          bytes: bytes.length,
          elapsed: stopwatch.elapsed,
        );
      }

      throw _mapStatus(response.statusCode, response.body);
    } on CloudinaryUploadException {
      rethrow;
    } on TimeoutException {
      stopwatch.stop();
      throw CloudinaryUploadException(
        CloudinaryFailureKind.timeout,
        'Upakiaji umechukua muda mrefu kupita (${(deadline.inSeconds / 60).round()} dk) '
        'na umehakikiwa. Jaribu tena kwenye mtandao bora, au pakia faili ndogo.',
        detail:
            'timeout ${deadline.inSeconds}s · ${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB',
      );
    } on http.ClientException catch (e) {
      throw CloudinaryUploadException(
        CloudinaryFailureKind.network,
        'Hakuna muungano na Cloudinary. Angalia mtandao wako (au CORS kwenye '
        'preset) kisha ujaribu tena.',
        detail: e.message,
      );
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      throw CloudinaryUploadException(
        CloudinaryFailureKind.network,
        'Upakiaji umeshindwa kwa sababu isiyotarajiwa.',
        detail: '$e',
      );
    }
  }

  /// Legacy shape used by older call sites: `null` instead of throwing.
  /// New code should use [uploadBytes] so failures are visible.
  static Future<String?> uploadMediaBytes({
    required Uint8List bytes,
    required String filename,
    String folder = 'zion_church_media',
    String resourceType = 'image',
  }) async {
    try {
      final outcome = await uploadBytes(
        bytes: bytes,
        filename: filename,
        kind: _kindFromResourceType(resourceType),
        folder: folder,
      );
      return outcome.url;
    } on CloudinaryUploadException catch (e) {
      debugPrint('Cloudinary upload warning: $e');
      return null;
    }
  }

  /// Folder per media section so the Cloudinary media library stays browsable.
  static String folderFor(String categorySlug) {
    final slug = categorySlug
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty
        ? 'zion_church_media/audio'
        : 'zion_church_media/audio/$slug';
  }

  static CloudinaryMediaKind _kindFromResourceType(String resourceType) {
    switch (resourceType) {
      case 'video':
        return CloudinaryMediaKind.video;
      case 'image':
        return CloudinaryMediaKind.image;
      default:
        return CloudinaryMediaKind.audio;
    }
  }

  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Turns a Cloudinary error payload into an honest, actionable message.
  static CloudinaryUploadException _mapStatus(int status, String body) {
    final decoded = _tryDecode(body);
    final raw = (decoded?['error']?['message'] ?? decoded?['message'] ?? '')
        .toString()
        .trim();
    final lower = raw.toLowerCase();

    CloudinaryUploadException build(CloudinaryFailureKind kind, String sw) =>
        CloudinaryUploadException(kind, sw, detail: raw.isEmpty ? null : raw);

    if (status == 401 || status == 403) {
      if (lower.contains('preset')) {
        return build(
          CloudinaryFailureKind.badPreset,
          'Upload preset haikubaliki kwenye Cloudinary. '
          'Fungua console → Settings → Upload presets: hakikisha preset iko kwa '
          'hali ya unsigned, na kwamba haizuii aina ya faili unayopakia.',
        );
      }
      return build(
        CloudinaryFailureKind.forbidden,
        'Cloudinary imekataza ruhusa (HTTP $status). Hakikisha Cloud Name ni sahihi.',
      );
    }
    if (status == 404) {
      return build(
        CloudinaryFailureKind.notConfigured,
        'Cloud Name haipatikani (HTTP 404). Badilisha Cloud Name kwenye Mipangilio ya Upakiaji.',
      );
    }
    if (status == 413) {
      return build(
        CloudinaryFailureKind.fileTooLarge,
        'Faili ni kubwa kuliko kikomo kilichowekwa kwenye preset (HTTP 413).',
      );
    }
    if (status == 420 || lower.contains('rate limit')) {
      return build(
        CloudinaryFailureKind.rateLimited,
        'Cloudinary imepunguza kasi yako (HTTP $status). Subiri dakika chache kisha ujaribu tena.',
      );
    }
    if (status >= 500) {
      return build(
        CloudinaryFailureKind.server,
        'Cloudinary ina tatizo la upande wao (HTTP $status). Jaribu tena baadaye.',
      );
    }
    if (lower.contains('invalid image') ||
        lower.contains('invalid video') ||
        lower.contains('unsupported') ||
        lower.contains('corrupt')) {
      return build(
        CloudinaryFailureKind.badFile,
        'Cloudinary haikubali faili hili. Tumia mp3, m4a, aac, wav au mp4.',
      );
    }
    if (lower.contains('raw') && lower.contains('not allowed')) {
      return build(
        CloudinaryFailureKind.badPreset,
        'Preset hii hairuhusu "Raw file uploads", ambazo audio inahitaji. '
        'Washa Raw uploads kwenye preset kisha ujaribu tena.',
      );
    }
    return build(
      CloudinaryFailureKind.rejected,
      'Cloudinary imekatalia upakiaji (HTTP $status).',
    );
  }
}
