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
import 'church_customization_service.dart';
import 'church_notification_service.dart';

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

  /// Fingerprint of every notice already delivered to this device, keyed by id.
  ///
  /// Two things depend on this being a *content* fingerprint rather than a set
  /// of ids:
  ///   * a notice the secretary edits must re-render on the phone, and
  ///   * the same stream callbacks must not stack duplicate lock-screen alerts.
  final Map<String, String> _processedNoticeIds = {};

  /// Marker for "already on this device before this session" — any real
  /// fingerprint differs from it, so an edited notice still re-renders.
  static const String _sentinelAlreadyKnown = 'seed';

  static const String _processedNoticeIdsKey = 'zion_processed_notice_fingerprints';

  /// Loads the alert history persisted on this device.
  Future<void> _loadProcessedFingerprints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_processedNoticeIdsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      decoded.forEach((key, value) {
        final id = key?.toString() ?? '';
        if (id.isNotEmpty) {
          _processedNoticeIds[id] = value?.toString() ?? '';
        }
      });
    } catch (e) {
      debugPrint('Could not restore notice fingerprints: $e');
    }
  }

  /// Persists the alert history so a cold start does not replay old notices.
  /// Capped so the preference cannot grow without bound.
  Future<void> _saveProcessedFingerprints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = _processedNoticeIds.entries.toList();
      final overflow = entries.length - _maxRememberedNotices;
      if (overflow > 0) {
        // Newest inserts are last; drop the oldest tail of the map.
        for (final e in entries.take(overflow)) {
          _processedNoticeIds.remove(e.key);
        }
      }
      await prefs.setString(
        _processedNoticeIdsKey,
        jsonEncode(_processedNoticeIds),
      );
    } catch (e) {
      debugPrint('Could not persist notice fingerprints: $e');
    }
  }

  static const int _maxRememberedNotices = 500;


  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Store what this device has already been alerted about. Without this the
    // map lived only in memory, so every cold start re-announced *every*
    // announcement in the collection on the lock screen.
    await _loadProcessedFingerprints();

    // Seed processed IDs with pre-existing announcement IDs so we only alert for NEW incoming items
    final existing = NotificationsDataService().announcements;
    for (final a in existing) {
      _processedNoticeIds.putIfAbsent(a.id, () => _sentinelAlreadyKnown);
    }

    // 1. Primary Cloud Realtime Stream via Firebase Cloud Firestore
    _initFirestoreStream();
    _initLeadershipStream();

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

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _sermonsSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _leadershipSubscription;

  /// Sets up real-time stream listener to Cloud Firestore `announcements` and `sermons` collections
  /// Leadership names / photo are owned by the portal (church_settings doc).
  /// Listening here is what makes "picha ya viongozi" appear on every member
  /// device instead of only on the browser where it was uploaded.
  void _initLeadershipStream() {
    try {
      _leadershipSubscription = FirebaseFirestore.instance
          .collection('church_settings')
          .doc('leadership')
          .snapshots()
          .listen((snapshot) async {
        final data = snapshot.data();
        if (data == null) return;
        final prefs = await SharedPreferences.getInstance();
        const pairs = {
          'bishopName': 'custom_bishop',
          'coLeaderName': 'custom_co_leader',
          'assistantPastor': 'custom_assistant',
          'assistantPhone': 'custom_assistant_phone',
          'leadershipPhotoUrl': 'custom_leadership_photo',
        };
        for (final entry in pairs.entries) {
          final value = data[entry.key];
          if (value is String && value.trim().isNotEmpty) {
            await prefs.setString(entry.value, value.trim());
          }
        }
        // Refresh the in-memory cache so the UI updates immediately.
        await ChurchCustomizationService().reload();
        notifyListeners();
      }, onError: (Object err) {
        debugPrint('Firestore leadership stream error: $err');
      });
    } catch (e) {
      debugPrint('Leadership stream init error: $e');
    }
  }

  void _initFirestoreStream() {
    try {
      final announcementsRef = FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true);

      _firestoreSubscription = announcementsRef.snapshots().listen(
        (snapshot) {
          isCloudConnected.value = true;
          isPortalConnected.value = true;
          syncStatusMessage.value = 'Imeunganishwa na Seva ya Kanisa';

          final liveIds = <String>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            liveIds.add(doc.id);
            if (data['createdAt'] is Timestamp) {
              final date = (data['createdAt'] as Timestamp).toDate();
              data['date'] = '${date.day}/${date.month}/${date.year}';
            }
            _processIncomingNotice(data);
          }

          // A notice the secretariat DELETED (wrong venue, cancelled service)
          // used to keep showing on every phone forever, because the app only
          // ever added. Prune against the authoritative server list — but never
          // against a local-cache snapshot, which can be empty before the
          // server answers and would wipe every cached notice on a cold start.
          if (!snapshot.metadata.isFromCache) {
            NotificationsDataService().pruneMissingPortalNotices(liveIds);
          }
        },
        onError: (err) {
          debugPrint('Firestore announcements stream error: $err');
          isCloudConnected.value = false;
          syncStatusMessage.value =
              'Nje ya mtandao — unaona matangazo yaliyohifadhiwa';
        },
      );

      final sermonsRef = FirebaseFirestore.instance
          .collection('sermons')
          .orderBy('createdAt', descending: true)
          .limit(30);

      _sermonsSubscription = sermonsRef.snapshots().listen(
        (snapshot) async {
          if (snapshot.docs.isEmpty) return;
          final prefs = await SharedPreferences.getInstance();
          final raw = prefs.getString('zion_admin_uploaded_media');
          List<dynamic> list = [];
          if (raw != null && raw.isNotEmpty) {
            try {
              list = jsonDecode(raw);
            } catch (_) {}
          }
          bool changed = false;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final id = doc.id;
            if (!list.any((e) => e is Map && e['id'] == id)) {
              final type = data['type']?.toString() ?? 'audio';
              final mediaUrl = data['mediaUrl']?.toString() ?? '';
              list.insert(0, {
                'id': id,
                'title': data['title']?.toString() ?? 'Mahubiri ya Sayuni',
                'preacher': data['preacher']?.toString() ?? 'Askofu / Mchungaji',
                'scripture': data['scripture']?.toString() ?? 'Neno la Mungu',
                'date': data['date']?.toString() ?? 'Hivi karibuni',
                'duration': data['duration']?.toString() ?? '45:00',
                'type': type,
                'category': data['category']?.toString() ?? 'Jumapili',
                'description': data['description']?.toString() ??
                    'Mahubiri yaliyowekwa na Utawala wa Kanisa.',
                'imageUrl': data['imageUrl']?.toString() ??
                    (type == 'video'
                        ? 'assets/images/altar.jpg'
                        : 'assets/images/church_front.jpg'),
                'audioUrl': type == 'audio'
                    ? mediaUrl
                    : 'https://stream.zeno.fm/4v4e91y9sm8uv',
                'videoUrl': type == 'video' ? mediaUrl : '',
                'isAdminUpload': true,
              });
              changed = true;
            }
          }
          if (changed) {
            final encoded = jsonEncode(list);
            await prefs.setString('zion_admin_uploaded_media', encoded);
            await prefs.setString('flutter.zion_admin_uploaded_media', encoded);
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('Firestore sermons stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore init stream error: $e');
      isCloudConnected.value = false;
      syncStatusMessage.value =
          'Nje ya mtandao — unaona matangazo yaliyohifadhiwa';
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

  /// Reads a string field, treating blank/whitespace values as missing.
  ///
  /// The portal writes `body` *and* `content` (same value) and sometimes only
  /// one of them; a plain `??` chain stops at the first key that exists even
  /// when its value is an empty string, which is how an announcement arrived
  /// on the phone with a blank body.
  static String? _firstNonEmpty(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  /// Builds the immutable, content-addressed fingerprint used to decide
  /// whether a notice really is "new" for this device.
  ///
  /// Keying only on the document id was a bug: when the secretary *edited* an
  /// announcement (corrected the venue, escalated it to urgent), the id was
  /// already in `_processedNoticeIds`, so the phone silently kept showing the
  /// old text forever. A changed fingerprint now re-renders the notice in
  /// place instead of being dropped.
  static String _noticeFingerprint(Map<String, dynamic> item) => [
        item['title'],
        item['body'],
        item['content'],
        item['summary'],
        item['fullDetails'],
        item['category'],
        item['type'],
        item['priority'],
        item['branch'],
        item['isUrgent'],
        item['isHighPriority'],
        item['targetAudience'],
        item['audience'],
        item['targetUid'],
        item['targetJumuiya'],
        item['eventDate'],
        item['date'],
        item['eventTime'],
        item['time'],
        item['venue'],
        item['location'],
        item['authorRole'],
      ].map((v) => v?.toString() ?? '').join('\u0001');

  void _processIncomingNotice(Map<String, dynamic> item) {
    final noticeId = item['id']?.toString() ?? '';
    if (noticeId.isEmpty) return;

    final fingerprint = _noticeFingerprint(item);
    if (_processedNoticeIds[noticeId] == fingerprint) {
      return; // Identical content already delivered to this device.
    }
    final bool isEdit = _processedNoticeIds.containsKey(noticeId);
    _processedNoticeIds[noticeId] = fingerprint;

    final targetAudience = item['targetAudience']?.toString() ??
        (item['audience']?.toString() ?? 'all');

    // The portal's canonical fields are `body`/`content` plus the structured
    // `eventDate` / `eventTime` / `venue` trio. Older clients and the demo
    // seed use `summary` / `date` / `time` / `location`. Read both, and never
    // let a blank value win over a populated one.
    final body = _firstNonEmpty(item, ['body', 'content', 'summary']);
    final summary =
        _firstNonEmpty(item, ['summary', 'body', 'content']) ?? '';
    final fullDetails =
        _firstNonEmpty(item, ['fullDetails', 'body', 'content']) ?? summary;

    // `type` carries the urgency in Firestore (`normal|urgent|bereavement`).
    // The app used to look only at `isUrgent`/`isHighPriority`, which the
    // portal never writes, so every urgent notice arrived as a quiet normal
    // one: no lock-screen alert, no red banner.
    final rawType = item['type']?.toString();
    final bool urgent =
        rawType == 'urgent' || item['priority']?.toString() == 'high';
    final String type = switch (rawType) {
      'urgent' => 'urgent',
      'bereavement' => 'bereavement',
      _ => (urgent ? 'urgent' : 'normal'),
    };

    // Create ChurchAnnouncement model (with personalized targeting)
    final announcement = ChurchAnnouncement(
      id: noticeId,
      title: item['title']?.toString() ?? 'Tangazo Jipya la Kanisa',
      category: item['category']?.toString() ?? 'Taarifa Kuu',
      type: type,
      branch: _firstNonEmpty(item, ['branch']) ?? 'Zote',
      date: _firstNonEmpty(item, ['eventDate', 'date']) ?? 'Leo',
      time: _firstNonEmpty(item, ['eventTime', 'time']) ?? 'Saa za Ibada',
      location:
          _firstNonEmpty(item, ['venue', 'location']) ?? 'Hekalu Kuu la Sayuni',
      summary: summary.isNotEmpty ? summary : (body ?? ''),
      fullDetails: fullDetails,
      preacherOrLeader:
          _firstNonEmpty(item, ['preacherOrLeader', 'authorRole']) ??
              'Ofisi ya Katibu Mkuu wa Kanisa',
      isHighPriority: urgent || item['isHighPriority'] == true,
      targetAudience: targetAudience,
      isRead: false,
      targetUid: item['targetUid']?.toString(),
      targetJumuiya: item['targetJumuiya']?.toString(),
    );

    // Personalized targeting: only the intended member/group (plus
    // leaders/admins for oversight) should see/alert for this notice.
    // NOTE: Firestore currently streams all announcements to all clients
    // (public read rules) — this is UI-level filtering for the demo.
    // Production must enforce targeting in firestore.rules + FCM topics.
    final auth = ChurchAuthService();
    final bool isTargetedToMe = announcement.targetUid != null &&
        auth.uid != null &&
        announcement.targetUid == auth.uid;
    final bool isTargetedToMyJumuiya = announcement.targetJumuiya != null &&
        announcement.targetJumuiya!.trim().toLowerCase() ==
            auth.jumuiya.trim().toLowerCase();
    final bool isRelevantToMe = announcement.targetAudience == 'all' ||
        isTargetedToMe ||
        isTargetedToMyJumuiya ||
        auth.isAdmin ||
        auth.isLeader;

    if (!isRelevantToMe) {
      // Not for this user — skip silently (already marked processed).
      notifyListeners();
      return;
    }

    // 1. Add to Notifications Data Service so unread count increments immediately
    NotificationsDataService().addAnnouncementFromPortal(announcement);

    // 2. Trigger notifications if relevant to current user.
    //
    // An *edited* announcement must update the list but must not buzz the phone
    // again for something the member already read — only genuinely new notices
    // interrupt.
    if (!isEdit) {
      ChurchNotificationService().showLockScreenNotification(
        id: announcement.id.hashCode,
        title:
            '${announcement.isPersonalized ? "[Kwa Ajili Yako] " : announcement.isForLeaders ? "[Viongozi] " : "[Tangazo] "}${announcement.title}',
        body: announcement.summary.isNotEmpty
            ? announcement.summary
            : announcement.fullDetails,
        payload: announcement.id,
      );

      // Trigger In-App Notification Heads-Up Banner
      currentInAppNotice.value = announcement;
      AppHaptics.heavyImpact();
    }

    // Remember that this device has seen this exact revision, so a cold start
    // or a re-emitted snapshot does not replay it.
    _saveProcessedFingerprints();

    notifyListeners();
  }

  /// Dismiss active in-app notice
  void dismissInAppNotice() {
    currentInAppNotice.value = null;
  }

  /// Broadcast a newly uploaded sermon from Mobile to Cloud Firestore & local Web portal
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

      // 2. Write to Cloud Firestore `sermons` collection when authenticated as leader/admin
      try {
        await FirebaseFirestore.instance.collection('sermons').doc(id).set({
          'title': title,
          'preacher': preacher,
          'scripture': scripture,
          'duration': duration,
          'type': type,
          'category': category,
          'mediaUrl': mediaUrl,
          'imageUrl': itemMap['imageUrl'],
          'description': itemMap['description'],
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore sermon write skipped (offline or unauthenticated): $e');
      }

      // 3. Also push to Web Portal Sync API if reachable in debug mode
      if (kDebugMode) {
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
      }

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
      if (bishop != null) {
        await prefs.setString('custom_bishop', bishop);
      }
      if (coLeader != null) {
        await prefs.setString('custom_co_leader', coLeader);
      }
      if (assistant != null) {
        await prefs.setString('custom_assistant', assistant);
      }
      if (assistantPhone != null) {
        await prefs.setString('custom_assistant_phone', assistantPhone);
      }
      if (photoUrl != null) {
        await prefs.setString('custom_leadership_photo', photoUrl);
      }

      // Push the same profile to Cloud Firestore so the leadership portal and
      // other member devices stay in sync (admin-only write in the rules).
      final auth = ChurchAuthService();
      if (auth.uid != null) {
        try {
          await FirebaseFirestore.instance
              .collection('church_settings')
              .doc('leadership')
              .set({
            if (bishop != null) 'bishopName': bishop,
            if (coLeader != null) 'coLeaderName': coLeader,
            if (assistant != null) 'assistantPastor': assistant,
            if (assistantPhone != null) 'assistantPhone': assistantPhone,
            if (photoUrl != null) 'leadershipPhotoUrl': photoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore leadership write skipped: $e');
        }
      }
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

      // Push to Cloud Firestore `prayer_requests` collection (matches firestore.rules)
      final auth = ChurchAuthService();
      if (auth.uid != null) {
        try {
          await FirebaseFirestore.instance
              .collection('prayer_requests')
              .doc(id)
              .set({
            'title': title,
            'senderName': author,
            'requestText': description,
            'urgency': urgency,
            'userId': auth.uid,
            'isAnswered': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Firestore prayer_requests write skipped: $e');
        }
      }

      // Push to Vite Sync API in debug mode
      if (kDebugMode) {
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

      final visitorId = 'vis-${DateTime.now().millisecondsSinceEpoch}';
      final visitorMap = {
        'id': visitorId,
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

      // Push to Cloud Firestore `visitors_registry` collection (matches firestore.rules)
      final auth = ChurchAuthService();
      if (auth.uid != null) {
        try {
          await FirebaseFirestore.instance
              .collection('visitors_registry')
              .doc(visitorId)
              .set({
            'fullName': fullName,
            'phone': phone,
            'residence': residence.isNotEmpty ? residence : 'Mbagala',
            'assignedJumuiya': assignedJumuiya,
            'prayerRequest':
                prayerRequest.isNotEmpty ? prayerRequest : 'Maombi ya Baraka',
            'followUpStatus': 'Mpya',
            'consent': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Firestore visitors_registry write skipped: $e');
        }
      }

      // Push to Vite Sync API in debug mode
      if (kDebugMode) {
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
      }

      notifyListeners();
    } catch (e) {
      debugPrint('ChurchSyncService syncNewVisitor error: $e');
    }
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _sermonsSubscription?.cancel();
    _leadershipSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
