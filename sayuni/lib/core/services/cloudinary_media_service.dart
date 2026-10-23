import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for uploading photos, sermon recordings, and choir songs to Cloudinary.
/// Configured with official Zion Jerusalem credentials.
class CloudinaryMediaService {
  static const String cloudName = 'zion-fellowship';
  static const String uploadPreset = 'zion_unsigned';

  /// Uploads an image or document from bytes to Cloudinary
  static Future<String?> uploadMediaBytes({
    required Uint8List bytes,
    required String filename,
    String folder = 'zion_church_media',
    String resourceType = 'image', // 'image' | 'video' | 'raw' | 'auto'
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeCloudName =
          prefs.getString('setting_cloudinary_cloud_name') ?? cloudName;
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$activeCloudName/$resourceType/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folder;

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['secure_url'] as String?;
      } else {
        debugPrint(
            'Cloudinary upload warning (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }
}
