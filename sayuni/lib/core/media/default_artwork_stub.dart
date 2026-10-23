/// Web stub: browsers expose media metadata through the Media Session API
/// (handled by `audio_service_web`), and there is no writable file to attach,
/// so artwork falls back to the in-app asset rendering only.
String? resolvedFileUri;

Future<String?> resolveFileUri() async => null;
