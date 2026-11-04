import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/member_directory_model.dart';

class MemberDirectoryService extends ChangeNotifier {
  static final MemberDirectoryService _instance =
      MemberDirectoryService._internal();
  factory MemberDirectoryService() => _instance;
  MemberDirectoryService._internal() {
    _loadCustomMembers();
  }

  static const String _customMembersKey = 'zion_custom_member_skills';

  static const List<MemberSkillProfile> _initialProfiles = [
    MemberSkillProfile(
      id: 'member-david-mwijage',
      fullName: 'David Erick Mwijage',
      profession: 'Mhandisi wa Mifumo ya TEHAMA, Media & Apps',
      category: 'Tehama & Apps',
      description:
          'Kusimamia mifumo ya kidijitali ya kanisa, website ya kanisa, kurusha matangazo mtandaoni, na huduma ya Tehama na sauti.',
      phone: '+255790942616',
      location: 'Mbagala Kwa Matope',
      jumuiya: 'Umoja wa Vijana (Youth)',
      experienceYears: 'Miaka 6',
      avatarEmoji: '💻',
    ),
    MemberSkillProfile(
      id: 'member-emmanuel-majaliwa',
      fullName: 'Mwl. Emmanuel Majaliwa',
      profession: 'Mwalimu Mkuu wa Kwaya & Muziki wa Injili',
      category: 'Muziki & Sifa',
      description:
          'Kufundisha sauti, kutunga na kurekodi nyimbo za kwaya (Kwaya ya Upendo na Kwaya Kuu), na kuongoza mazoezi ya uimbaji hekaluni.',
      phone: '+255745896311',
      location: 'Mbagala Kwa Matope',
      jumuiya: 'Kwaya ya Upendo',
      experienceYears: 'Miaka 10',
      avatarEmoji: '🎼',
    ),
    MemberSkillProfile(
      id: 'member-jonathan-praise',
      fullName: 'Jonathan',
      profession: 'Kiongozi wa Sifa na Kuabudu (Praise & Worship)',
      category: 'Muziki & Sifa',
      description:
          'Kuongoza jopo la waimbaji wa Praise Team katika ibada za Jumapili, mikesha na makongamano ya maombi Sayuni.',
      phone: '+255746296707',
      location: 'Mbagala Rangi Tatu',
      jumuiya: 'Sayuni Praise Team',
      experienceYears: 'Miaka 7',
      avatarEmoji: '🎸',
    ),
    MemberSkillProfile(
      id: 'member-sarah-tailor',
      fullName: 'Mama Sarah Mgalla',
      profession: 'Mbunifu wa Nguo & Sare za Harusi',
      category: 'Mavazi & Urembo',
      description:
          'Ninashona gauni za harusi, suti za kiume, sare za kwaya, na nguo za watoto kwa ufundi wa hali ya juu. Vifaa na vitambaa bora vinapatikana.',
      phone: '+255755000303',
      location: 'Mbagala Kwa Matope',
      jumuiya: 'Umoja wa Wanawake (Wamama)',
      experienceYears: 'Miaka 12',
      avatarEmoji: '🧵',
    ),
    MemberSkillProfile(
      id: 'member-john-electrician',
      fullName: 'Fundi John Temu',
      profession: 'Fundi Umeme, Solar & Ujenzi',
      category: 'Ufundi & Ujenzi',
      description:
          'Ufungaji wa mifumo ya umeme wa majumbani (Wiring), ufungaji wa Solar Power na taa za hekalu, pamoja na marekebisho ya maji na mifumo ya pampu.',
      phone: '+255768112233',
      location: 'Chamazi Kati',
      jumuiya: 'Jumuiya ya Nazareti',
      experienceYears: 'Miaka 8',
      avatarEmoji: '⚡',
    ),
    MemberSkillProfile(
      id: 'member-mary-health',
      fullName: 'Dr. Mary Kimaro',
      profession: 'Afisa Afya ya Jamii & Duka la Dawa',
      category: 'Afya & Ustawi',
      description:
          'Ninamiliki duka la dawa (Pharmacy) lililosajiliwa. Natoa vipimo vya awali vya presha na sukari, ushauri wa lishe kwa wazee na watoto kwa waumini wa kanisa.',
      phone: '+255754888999',
      location: 'Mbagala Kijichi',
      jumuiya: 'Jumuiya ya Galilaya',
      experienceYears: 'Miaka 10',
      avatarEmoji: '🩺',
    ),
    MemberSkillProfile(
      id: 'member-grace-teacher',
      fullName: 'Mwl. Grace Malisa',
      profession: 'Mwalimu wa Sayansi & Tuition ya Watoto',
      category: 'Elimu & Mafunzo',
      description:
          'Nafundisha Hisabati, Fizikia na Kemia kwa wanafunzi wa sekondari (Form 1 - Form 4). Pia nina klabu ya usomaji wa watoto wa Sunday School.',
      phone: '+255714000305',
      location: 'Charambe Mwisho',
      jumuiya: 'Jumuiya ya Yerusalemu',
      experienceYears: 'Miaka 7',
      avatarEmoji: '📚',
    ),
    MemberSkillProfile(
      id: 'member-boniface-transport',
      fullName: 'Mzee Boniface Mlay',
      profession: 'Usafirishaji wa Mizigo & Vifaa vya Ujenzi',
      category: 'Biashara',
      description:
          'Usafirishaji wa mizigo, mchanga, kokoto, mawe ya msingi na vifaa vya kuhama nyumba kwa magari ya canter na tipper.',
      phone: '+255713444555',
      location: 'Mbagala Mangise',
      jumuiya: 'Jumuiya ya Sayuni',
      experienceYears: 'Miaka 15',
      avatarEmoji: '🚛',
    ),
  ];

  List<MemberSkillProfile> _customProfiles = [];

  List<MemberSkillProfile> get allProfiles =>
      [..._customProfiles, ..._initialProfiles];

  Future<void> _loadCustomMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_customMembersKey);
      if (jsonStr != null) {
        final List<dynamic> list = json.decode(jsonStr);
        _customProfiles = list
            .map((item) =>
                MemberSkillProfile.fromJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> registerMemberSkill(MemberSkillProfile profile) async {
    _customProfiles.removeWhere((p) => p.id == profile.id);
    _customProfiles.insert(0, profile);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _customProfiles.map((p) => p.toJson()).toList();
      await prefs.setString(_customMembersKey, json.encode(list));
    } catch (_) {}
  }
}
