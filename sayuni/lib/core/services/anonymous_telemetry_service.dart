import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Anonymous Telemetry Service for Zion Jerusalem Church App
/// 
/// Compliant with Tanzania Personal Data Protection Act (PDPA No. 11 of 2022).
/// PRINCIPLE:
/// - Absolute Data Minimisation: No collection of personal identifiable data (PII).
/// - Zero Surveillance: No phone numbers, names, GPS coordinates, or Advertising IDs.
/// - Aggregates Only: Increments anonymous global tallies in Firestore and local device cache.
class AnonymousTelemetryService {
  AnonymousTelemetryService._();
  static final AnonymousTelemetryService instance = AnonymousTelemetryService._();

  static const String _localScriptureCountKey = 'anon_telemetry_scripture_count';
  static const String _localSermonCountKey = 'anon_telemetry_sermon_count';
  static const String _localHymnCountKey = 'anon_telemetry_hymn_count';
  static const String _localBulletinCountKey = 'anon_telemetry_bulletin_count';

  /// Records an anonymous scripture chapter/verse read event.
  Future<void> recordScriptureRead({String? reference}) async {
    await _incrementLocalCounter(_localScriptureCountKey);
    await _incrementCloudCounter('scriptureReadsCount');
  }

  /// Records an anonymous sermon listen/view event.
  Future<void> recordSermonListen({String? sermonTitle}) async {
    await _incrementLocalCounter(_localSermonCountKey);
    await _incrementCloudCounter('sermonsListenedCount');
  }

  /// Records an anonymous hymn / choir song play event.
  Future<void> recordHymnPlay({String? songTitle}) async {
    await _incrementLocalCounter(_localHymnCountKey);
    await _incrementCloudCounter('hymnsPlayedCount');
  }

  /// Records an anonymous weekly bulletin read event.
  Future<void> recordBulletinView() async {
    await _incrementLocalCounter(_localBulletinCountKey);
    await _incrementCloudCounter('bulletinViewsCount');
  }

  /// Records an anonymous app open session.
  Future<void> recordAppLaunch() async {
    await _incrementCloudCounter('appLaunchesCount');
  }

  /// Helper to increment local SharedPreferences counter safely
  Future<void> _incrementLocalCounter(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, current + 1);
    } catch (e) {
      debugPrint('AnonymousTelemetryService._incrementLocalCounter error: $e');
    }
  }

  /// Helper to increment aggregate Firestore document with FieldValue.increment
  /// Note: ZERO user identifying tokens are sent. Only the aggregate counter is incremented.
  Future<void> _incrementCloudCounter(String field) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('church_telemetry')
          .doc('aggregates');

      await docRef.set({
        field: FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Offline or network error: silent fallback to protect user experience
      debugPrint('AnonymousTelemetryService._incrementCloudCounter fallback: $e');
    }
  }
}
