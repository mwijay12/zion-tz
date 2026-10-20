import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, swahili }

class AppLanguageService extends ChangeNotifier {
  static final AppLanguageService _instance = AppLanguageService._internal();
  factory AppLanguageService() => _instance;
  AppLanguageService._internal();

  static const String _prefKey = 'setting_app_language_code';
  AppLanguage _currentLanguage = AppLanguage.english; // Default English as requested
  bool _isInitialized = false;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isEnglish => _currentLanguage == AppLanguage.english;
  bool get isSwahili => _currentLanguage == AppLanguage.swahili;
  String get languageCode => _currentLanguage == AppLanguage.english ? 'en' : 'sw';

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      if (code == 'sw') {
        _currentLanguage = AppLanguage.swahili;
      } else {
        _currentLanguage = AppLanguage.english; // Default English
      }
      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      _currentLanguage = AppLanguage.english;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, language == AppLanguage.swahili ? 'sw' : 'en');
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    if (_currentLanguage == AppLanguage.english) {
      await setLanguage(AppLanguage.swahili);
    } else {
      await setLanguage(AppLanguage.english);
    }
  }

  /// Translate helper with fallback
  String t({required String en, required String sw}) {
    return _currentLanguage == AppLanguage.english ? en : sw;
  }
}
