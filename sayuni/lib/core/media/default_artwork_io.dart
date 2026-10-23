import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

String? resolvedFileUri;

/// Native implementation of the lock-screen/notification artwork fallback.
///
/// `audio_service` forwards `file://` artwork straight to the Android media
/// session and iOS Control Centre, but it cannot read `assets/...` URIs, so the
/// bundled Sayuni logo is copied once into app support storage.
Future<String?> resolveFileUri() async {
  if (resolvedFileUri != null) return resolvedFileUri;
  try {
    final data = await rootBundle.load('assets/images/zion_logo.png');
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/sayuni_audio_artwork.png');
    if (!await file.exists()) {
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    resolvedFileUri = Uri.file(file.path).toString();
  } catch (_) {
    // Notification still renders with the app's monochrome icon.
    resolvedFileUri = null;
  }
  return resolvedFileUri;
}
