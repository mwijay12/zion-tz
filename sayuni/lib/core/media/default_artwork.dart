// Conditional implementation: `dart:io` + path_provider are only compiled on
// native targets, so the web build keeps the no-op stub.
import 'default_artwork_stub.dart'
    if (dart.library.io) 'default_artwork_io.dart' as impl;

/// Church artwork resolution shared by the mini-player, full-screen player,
/// Android media notification and iOS Control Centre.
///
/// The previous implementation pointed every fallback at a remote lion PNG.
/// Everything now falls back to the Sayuni logo bundled with the app.
class DefaultArtwork {
  DefaultArtwork._();

  /// Bundled Sayuni / Zion Jerusalem logo (the baked-in gold letter-ring is
  /// cropped in the UI with `Transform.scale(1.3) + BoxFit.cover`, exactly like
  /// the onboarding logo).
  static const String logoAsset = 'assets/images/zion_logo.png';

  /// Church hero photo, used as poster artwork for sermons/teaching.
  static const String churchAsset = 'assets/images/church_front.jpg';

  /// Choir rehearsal photo, used as artwork for kwaya content.
  static const String choirAsset =
      'assets/images/zion_worship_choir_1788577423671.jpg';

  /// `file://` URI of [logoAsset] copied into app storage, or null on web.
  static String? get fileUri => impl.resolvedFileUri;

  /// Warms [fileUri] up at startup. Safe to call repeatedly; never throws.
  static Future<String?> warmUp() => impl.resolveFileUri();
}
