import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/church_auth_service.dart';
import '../models/church_announcement.dart';

class NotificationsDataService extends ChangeNotifier {
  static final NotificationsDataService _instance =
      NotificationsDataService._internal();
  factory NotificationsDataService() => _instance;
  NotificationsDataService._internal() {
    _loadReadStatus();
  }

  static const String _readKey = 'zion_read_announcement_ids';

  final List<ChurchAnnouncement> _announcements = [
    ChurchAnnouncement(
      id: 'ann-1',
      title: '🔔 Ibada Kuu ya Jumapili Hii & Meza ya Bwana',
      category: 'Ibada',
      date: 'Jumapili, 6 Septemba 2026',
      time: 'Saa 02:30 Asubuhi - 07:00 Mchana',
      location: 'Hekalu Kuu la Sayuni, Mbagala Kwa Matope',
      summary:
          'Askofu Mercy Mgalla ataongoza ibada ya sifa, uponyaji na ushirika mtakatifu.',
      fullDetails:
          'Tunakukaribisha wewe, familia yako na majirani katika Ibada Kuu ya Ushindi. Kutakuwa na meza ya Bwana, maombi maalum ya uponyaji kwa wagonjwa, na neno la kinabii la kuvuka dhoruba. '
          'Mavazi ya heshima yanazingatiwa. Waumini wanaotaka kubatizwa wafike ofisi ya kanisa saa 01:30 asubuhi.',
      preacherOrLeader: 'Askofu Mercy Mgalla',
      isHighPriority: true,
    ),
    ChurchAnnouncement(
      id: 'ann-2',
      title: '🔥 Mkesha Mkuu wa Ukombozi (War Room Overnight)',
      category: 'Mkesha',
      date: 'Ijumaa Ijayo, 11 Septemba 2026',
      time: 'Saa 03:00 Usiku Hadi Mapambazuko (Asubuhi)',
      location: 'Hekalu Kuu la Sayuni',
      summary:
          'Mkesha wa kufunga na kuomba kubomoa ngome na kuachilia vifungo vya kiroho.',
      fullDetails:
          'Mkesha huu maalum unakutanisha matawi yote 5 ya Sayuni (Mbagala, Chamazi, Kibada, Charambe, Vikindu). '
          'Wazee wa maombi, jopo la maombezi na kwaya zote zitakuwepo. Usikose nguvu ya upako wa usiku wa manane kama Paulo na Sila.',
      preacherOrLeader: 'Mch. Msaidizi Alex & Wazee wa Maombi',
      isHighPriority: true,
    ),
    ChurchAnnouncement(
      id: 'ann-3',
      title: '🏗️ Harambee ya Upanuzi wa Hekalu & Ujenzi wa Madarasa ya Watoto',
      category: 'Ujenzi',
      date: 'Mwezi Huu wa Septemba 2026',
      time: 'Michango Inapokelewa Kila Siku',
      location: 'Ofisi ya Hazina / Lipa Namba M-Pesa 5522114',
      summary:
          'Ujenzi wa jengo la kisasa la ibada ya watoto (Sunday School) na uzio wa hekalu.',
      fullDetails:
          'Kamati ya Ujenzi inawashukuru waumini wote waliojitolea mifuko ya saruji na nondo. Tumeanza kumwaga nguzo za madarasa 4 mapya ya watoto. '
          'Kiwango cha ushiriki: Mfuko 1 wa Saruji ni TZS 22,000. Unaweza kutuma sadaka ya ujenzi moja kwa moja kupitia kitufe cha "Sadaka & Zaka" kwenye app.',
      preacherOrLeader: 'Kamati ya Ujenzi & Mzee James Robert',
      isHighPriority: false,
    ),
    ChurchAnnouncement(
      id: 'ann-4',
      title: '💍 Semina ya Wanandoa & Vijana Wanaotarajia Ndoa',
      category: 'Semina',
      date: 'Jumamosi, 19 Septemba 2026',
      time: 'Saa 08:30 Mchana - 11:30 Jioni',
      location: 'Ukumbi wa Sayuni Fellowship',
      summary:
          'Kujenga misingi imara ya kiungu katika ndoa, mawasiliano na uchumi wa familia.',
      fullDetails:
          'Wamama na Wababa wa Sayuni pamoja na vijana wanakaribishwa katika semina ya wazi ya ujenzi wa ndoa imara na kulea watoto katika njia ya Bwana. '
          'Kutakuwa na chakula cha jioni cha pamoja na nafasi ya maswali na ushauri wa kichungaji kwa siri.',
      preacherOrLeader: 'Mama Mch. Sarah Mgala & Wachungaji Washauri',
      isHighPriority: false,
    ),
    ChurchAnnouncement(
      id: 'ann-5',
      title: '🤝 Jumuiya za Nyumbani (Home Cells) Mzunguko wa Ijumaa',
      category: 'Jumuiya',
      date: 'Kila Ijumaa',
      time: 'Saa 10:00 Jioni - 11:30 Jioni',
      location: 'Jumuiya za Bethlehemu, Galilaya, Nazareti, Yerusalemu, Sayuni',
      summary: 'Ibada za nyumbani katika mitaa ya Mbagala na Chamazi.',
      fullDetails:
          'Kila muumini anahimizwa kuhudhuria jumuiya iliyo karibu na mtaa wake kwa ajili ya kufarijiana, kuombeana na kushirikiana wakati wa shida na raha. '
          'Tazama tab ya "Jumuiya" kupata namba ya kiongozi wa mtaa wako.',
      preacherOrLeader: 'Idara ya Jumuiya za Nyumbani',
      isHighPriority: false,
      targetAudience: 'all',
    ),
    ChurchAnnouncement(
      id: 'ann-lead-1',
      title: '🔒 Kikao Maalum cha Baraza la Wazee & Mashemasi',
      category: 'Taarifa Kuu',
      date: 'Jumamosi Hii, Saa 10:00 Jioni',
      time: 'Saa 10:00 Jioni - 12:30 Jioni',
      location: 'Chumba cha Mkutano cha Wachungaji (Pastoral Boardroom)',
      summary: 'Tathmini ya maendeleo ya ujenzi na maandalizi ya Semina.',
      fullDetails:
          'Kikao hiki ni kwa ajili ya Wazee wa Kanisa wote, Mashemasi, Katibu na Viongozi wote wa Idara. '
          'Tafadhali fika na ripoti fupi ya idara yako kwa mwezi uliopita. Taarifa hii ni ya siri ya uongozi.',
      preacherOrLeader: 'Askofu Mkuu Mercy Mgalla & Katibu Mkuu',
      isHighPriority: true,
      targetAudience: 'leaders',
    ),
  ];

  List<ChurchAnnouncement> get announcements => _announcements;

  /// Returns announcements filtered for the current user's role:
  /// - If user is Admin or Leader: returns all announcements
  /// - If user is Member or Guest: returns ONLY announcements where targetAudience == 'all'
  List<ChurchAnnouncement> get filteredAnnouncements {
    final auth = ChurchAuthService();
    if (auth.isAdmin || auth.isLeader) {
      return _announcements;
    }
    return _announcements.where((a) => a.targetAudience == 'all').toList();
  }

  int get unreadCount => filteredAnnouncements.where((a) => !a.isRead).length;

  static const String _syncedNoticesKey = 'zion_synced_portal_notices';

  Future<void> _loadReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Load any synced notices from portal stored in preferences
      final savedNoticesJson = prefs.getString(_syncedNoticesKey);
      if (savedNoticesJson != null && savedNoticesJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(savedNoticesJson);
          for (final item in decoded.reversed) {
            final announcement =
                ChurchAnnouncement.fromJson(Map<String, dynamic>.from(item));
            if (!_announcements.any((a) => a.id == announcement.id)) {
              _announcements.insert(0, announcement);
            }
          }
        } catch (_) {}
      }

      // 2. Apply read status
      final readIds = prefs.getStringList(_readKey) ?? [];
      for (final a in _announcements) {
        if (readIds.contains(a.id)) {
          a.isRead = true;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Dynamically inserts a new announcement received in real-time from the Web Portal Katibu/Admin
  Future<void> addAnnouncementFromPortal(
      ChurchAnnouncement announcement) async {
    // Remove if already present
    _announcements.removeWhere((a) => a.id == announcement.id);
    // Prepend to top of list as unread
    announcement.isRead = false;
    _announcements.insert(0, announcement);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      List<dynamic> list = [];
      final raw = prefs.getString(_syncedNoticesKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          list = jsonDecode(raw);
        } catch (_) {}
      }
      list.removeWhere((item) => item is Map && item['id'] == announcement.id);
      list.insert(0, announcement.toJson());
      await prefs.setString(_syncedNoticesKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    final item = _announcements.firstWhere((a) => a.id == id,
        orElse: () => _announcements.first);
    if (!item.isRead) {
      item.isRead = true;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        final readIds = prefs.getStringList(_readKey) ?? [];
        if (!readIds.contains(id)) {
          readIds.add(id);
          await prefs.setStringList(_readKey, readIds);
        }
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    for (final a in _announcements) {
      a.isRead = true;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final allIds = _announcements.map((a) => a.id).toList();
      await prefs.setStringList(_readKey, allIds);
    } catch (_) {}
  }
}
