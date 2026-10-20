import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/church_profile.dart';

ImageProvider getChurchImageProvider(String? imagePath, String fallbackAsset) {
  if (imagePath == null || imagePath.isEmpty) {
    return AssetImage(fallbackAsset);
  }
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('blob:')) {
    return NetworkImage(imagePath);
  }
  if (kIsWeb) {
    return NetworkImage(imagePath);
  }
  return FileImage(File(imagePath));
}

class CustomSermonItem {
  final String id;
  final String title;
  final String preacher;
  final String scripture;
  final String duration;
  final String mediaUrl;
  final String type; // 'video' | 'audio'
  final String category;
  final String? thumbnailUrl;
  final bool isYouTube;

  const CustomSermonItem({
    required this.id,
    required this.title,
    required this.preacher,
    required this.scripture,
    required this.duration,
    required this.mediaUrl,
    this.type = 'video',
    this.category = 'Mahubiri',
    this.thumbnailUrl,
    this.isYouTube = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'preacher': preacher,
    'scripture': scripture,
    'duration': duration,
    'mediaUrl': mediaUrl,
    'type': type,
    'category': category,
    'thumbnailUrl': thumbnailUrl,
    'isYouTube': isYouTube,
  };

  factory CustomSermonItem.fromJson(Map<String, dynamic> json) => CustomSermonItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    preacher: json['preacher'] ?? '',
    scripture: json['scripture'] ?? '',
    duration: json['duration'] ?? '',
    mediaUrl: json['mediaUrl'] ?? '',
    type: json['type'] ?? 'video',
    category: json['category'] ?? 'Mahubiri',
    thumbnailUrl: json['thumbnailUrl'],
    isYouTube: json['isYouTube'] == true,
  );
}

class ChurchCustomizationService extends ChangeNotifier {
  static final ChurchCustomizationService _instance = ChurchCustomizationService._internal();
  factory ChurchCustomizationService() => _instance;
  ChurchCustomizationService._internal();

  final ImagePicker _picker = ImagePicker();

  // State
  String _bishopName = ChurchProfile.headBishop;
  String _coLeaderName = ChurchProfile.pastorCoLeader;
  String _assistantPastor = ChurchProfile.assistantPastor;
  String _assistantPhone = ChurchProfile.assistantPastorPhone;

  String? _leadershipPhoto;
  String? _womenPhoto;
  String? _youthPhoto;
  String? _menPhoto;
  String? _sundaySchoolPhoto;

  List<CustomSermonItem> _customSermons = [];
  bool _isInitialized = false;

  String get bishopName => _bishopName;
  String get coLeaderName => _coLeaderName;
  String get assistantPastor => _assistantPastor;
  String get assistantPhone => _assistantPhone;

  String? get leadershipPhoto => _leadershipPhoto;
  String? get womenPhoto => _womenPhoto;
  String? get youthPhoto => _youthPhoto;
  String? get menPhoto => _menPhoto;
  String? get sundaySchoolPhoto => _sundaySchoolPhoto;

  List<CustomSermonItem> get customSermons => List.unmodifiable(_customSermons);

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _bishopName = prefs.getString('custom_bishop') ?? ChurchProfile.headBishop;
      _coLeaderName = prefs.getString('custom_co_leader') ?? ChurchProfile.pastorCoLeader;
      _assistantPastor = prefs.getString('custom_assistant') ?? ChurchProfile.assistantPastor;
      _assistantPhone = prefs.getString('custom_assistant_phone') ?? ChurchProfile.assistantPastorPhone;

      _leadershipPhoto = prefs.getString('custom_leadership_photo');
      _womenPhoto = prefs.getString('custom_women_photo');
      _youthPhoto = prefs.getString('custom_youth_photo');
      _menPhoto = prefs.getString('custom_men_photo');
      _sundaySchoolPhoto = prefs.getString('custom_sundayschool_photo');

      // Load sermons
      final rawSermons = prefs.getStringList('custom_admin_sermons_v2') ?? [];
      _customSermons = rawSermons.map((line) {
        final parts = line.split('||');
        if (parts.length >= 7) {
          final url = parts[5];
          final isYt = isYouTubeUrl(url);
          final thumb = isYt ? getYouTubeThumbnail(url) : null;
          return CustomSermonItem(
            id: parts[0],
            title: parts[1],
            preacher: parts[2],
            scripture: parts[3],
            duration: parts[4],
            mediaUrl: parts[5],
            type: parts[6],
            category: parts.length > 7 ? parts[7] : 'Mahubiri',
            isYouTube: isYt,
            thumbnailUrl: thumb,
          );
        }
        return null;
      }).whereType<CustomSermonItem>().toList();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ChurchCustomizationService: $e');
    }
  }

  // Photo upload helpers
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1400,
      );
      return file?.path;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1400,
      );
      return file?.path;
    } catch (e) {
      debugPrint('Error capturing photo from camera: $e');
      return null;
    }
  }

  // Update photo paths
  Future<void> updateLeadershipPhoto(String? pathOrUrl) async {
    _leadershipPhoto = (pathOrUrl != null && pathOrUrl.trim().isNotEmpty) ? pathOrUrl.trim() : null;
    final prefs = await SharedPreferences.getInstance();
    if (_leadershipPhoto != null) {
      await prefs.setString('custom_leadership_photo', _leadershipPhoto!);
    } else {
      await prefs.remove('custom_leadership_photo');
    }
    notifyListeners();
  }

  Future<void> updateFellowshipPhoto({
    required String fellowshipKey, // 'women' | 'youth' | 'men' | 'sundayschool'
    required String? pathOrUrl,
  }) async {
    final value = (pathOrUrl != null && pathOrUrl.trim().isNotEmpty) ? pathOrUrl.trim() : null;
    final prefs = await SharedPreferences.getInstance();

    switch (fellowshipKey) {
      case 'women':
        _womenPhoto = value;
        break;
      case 'youth':
        _youthPhoto = value;
        break;
      case 'men':
        _menPhoto = value;
        break;
      case 'sundayschool':
        _sundaySchoolPhoto = value;
        break;
    }

    final key = 'custom_${fellowshipKey}_photo';
    if (value != null) {
      await prefs.setString(key, value);
    } else {
      await prefs.remove(key);
    }
    notifyListeners();
  }

  Future<void> updateLeadershipInfo({
    required String bishop,
    required String coLeader,
    required String assistant,
    required String phone,
  }) async {
    _bishopName = bishop.trim();
    _coLeaderName = coLeader.trim();
    _assistantPastor = assistant.trim();
    _assistantPhone = phone.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_bishop', _bishopName);
    await prefs.setString('custom_co_leader', _coLeaderName);
    await prefs.setString('custom_assistant', _assistantPastor);
    await prefs.setString('custom_assistant_phone', _assistantPhone);
    notifyListeners();
  }

  // YouTube utilities
  static bool isYouTubeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com') || lower.contains('youtu.be');
  }

  static String? extractYouTubeVideoId(String url) {
    if (url.isEmpty) return null;
    try {
      final uri = Uri.parse(url.trim());
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
      if (uri.host.contains('youtube.com')) {
        if (uri.queryParameters.containsKey('v')) {
          return uri.queryParameters['v'];
        }
        if (uri.pathSegments.contains('live') || uri.pathSegments.contains('embed')) {
          return uri.pathSegments.last;
        }
      }
    } catch (_) {}
    return null;
  }

  static String? getYouTubeThumbnail(String url) {
    final id = extractYouTubeVideoId(url);
    if (id != null && id.isNotEmpty) {
      return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    return null;
  }

  static Future<void> launchMediaUrl(String url) async {
    if (url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching media URL: $e');
    }
  }

  // Add Sermon
  Future<void> addSermon(CustomSermonItem item) async {
    _customSermons.insert(0, item);
    final prefs = await SharedPreferences.getInstance();
    final list = _customSermons.map((s) => '${s.id}||${s.title}||${s.preacher}||${s.scripture}||${s.duration}||${s.mediaUrl}||${s.type}||${s.category}').toList();
    await prefs.setStringList('custom_admin_sermons_v2', list);
    notifyListeners();
  }

  Future<void> deleteSermon(String id) async {
    _customSermons.removeWhere((s) => s.id == id);
    final prefs = await SharedPreferences.getInstance();
    final list = _customSermons.map((s) => '${s.id}||${s.title}||${s.preacher}||${s.scripture}||${s.duration}||${s.mediaUrl}||${s.type}||${s.category}').toList();
    await prefs.setStringList('custom_admin_sermons_v2', list);
    notifyListeners();
  }
}
