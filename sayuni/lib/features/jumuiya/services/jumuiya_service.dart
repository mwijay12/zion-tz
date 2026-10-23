import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jumuiya_model.dart';

class JumuiyaService {
  static const String _prayersKey = 'zion_prayer_requests';

  static const List<HomeCell> homeCells = [
    HomeCell(
      id: 'cell-1',
      name: 'Jumuiya ya Bethlehemu',
      area: 'Kwa Matope - Mbagala',
      leader: 'Mzee Boniface Mlay',
      phone: '+255713444555',
      meetingDay: 'Kila Ijumaa',
      meetingTime: '10:00 Jioni',
      membersCount: 28,
    ),
    HomeCell(
      id: 'cell-2',
      name: 'Jumuiya ya Galilaya',
      area: 'Chamazi Kati',
      leader: 'Mama Mary Kimaro',
      phone: '+255754888999',
      meetingDay: 'Kila Ijumaa',
      meetingTime: '10:30 Jioni',
      membersCount: 22,
    ),
    HomeCell(
      id: 'cell-3',
      name: 'Jumuiya ya Nazareti',
      area: 'Rangi Tatu, Mbagala',
      leader: 'Mzee Thomas Temu',
      phone: '+255768112233',
      meetingDay: 'Kila Ijumaa',
      meetingTime: '10:00 Jioni',
      membersCount: 19,
    ),
    HomeCell(
      id: 'cell-4',
      name: 'Jumuiya ya Yerusalemu',
      area: 'Charambe Mwisho',
      leader: 'Mwinjilisti Daudi Shayo',
      phone: '+255714556677',
      meetingDay: 'Kila Ijumaa',
      meetingTime: '10:00 Jioni',
      membersCount: 24,
    ),
    HomeCell(
      id: 'cell-5',
      name: 'Jumuiya ya Sayuni',
      area: 'Mbagala Kuu / Mangise',
      leader: 'Mama Rehema Mushi',
      phone: '+255755998877',
      meetingDay: 'Kila Ijumaa',
      meetingTime: '11:00 Jioni',
      membersCount: 17,
      imagePath: 'assets/images/jumuiya_fellowship_1788577443594.jpg',
    ),
  ];

  static const List<ChurchMinistryGroup> ministryGroups = [
    ChurchMinistryGroup(
      id: 'group-choir-main',
      name: 'Kwaya Kuu ya Sayuni',
      category: 'Kwaya',
      leader: 'Mwl. Joshua Msigwa',
      leaderTitle: 'Mwalimu Mkuu wa Kwaya',
      phone: '+255754000301',
      meetingSchedule: 'Jumanne & Jumamosi • 10:30 Jioni',
      description:
          'Kwaya Kuu inayoongoza sifa na kuabudu katika ibada zote kuu za Jumapili na mikutano ya injili.',
      imagePath: 'assets/images/zion_worship_choir_1788577423671.jpg',
      membersCount: 68,
      activities: ['Mazoezi ya Sauti', 'Albamu za Nyimbo', 'Huduma za Nje'],
    ),
    ChurchMinistryGroup(
      id: 'group-youth',
      name: 'Umoja wa Vijana wa Sayuni (Youth Fellowship)',
      category: 'Vijana',
      leader: 'Ndg. Emmanuel Mbise',
      leaderTitle: 'Mwenyekiti wa Vijana',
      phone: '+255713000302',
      meetingSchedule: 'Jumamosi • 09:00 Alasiri',
      description:
          'Vijana wa Sayuni wakisimama imara katika neno, uamsho, vipaji vya muziki na uinjilisti wa kisasa.',
      imagePath: 'assets/images/church_youth_fellowship.jpg',
      membersCount: 94,
      activities: ['Kwaya ya Vijana', 'Makongamano', 'Ujasiriamali wa Kiroho'],
    ),
    ChurchMinistryGroup(
      id: 'group-women',
      name: 'Umoja wa Wanawake wa Sayuni (Wamama)',
      category: 'Wamama',
      leader: 'Mama Mchungaji Sarah Mgala',
      leaderTitle: 'Mlezi wa Idara ya Wamama',
      phone: '+255755000303',
      meetingSchedule: 'Alhamisi • 09:30 Alasiri',
      description:
          'Wamama wa Sayuni wakiwa nguzo ya maombi ya familia, kusaidia wasiojiweza, na malezi ya watoto.',
      imagePath: 'assets/images/church_women_fellowship.jpg',
      membersCount: 118,
      activities: ['Maombi ya Wamama', 'Kusaidia Yatima', 'Semina za Ndoa'],
    ),
    ChurchMinistryGroup(
      id: 'group-men',
      name: 'Umoja wa Wanaume wa Sayuni (Wababa)',
      category: 'Wababa',
      leader: 'Mzee James Robert',
      leaderTitle: 'Mwenyekiti wa Wanaume',
      phone: '+255768000304',
      meetingSchedule: 'Jumapili ya Mwisho wa Mwezi • 11:30 Jioni',
      description:
          'Wababa na wazee wa kanisa wakisimamia misingi ya uongozi wa kiungu katika familia na kanisa.',
      imagePath: 'assets/images/church_men_fellowship.jpg',
      membersCount: 76,
      activities: [
        'Uongozi wa Familia',
        'Miradi ya Ujenzi',
        'Ushauri wa Kijamii'
      ],
    ),
    ChurchMinistryGroup(
      id: 'group-intercessors',
      name: 'Idara ya Maombi & Maombezi (Intercessors)',
      category: 'Maombi',
      leader: 'Mwinjilisti Grace Malisa',
      leaderTitle: 'Mwangalizi wa War Room',
      phone: '+255714000305',
      meetingSchedule: 'Kila Siku • Saa 12:00 Asubuhi & 06:00 Usiku',
      description:
          'Walinzi wa kuta za Yerusalemu wanaoomba mfululizo kwa ajili ya kanisa, wagonjwa, na taifa.',
      imagePath: 'assets/images/pastoral_leadership_1788577468703.jpg',
      membersCount: 52,
      activities: [
        'Mikesha ya Kila Mwezi',
        'Kufunga na Kuomba',
        'Kuponya Wagonjwa'
      ],
    ),
  ];

  Future<List<PrayerRequestItem>> getPrayerRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prayersKey);
    if (jsonString == null) {
      return [
        PrayerRequestItem(
          id: 'p-1',
          senderName: 'Mshirika wa Sayuni',
          phone: '+255788123456',
          category: 'Uponyaji',
          details: 'Maombi kwa ajili ya mama mzazi aliyelazwa hospitali.',
          isConfidential: false,
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    }
    final List<dynamic> list = json.decode(jsonString);
    return list
        .map((item) => PrayerRequestItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitPrayerRequest(PrayerRequestItem request) async {
    final list = await getPrayerRequests();
    list.insert(0, request);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prayersKey, json.encode(list.map((p) => p.toJson()).toList()));
  }
}
