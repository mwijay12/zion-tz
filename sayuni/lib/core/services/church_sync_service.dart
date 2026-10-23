import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notifications/models/church_announcement.dart';
import '../../features/notifications/services/notifications_data_service.dart';
import '../utils/haptics.dart';
import 'church_auth_service.dart';
import 'church_notification_service.dart';
import 'supabase_database_service.dart';

/// Central real-time and offline-first Synchronization Bridge between
/// Zion Jerusalem Mobile Application and the Church Web Administration Portal.
///
/// Features:
/// 1. Real-time announcement synchronization with Cloud Firestore as single source of truth
/// 2. Instant system & in-app Heads-Up notification alerts on incoming notices
/// 3. Offline-first resilience retaining cached announcements in SharedPreferences
/// 4. Synchronizes church leadership profile, phone contacts, and pastoral photo
class ChurchSyncService extends ChangeNotifier {
  static final ChurchSyncService _instance = ChurchSyncService._internal();
  factory ChurchSyncService() => _instance;
  ChurchSyncService._internal();

  final SupabaseDatabaseService _supabase = SupabaseDatabaseService();
  bool _isInitialized = false;
  Timer? _syncTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _firestoreSubscription;

  /// Global reactive notifier for live portal / cloud connection status
  static final ValueNotifier<bool> isPortalConnected = ValueNotifier(false);

  /// Global reactive notifier for cloud Firestore connection
  static final ValueNotifier<bool> isCloudConnected = ValueNotifier(false);

  /// Human-readable sync status message for users
  static final ValueNotifier<String> syncStatusMessage =
      ValueNotifier('Inaunganisha na kanisa...');

  /// Global reactive notifier for the in-app top alert banner
  static final ValueNotifier<ChurchAnnouncement?> currentInAppNotice =
      ValueNotifier(null);

  /// Global reactive notifier for live War Room prayers
  static final ValueNotifier<List<Map<String, dynamic>>> livePrayersNotifier =
      ValueNotifier([]);

  /// Set of IDs we have already alerted the user about
  final Set<String> _processedNoticeIds = {};

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Seed processed IDs with pre-existing announcement IDs so we only alert for NEW incoming items
    final existing = NotificationsDataService().announcements;
    for (final a in existing) {
      _processedNoticeIds.add(a.id);
    }

    // 1. Primary Cloud Realtime Stream via Firebase Cloud Firestore
    _initFirestoreStream();

    // 2. Offline and dev fallbacks: Check local storage
    await _checkLocalCacheSync();

    // 3. Localhost bridge: strictly in kDebugMode only (never in production / release builds)
    if (kDebugMode) {
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _checkLocalhostDevBridge();
        _checkPrayersSync();
      });
    }

    notifyListeners();
  }

  /// Sets up real-time stream listener to Cloud Firestore `announcements` collection
  void _initFirestoreStream() {
    try {
      final announcementsRef = FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true);

      _firestoreSubscription = announcementsRef.snapshots().listen(
        (snapshot) {
          isCloudConnected.value = true;
          isPortalConnected.value = true;
          syncStatusMessage.value = '🟢 Imeunganishwa na Seva ya Kanisa';

          for (final doc in snapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            if (data['createdAt'] is Timestamp) {
              final date = (data['createdAt'] as Timestamp).toDate();
              data['date'] = '${date.day}/${date.month}/${date.year}';
            }
            _processIncomingNotice(data);
          }
        },
        onError: (err) {
          debugPrint('Firestore announcements stream error: $err');
          isCloudConnected.value = false;
          syncStatusMessage.value =
              '⚪ Nje ya mtandao — unaona matangazo yaliyohifadhiwa';
        },
      );
    } catch (e) {
      debugPrint('Firestore announcements init stream error: $e');
      isCloudConnected.value = false;
      syncStatusMessage.value =
          '⚪ Nje ya mtandao — unaona matangazo yaliyohifadhiwa';
    }
  }

  /// Checks local offline storage for cached announcements
  Future<void> _checkLocalCacheSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('flutter.church_announcements') ??
          prefs.getString('church_announcements');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        for (final item in list) {
          if (item is Map) {
            _processIncomingNotice(Map<String, dynamic>.from(item));
          }
        }
      }
    } catch (_) {}
  }

  /// Localhost development bridge (only active during local debugging)
  Future<void> _checkLocalhostDevBridge() async {
    final urls = [
      'http://localhost:5173/api/sync/notices',
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        'http://10.0.2.2:5173/api/sync/notices',
    ];

    for (final url in urls) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200) {
          isPortalConnected.value = true;
          final List<dynamic> list = jsonDecode(response.body);
          for (final item in list) {
            if (item is Map) {
              _processIncomingNotice(Map<String, dynamic>.from(item));
            }
          }
          break;
        }
      } catch (_) {}
    }
  }

  /// Polls for newly created prayers from Web Pastor Portal
  Future<void> _checkPrayersSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('flutter.zion_prayer_requests') ??
          prefs.getString('zion_prayer_requests');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        final mapped = list
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        if (mapped.isNotEmpty) {
          livePrayersNotifier.value = mapped;
        }
      }
    } catch (_) {}

    final urls = [
      'http://localhost:5173/api/sync/prayers',
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        'http://10.0.2.2:5173/api/sync/prayers',
    ];

    for (final url in urls) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200) {
          final List<dynamic> list = jsonDecode(response.body);
          final mapped = list
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
          if (mapped.isNotEmpty) {
            livePrayersNotifier.value = mapped;
          }
          break;
        }
      } catch (_) {}
    }
  }

  /// Handles an incoming notice payload from Katibu / Admin
  void _processIncomingNotice(Map<String, dynamic> item) {
    final noticeId = item['id']?.toString() ?? '';
    if (noticeId.isEmpty) return;

    if (_processedNoticeIds.contains(noticeId)) {
      return; // Already processed
    }

    _processedNoticeIds.add(noticeId);

    final targetAudience = item['targetAudience']?.toString() ??
        (item['audience']?.toString() ?? 'all');

    // Create ChurchAnnouncement model
    final announcement = ChurchAnnouncement(
      id: noticeId,
      title: item['title']?.toString() ?? 'Tangazo Jipya la Kanisa',
      category: item['category']?.toString() ?? 'Taarifa Kuu',
      date: item['date']?.toString() ?? 'Leo',
      time: item['time']?.toString() ?? 'Saa za Ibada',
      location: item['location']?.toString() ?? 'Hekalu Kuu la Sayuni',
      summary:
          item['summary']?.toString() ?? (item['content']?.toString() ?? ''),
      fullDetails: item['content']?.toString() ??
          (item['fullDetails']?.toString() ?? ''),
      preacherOrLeader: 'Ofisi ya Katibu Mkuu wa Kanisa',
      isHighPriority:
          item['isUrgent'] == true || item['isHighPriority'] == true,
      targetAudience: targetAudience,
      isRead: false,
    );

    // 1. Add to Notifications Data Service so unread count increments immediately
    NotificationsDataService().addAnnouncementFromPortal(announcement);

    // 2. Trigger notifications if relevant to current user
    final auth = ChurchAuthService();
    final bool shouldAlertUser =
        announcement.targetAudience == 'all' || auth.isAdmin || auth.isLeader;

    if (shouldAlertUser) {
      ChurchNotificationService().showLockScreenNotification(
        id: announcement.id.hashCode,
        title:
            '${announcement.isForLeaders ? "🔒 " : "📢 "}${announcement.title}',
        body: announcement.summary.isNotEmpty
            ? announcement.summary
            : announcement.fullDetails,
        payload: announcement.id,
      );

      // Trigger In-App Notification Heads-Up Banner
      currentInAppNotice.value = announcement;
      AppHaptics.heavyImpact();
    }

    notifyListeners();
  }

  /// Dismiss active in-app notice
  void dismissInAppNotice() {
    currentInAppNotice.value = null;
  }

  /// Broadcast a newly uploaded sermon from Mobile to Web and Supabase
  Future<void> syncNewSermon({
    required String id,
    required String title,
    required String preacher,
    required String scripture,
    required String duration,
    required String type,
    required String category,
    required String mediaUrl,
    String? imageUrl,
    String? description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Read existing media from local storage
      final raw = prefs.getString('zion_admin_uploaded_media');
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        try {
          list = jsonDecode(raw);
        } catch (_) {}
      }

      final itemMap = {
        'id': id,
        'title': title,
        'preacher': preacher,
        'scripture': scripture,
        'date': 'Hivi karibuni',
        'duration': duration,
        'type': type,
        'category': category,
        'description': (description != null && description.trim().isNotEmpty)
            ? description.trim()
            : 'Mahubiri ya nguvu yaliyowekwa na Utawala wa Kanisa.',
        'imageUrl': imageUrl ??
            (type == 'video'
                ? 'assets/images/altar.jpg'
                : 'assets/images/church_front.jpg'),
        'audioUrl':
            type == 'audio' ? mediaUrl : 'https://stream.zeno.fm/4v4e91y9sm8uv',
        'videoUrl': type == 'video' ? mediaUrl : '',
        'isAdminUpload': true,
      };

      // Insert at the top
      list.removeWhere((e) => e is Map && e['id'] == id);
      list.insert(0, itemMap);

      final encoded = jsonEncode(list);
      await prefs.setString('zion_admin_uploaded_media', encoded);
      await prefs.setString('flutter.zion_admin_uploaded_media', encoded);

      // 2. Also push to Web Portal Sync API if reachable
      try {
        final urls = [
          'http://localhost:5173/api/sync/sermons',
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            'http://10.0.2.2:5173/api/sync/sermons',
        ];
        for (final u in urls) {
          http
              .post(
                Uri.parse(u),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(itemMap),
              )
              .catchError((_) => http.Response('', 500));
        }
      } catch (_) {}

      // 3. Also push to Supabase if connected
      await _supabase.insertSermon(
        title: title,
        preacher: preacher,
        scripture: scripture,
        duration: duration,
        type: type,
        category: category,
        mediaUrl: mediaUrl,
        imageUrl: imageUrl,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('ChurchSyncService syncNewSermon error: $e');
    }
  }

  /// Sync updated leadership contact or photo
  Future<void> syncLeadershipInfo({
    String? bishop,
    String? coLeader,
    String? assistant,
    String? assistantPhone,
    String? photoUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (bishop != null) await prefs.setString('custom_bishop', bishop);
      if (coLeader != null) await prefs.setString('custom_co_leader', coLeader);
      if (assistant != null)
        await prefs.setString('custom_assistant', assistant);
      if (assistantPhone != null)
        await prefs.setString('custom_assistant_phone', assistantPhone);
      if (photoUrl != null)
        await prefs.setString('custom_leadership_photo', photoUrl);
      notifyListeners();
    } catch (e) {
      debugPrint('ChurchSyncService syncLeadershipInfo error: $e');
    }
  }

  /// ================= PRAYER REQUESTS SYNC =================

  Future<List<Map<String, dynamic>>> getSavedPrayerRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('flutter.zion_prayer_requests') ??
          prefs.getString('zion_prayer_requests');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        return list
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> syncNewPrayerRequest({
    required String id,
    required String title,
    required String author,
    required String urgency,
    required String description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('flutter.zion_prayer_requests') ??
          prefs.getString('zion_prayer_requests');
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        try {
          list = jsonDecode(raw);
        } catch (_) {}
      }

      final prayerMap = {
        'id': id,
        'title': title,
        'author': author,
        'urgency': urgency,
        'description': description,
        'date': 'Punde hivi',
        'intercessors': 1,
        'hasJoined': true,
        'pastorInterceded': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      list.removeWhere((e) => e is Map && e['id'] == id);
      list.insert(0, prayerMap);

      final encoded = jsonEncode(list);
      await prefs.setString('zion_prayer_requests', encoded);
      await prefs.setString('flutter.zion_prayer_requests', encoded);

      livePrayersNotifier.value = list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      // Push to Vite Sync API
      final urls = [
        'http://localhost:5173/api/sync/prayers',
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          'http://10.0.2.2:5173/api/sync/prayers',
      ];
      for (final u in urls) {
        http
            .post(
              Uri.parse(u),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(prayerMap),
            )
            .catchError((_) => http.Response('', 500));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('ChurchSyncService syncNewPrayerRequest error: $e');
    }
  }

  Future<void> togglePrayerStandInGap(String prayerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('flutter.zion_prayer_requests') ??
          prefs.getString('zion_prayer_requests');
      if (raw == null || raw.isEmpty) return;

      final List<dynamic> list = jsonDecode(raw);
      for (final item in list) {
        if (item is Map && item['id'] == prayerId) {
          final currentJoined = item['hasJoined'] == true;
          item['hasJoined'] = !currentJoined;
          item['intercessors'] =
              ((item['intercessors'] as int? ?? 1) + (!currentJoined ? 1 : -1));
          break;
        }
      }

      final encoded = jsonEncode(list);
      await prefs.setString('zion_prayer_requests', encoded);
      await prefs.setString('flutter.zion_prayer_requests', encoded);

      livePrayersNotifier.value = list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('ChurchSyncService togglePrayerStandInGap error: $e');
    }
  }

  /// ================= VISITOR REGISTRATION SYNC =================

  Future<List<Map<String, dynamic>>> getSavedVisitors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('flutter.zion_portal_visitors') ??
          prefs.getString('zion_portal_visitors');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        return list
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> syncNewVisitor({
    required String fullName,
    required String phone,
    required String residence,
    required String visitorType,
    required String assignedJumuiya,
    required String prayerRequest,
    required String interests,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('flutter.zion_portal_visitors') ??
          prefs.getString('zion_portal_visitors');
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        try {
          list = jsonDecode(raw);
        } catch (_) {}
      }

      final visitorMap = {
        'id': 'vis-${DateTime.now().millisecondsSinceEpoch}',
        'fullName': fullName,
        'phone': phone,
        'residence': residence.isNotEmpty ? residence : 'Mbagala',
        'firstVisitDate': DateTime.now().toIso8601String().split('T')[0],
        'invitedBy': visitorType,
        'assignedJumuiya': assignedJumuiya,
        'prayerRequest':
            prayerRequest.isNotEmpty ? prayerRequest : 'Maombi ya Baraka',
        'followUpStatus': 'Mpya',
        'welfareNeeds': interests,
        'registeredByDeacon': 'Simu ya Mkononi (Self-Registered)',
      };

      list.insert(0, visitorMap);

      final encoded = jsonEncode(list);
      await prefs.setString('zion_portal_visitors', encoded);
      await prefs.setString('flutter.zion_portal_visitors', encoded);

      // Push to Vite Sync API
      final urls = [
        'http://localhost:5173/api/sync/visitors',
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          'http://10.0.2.2:5173/api/sync/visitors',
      ];
      for (final u in urls) {
        http
            .post(
              Uri.parse(u),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(visitorMap),
            )
            .catchError((_) => http.Response('', 500));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('ChurchSyncService syncNewVisitor error: $e');
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
