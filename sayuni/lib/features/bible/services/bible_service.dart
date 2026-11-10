import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_model.dart';
import '../models/tenzi_model.dart';

class BibleService {
  static final BibleService _instance = BibleService._internal();
  factory BibleService() => _instance;
  BibleService._internal();

  List<BibleBook>? _cachedSwBooks;
  List<BibleBook>? _cachedKjvBooks;
  List<TenziHymn>? _cachedTenzi;
  List<TenziHymn>? _cachedNyimbo;
  bool _isLoadingSw = false;
  bool _isLoadingKjv = false;

  Future<List<BibleBook>> loadBible({String translation = 'sw'}) async {
    if (translation == 'kjv') {
      if (_cachedKjvBooks != null) return _cachedKjvBooks!;
      if (_isLoadingKjv) {
        while (_isLoadingKjv) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        return _cachedKjvBooks ?? [];
      }

      _isLoadingKjv = true;
      try {
        final jsonString = await rootBundle.loadString('assets/bible/kjv.json');
        final Map<String, dynamic> data = json.decode(jsonString);
        final List<dynamic> bookList = data['BIBLEBOOK'] ?? [];
        _cachedKjvBooks = bookList
            .map((b) => BibleBook.fromJson(b as Map<String, dynamic>))
            .toList();
        return _cachedKjvBooks!;
      } finally {
        _isLoadingKjv = false;
      }
    } else {
      if (_cachedSwBooks != null) return _cachedSwBooks!;
      if (_isLoadingSw) {
        while (_isLoadingSw) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        return _cachedSwBooks ?? [];
      }

      _isLoadingSw = true;
      try {
        String jsonString;
        try {
          // Load full 66-book Swahili Bible
          jsonString =
              await rootBundle.loadString('assets/bible/full_version.json');
        } catch (_) {
          jsonString =
              await rootBundle.loadString('assets/bible/agano_jipya.json');
        }

        final Map<String, dynamic> data = json.decode(jsonString);
        final List<dynamic> bookList = data['BIBLEBOOK'] ?? [];
        _cachedSwBooks = bookList
            .map((b) => BibleBook.fromJson(b as Map<String, dynamic>))
            .toList();
        return _cachedSwBooks!;
      } finally {
        _isLoadingSw = false;
      }
    }
  }

  Future<List<TenziHymn>> loadTenzi() async {
    if (_cachedTenzi != null) return _cachedTenzi!;
    try {
      final jsonString =
          await rootBundle.loadString('assets/hymns/tenzi_za_rohoni.json');
      final List<dynamic> list = json.decode(jsonString);
      _cachedTenzi = list
          .map((h) => TenziHymn.fromJson(h as Map<String, dynamic>))
          .toList();
      return _cachedTenzi!;
    } catch (e) {
      return [];
    }
  }

  /// Nyimbo za Kikristo: 32 offline hymns with full Swahili lyrics
  /// (fresh translations of classic public-domain songs). No external links.
  Future<List<TenziHymn>> loadNyimbo() async {
    if (_cachedNyimbo != null) return _cachedNyimbo!;
    try {
      final jsonString = await rootBundle
          .loadString('assets/hymns/nyimbo_za_kikristo.json');
      final List<dynamic> list = json.decode(jsonString);
      _cachedNyimbo = list
          .map((h) => TenziHymn.fromJson(h as Map<String, dynamic>))
          .toList();
      return _cachedNyimbo!;
    } catch (e) {
      return [];
    }
  }

  /// Combined hymn list: Tenzi (46) then Nyimbo (32), all fully offline.
  Future<List<TenziHymn>> loadAllHymns() async {
    final tenzi = await loadTenzi();
    final nyimbo = await loadNyimbo();
    return [...tenzi, ...nyimbo];
  }

  Future<void> saveLastRead({
    required String bookName,
    required String chapterNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read_book', bookName);
    await prefs.setString('last_read_chapter', chapterNumber);
  }

  Future<Map<String, String>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final book = prefs.getString('last_read_book');
    final chapter = prefs.getString('last_read_chapter');
    if (book != null && chapter != null) {
      return {'book': book, 'chapter': chapter};
    }
    return null;
  }
}
