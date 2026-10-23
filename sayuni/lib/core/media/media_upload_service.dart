import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/cloudinary_media_service.dart';
import 'media_models.dart';

/// Upload plumbing for choir songs, hymns, sermons and other church audio.
///
/// Bytes are stored in **Cloudinary** through [CloudinaryStorageProvider]
/// (unsigned preset, same cloud as the Sayuni web portal). A upload returns a
/// real `https://res.cloudinary.com/...` URL or it throws a
/// [CloudinaryUploadException] with a Swahili reason — it never pretends to have
/// succeeded, because a local file path would play for the admin and be dead
/// audio for every other member.
///
/// ---------------------------------------------------------------------------
/// UPLOAD PATHS IN THIS FILE
///
/// * [MediaUploadService.cloudinary] — the production path used by the admin
///   upload sheet: pick file → upload bytes to Cloudinary → publish metadata.
/// * [MediaUploadService.local] — metadata-only drafts (device storage) used
///   when Cloudinary is not configured, so nothing typed by the admin is lost.
///
/// Metadata is published into the `zion_admin_uploaded_media` record set (see
/// `ChurchSyncService.syncNewSermon`), which [SayuniMediaRepository] already
/// merges into the player sections and the web portal already reads.
///
/// ---------------------------------------------------------------------------
/// HARDENING TODO (production, tracked in PLAN.md)
///   1. Replace the unsigned preset with a signed upload route
///      (`media_assets` collection + Cloud Function) so writes can be gated by
///      the admin role; `ChurchAuthService().isAdmin` is UI gating only.
///   2. Optionally add `firebase_storage` + Firestore `media_tracks` and make
///      [SayuniMediaRepository.tracksIn] read the collection instead of the
///      local/portal bridge.
/// ---------------------------------------------------------------------------

/// Formats the player can decode. `wav` is accepted for archival but is large;
/// `mp3`/`m4a`/`aac` are what the radio/sermon catalogue already uses.
const List<String> kSupportedAudioExtensions = <String>[
  'mp3',
  'm4a',
  'aac',
  'wav'
];

/// Video the admin may attach to a sermon entry.
const List<String> kSupportedVideoExtensions = <String>[
  'mp4',
  'mov',
  'webm',
  'm4v'
];

/// Everything the admin fills in on the upload form.
class MediaUploadRequest {
  const MediaUploadRequest({
    required this.title,
    required this.category,
    required this.filePath,
    this.artist = '',
    this.description = '',
    this.artworkPath,
    this.duration,
    this.tags = const <String>[],
    this.bytes,
    this.isVideo = false,
  });

  final String title;
  final MediaCategory category;
  final String filePath;
  final String artist;
  final String description;
  final String? artworkPath;
  final Duration? duration;
  final List<String> tags;

  /// File content when it came from the device/browser picker. Cloudinary needs
  /// bytes (a device path is meaningless on another device and on web).
  final Uint8List? bytes;

  /// true for sermon video, false for audio (default).
  final bool isVideo;

  bool get hasValidExtension {
    final lower = filePath.toLowerCase();
    final allowed =
        isVideo ? kSupportedVideoExtensions : kSupportedAudioExtensions;
    return allowed.any((ext) => lower.endsWith('.$ext'));
  }

  String get fileName {
    final parts = filePath.split(RegExp(r'[\\/]'));
    return parts.isEmpty ? 'audio' : parts.last;
  }

  Map<String, dynamic> toMetadataMap(String storageUri, String id) =>
      <String, dynamic>{
        'id': id,
        'title': title,
        'url': storageUri,
        'audioUrl': storageUri,
        'artist': artist,
        'preacher': artist,
        'subtitle': description,
        'description': description,
        'category': category.label,
        'categoryId': category.id,
        'type': category.type.name,
        'isLive': category.liveOnly,
        'durationMs': duration?.inMilliseconds,
        'tags': tags,
        'artworkUrl': artworkPath,
        'uploadedAt': DateTime.now().toIso8601String(),
      };
}

/// Result of an upload attempt.
class MediaUploadResult {
  const MediaUploadResult.success(this.track)
      : error = null,
        isDraft = false;
  const MediaUploadResult.draft(this.track)
      : error = null,
        isDraft = true;
  const MediaUploadResult.failure(this.error)
      : track = null,
        isDraft = false;

  final AudioTrack? track;
  final String? error;

  /// True when the file was only stored locally because no backend is wired.
  final bool isDraft;

  bool get isSuccess => track != null;
}

/// Byte storage backend (Cloudinary today; Firebase/Supabase can be added).
abstract class StorageProvider {
  const StorageProvider();

  /// Returns a publicly playable `https://` URL for the file.
  ///
  /// [bytes] is what the picker read from the device. Providers that cannot
  /// work without it (everything remote) must throw rather than invent a URL.
  Future<String> upload({
    required String localPath,
    required String categoryId,
    required String fileName,
    Uint8List? bytes,
    bool isVideo = false,
    void Function(double progress)? onProgress,
  });
}

/// Real backend: unsigned Cloudinary upload (preset `zion_unsigned`).
class CloudinaryStorageProvider extends StorageProvider {
  const CloudinaryStorageProvider();

  @override
  Future<String> upload({
    required String localPath,
    required String categoryId,
    required String fileName,
    Uint8List? bytes,
    bool isVideo = false,
    void Function(double progress)? onProgress,
  }) async {
    final data = bytes;
    if (data == null || data.isEmpty) {
      throw const CloudinaryUploadException(
        CloudinaryFailureKind.unreadable,
        'Kifaa hakilitoe faili hili (0 bytes). Chagua faili tena.',
      );
    }
    final outcome = await CloudinaryMediaService.uploadBytes(
      bytes: data,
      filename: fileName,
      kind: isVideo ? CloudinaryMediaKind.video : CloudinaryMediaKind.audio,
      folder: CloudinaryMediaService.folderFor(categoryId),
    );
    onProgress?.call(1);
    return outcome.url;
  }
}

/// Placeholder that refuses to upload and explains exactly what to add.
class UnconfiguredStorageProvider extends StorageProvider {
  const UnconfiguredStorageProvider();

  @override
  Future<String> upload({
    required String localPath,
    required String categoryId,
    required String fileName,
    Uint8List? bytes,
    bool isVideo = false,
    void Function(double progress)? onProgress,
  }) async {
    throw const CloudinaryUploadException(
      CloudinaryFailureKind.notConfigured,
      'Hakuna storage iliyowekwa. Chagua Cloudinary (Mipangilio ya Upakiaji) '
      'au ongeza Firebase Storage kwenye MediaUploadService.',
    );
  }
}

/// Upload contract used by the admin flow.
abstract class MediaUploadService {
  const MediaUploadService();

  /// Local-only implementation with no fake cloud calls.
  factory MediaUploadService.local({StorageProvider? storage}) =>
      LocalDraftMediaUploadService(
          storage: storage ?? const UnconfiguredStorageProvider());

  /// Production path: bytes go to Cloudinary, metadata to the shared library.
  factory MediaUploadService.cloudinary() =>
      const LocalDraftMediaUploadService(storage: CloudinaryStorageProvider());

  Future<MediaUploadResult> submit(MediaUploadRequest request);

  /// Metadata drafts recorded on this device (not yet uploaded).
  Future<List<AudioTrack>> drafts();

  /// True when a real storage backend is attached.
  bool get isCloudReady;
}

class LocalDraftMediaUploadService extends MediaUploadService {
  const LocalDraftMediaUploadService(
      {this.storage = const UnconfiguredStorageProvider()});

  final StorageProvider storage;

  /// SharedPreferences key shared with the media repository.
  static const String draftsKey = 'zion_media_upload_drafts';

  @override
  bool get isCloudReady => storage is! UnconfiguredStorageProvider;

  @override
  Future<MediaUploadResult> submit(MediaUploadRequest request) async {
    if (!request.hasValidExtension) {
      return MediaUploadResult.failure(
        request.isVideo
            ? 'Faili hili halikubaliki. Tafadhali mp4, mov au webm.'
            : 'Faili hili halikubaliki. Tafadhali mp3, m4a, aac au wav.',
      );
    }
    if (request.title.trim().isEmpty) {
      return const MediaUploadResult.failure('Weka jina la rekodi.');
    }

    final cloudinary = storage is CloudinaryStorageProvider;
    final id = cloudinary
        ? 'admin-${DateTime.now().millisecondsSinceEpoch}'
        : 'draft-${DateTime.now().millisecondsSinceEpoch}';
    try {
      final url = await storage.upload(
        localPath: request.filePath,
        categoryId: request.category.id,
        fileName: request.fileName,
        bytes: request.bytes,
        isVideo: request.isVideo,
      );
      final track = AudioTrack.fromMap(request.toMetadataMap(url, id));
      return MediaUploadResult.success(track);
    } on CloudinaryUploadException catch (e) {
      if (e.kind != CloudinaryFailureKind.notConfigured) {
        // A real failure: report it verbatim. Never store a dead local path as
        // though the file had reached the members' devices.
        return MediaUploadResult.failure(e.toString());
      }
      // Nothing configured yet: keep the metadata so the admin can finish the
      // upload later, and say so honestly.
      final track = AudioTrack.fromMap(request.toMetadataMap('', id));
      await _remember(track);
      return MediaUploadResult.draft(
        track.copyWith(
            subtitle: 'Rasimu (haijapakiwa mtandaoni): ${e.message}'),
      );
    } catch (e) {
      return MediaUploadResult.failure('Upakiaji umeshindwa: $e');
    }
  }

  Future<void> _remember(AudioTrack track) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(draftsKey);
      final list = <Map<String, dynamic>>[
        if (raw != null && raw.isNotEmpty)
          ...(jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>(),
        track.toMap(),
      ];
      await prefs.setString(draftsKey, jsonEncode(list));
    } catch (_) {
      // A failed draft log must never block the media UI.
    }
  }

  @override
  Future<List<AudioTrack>> drafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(draftsKey);
      if (raw == null || raw.isEmpty) return const <AudioTrack>[];
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => AudioTrack.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (_) {
      return const <AudioTrack>[];
    }
  }
}
