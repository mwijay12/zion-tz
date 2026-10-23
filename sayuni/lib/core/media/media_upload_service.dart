import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'media_models.dart';

/// Upload plumbing for choir songs, hymns, sermons and other church audio.
///
/// The app has Firebase configured (`firebase_core`, `firebase_auth`,
/// `cloud_firestore`) but **no** `firebase_storage` dependency and no verified
/// storage bucket, so this file deliberately stops short of pretending uploads
/// work. It provides:
///
/// * [MediaUploadService] — the contract the admin UI will call;
/// * [StorageProvider] — the contract for the byte-storage backend;
/// * [LocalDraftMediaUploadService] — a working *local* implementation that
///   records metadata drafts on the device so the catalogue and player already
///   understand uploaded content;
/// * [UnconfiguredStorageProvider] — fails loudly with instructions instead of
///   silently dropping files.
///
/// ---------------------------------------------------------------------------
/// HOW TO FINISH THE BACKEND (pick ONE, then delete this note)
///
/// A. Firebase Storage + Firestore
///   1. `flutter pub add firebase_storage`
///   2. Console → Storage → create a bucket (the configured bucket is
///      `zion-mbagala-church.firebasestorage.app`); Firestore collection
///      `media_tracks`.
///   3. Implement [StorageProvider.upload] as
///      `FirebaseStorage.ref('media/$categoryId/${file.name}').putFile(file)`,
///      return `await ref.getDownloadURL()`, then write the metadata map from
///      [MediaUploadRequest.toMetadataMap] to
///      `FirebaseFirestore.instance.collection('media_tracks').doc(id)`.
///   4. Replace [UnconfiguredStorageProvider] with that class inside
///      `MediaUploadService.local()` and make
///      `SayuniMediaRepository.tracksIn()` read `media_tracks` (it already
///      merges the portal bridge, so nothing else has to change).
///   5. Rules: allow `read` for signed-in users, `write` only when
///      `request.auth.token.email in ['<pastor email>']` or a custom claim
///      `admin == true`. The app gates the UI with `ChurchAuthService().isAdmin`,
///      which is **not** a security boundary by itself.
///
/// B. Supabase Storage + Postgres
///   1. `flutter pub add supabase_flutter`
///   2. `supabase.storage.from('church-audio').upload(path, file)` →
///      `getPublicUrl(path)`, then insert the same metadata map into the
///      `media_tracks` table with the app's RLS policy for admins.
/// ---------------------------------------------------------------------------

/// Formats the player can decode. `wav` is accepted for archival but is large;
/// `mp3`/`m4a`/`aac` are what the radio/sermon catalogue already uses.
const List<String> kSupportedAudioExtensions = <String>[
  'mp3',
  'm4a',
  'aac',
  'wav'
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
  });

  final String title;
  final MediaCategory category;
  final String filePath;
  final String artist;
  final String description;
  final String? artworkPath;
  final Duration? duration;
  final List<String> tags;

  bool get hasValidExtension {
    final lower = filePath.toLowerCase();
    return kSupportedAudioExtensions.any((ext) => lower.endsWith('.$ext'));
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

/// Byte storage backend (Firebase Storage, Supabase Storage, S3, ...).
abstract class StorageProvider {
  const StorageProvider();

  /// Returns a publicly playable URL for [localPath].
  Future<String> upload({
    required String localPath,
    required String categoryId,
    required String fileName,
    void Function(double progress)? onProgress,
  });
}

/// Placeholder that refuses to upload and explains exactly what to add.
class UnconfiguredStorageProvider extends StorageProvider {
  const UnconfiguredStorageProvider();

  @override
  Future<String> upload({
    required String localPath,
    required String categoryId,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    throw UnsupportedError(
      'Hakuna storage iliyowekwa. Ongeza `firebase_storage` (au supabase_flutter) '
      'kwenye pubspec.yaml, panga bucket, kisha weka FirebaseStorageProvider '
      'kbdala ya UnconfiguredStorageProvider katika MediaUploadService.',
    );
  }
}

/// Upload contract used by the admin flow.
abstract class MediaUploadService {
  const MediaUploadService();

  /// Local-only implementation with no fake cloud calls. Swap the provider to
  /// enable real uploads (see the header of this file).
  factory MediaUploadService.local({StorageProvider? storage}) =>
      LocalDraftMediaUploadService(
          storage: storage ?? const UnconfiguredStorageProvider());

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
      return const MediaUploadResult.failure(
          'Faili hili halijumiwi. Tafadhali mp3, m4a, au aac.');
    }
    if (request.title.trim().isEmpty) {
      return const MediaUploadResult.failure('Weka jina la rekodi.');
    }

    final id = 'draft-${DateTime.now().millisecondsSinceEpoch}';
    try {
      final url = await storage.upload(
        localPath: request.filePath,
        categoryId: request.category.id,
        fileName: request.fileName,
      );
      final track = AudioTrack.fromMap(request.toMetadataMap(url, id));
      return MediaUploadResult.success(track);
    } on UnsupportedError catch (e) {
      // Expected until a storage provider is configured: keep the metadata so
      // the admin can finish the upload later, and say so honestly.
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
