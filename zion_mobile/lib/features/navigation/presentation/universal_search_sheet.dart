import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../community/models/member_directory_model.dart';
import '../../community/services/member_directory_service.dart';
import '../../devotional/presentation/mood_psalms_screen.dart';
import '../../media/presentation/online_radio_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';

class SearchResultItem {
  final String title;
  final String subtitle;
  final String category; // 'Waumini & Ujuzi' | 'Biblia' | 'Tenzi' | 'Mahubiri' | 'Redio' | 'Matangazo' | 'Jumuiya'
  final IconData icon;
  final Color color;
  final MemberSkillProfile? memberProfile;
  final String? phone;
  final String? actionRoute;
  final String? bookName;
  final String? chapterNumber;
  final String? verseNumber;
  final int? tenziNumber;

  const SearchResultItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.color,
    this.memberProfile,
    this.phone,
    this.actionRoute,
    this.bookName,
    this.chapterNumber,
    this.verseNumber,
    this.tenziNumber,
  });
}

class UniversalSearchSheet extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;
  const UniversalSearchSheet({super.key, this.onNavigateToTab});

  @override
  State<UniversalSearchSheet> createState() => _UniversalSearchSheetState();
}

class _UniversalSearchSheetState extends State<UniversalSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final MemberDirectoryService _directoryService = MemberDirectoryService();

  String _selectedCategory = 'Zote';
  String _query = '';

  final List<String> _filters = [
    'Zote',
    'Waumini & Ujuzi',
    'Biblia',
    'Tenzi',
    'Mahubiri',
    'Redio',
    'Matangazo',
    'Jumuiya',
  ];

  // Instagram-style Trending Explore Pills
  final List<Map<String, dynamic>> _trendingPills = [
    {'label': '🥬 David (Mkulima)', 'query': 'David'},
    {'label': '💻 Emmanuel (Apps)', 'query': 'Emmanuel'},
    {'label': '🧵 Sarah (Mavazi)', 'query': 'Sarah'},
    {'label': '⚡ Fundi Umeme', 'query': 'Umeme'},
    {'label': '💊 Dawa & Afya', 'query': 'Dawa'},
    {'label': '📻 Praiseworld Nigeria', 'query': 'Praiseworld'},
    {'label': '📻 Safina Radio', 'query': 'Safina'},
    {'label': '📖 Zaburi 23', 'query': 'Zaburi 23'},
    {'label': '🎵 Tenzi #130', 'query': 'Tenzi 130'},
    {'label': '🧱 Ujenzi wa Hekalu', 'query': 'Ujenzi'},
    {'label': '🕊️ Askofu Messi Mgala', 'query': 'Messi Mgala'},
    {'label': '🙏 Uponyaji & Faraja', 'query': 'Uponyaji'},
  ];

  static const List<SearchResultItem> _staticDatabase = [
    // Biblia
    SearchResultItem(
      title: 'Yohana 3:16',
      subtitle: 'Kwa maana jinsi hii Mungu aliupenda ulimwengu, hata akamtoa Mwanawe wa pekee...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Zaburi 23:1-4',
      subtitle: 'Bwana ndiye mchungaji wangu, sitapungukiwa na kitu. Katika malisho ya majani mabichi hunilaza...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Isaya 41:10',
      subtitle: 'Usiogope, kwa maana mimi ni pamoja nawe; usifadhaike, kwa maana mimi ni Mungu wako...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Wafilipi 4:6-7',
      subtitle: 'Msijisumbue kwa neno lo lote; bali katika kila neno kwa kusali na kuomba, pamoja na kushukuru...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Zaburi 132:13-14',
      subtitle: 'Kwa kuwa Bwana ameichagua Sayuni; Ameitamani akae ndani yake. Hapa ndipo patakapokuwa pumziko langu...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Isaya 60:1-3',
      subtitle: 'Ondoka, uangaze; kwa kuwa nuru yako imekuja, na utukufu wa Bwana umekuzukia...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Mathayo 6:33',
      subtitle: 'Basi utafuteni kwanza ufalme wake, na haki yake; na hayo yote mtazidishiwa...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Warumi 8:28',
      subtitle: 'Nasi twajua ya kuwa katika mambo yote Mungu hufanya kazi pamoja na wale wampendao...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Waebrania 11:1',
      subtitle: 'Basi imani ni kuwa na hakika ya mambo yatarajiwayo, ni bayana ya mambo yasiyoonekana...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: '1 Wakorintho 13:4-8',
      subtitle: 'Upendo huvumilia, hufadhili; upendo hauhusudu; upendo hautakabari, haujivuni...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Mithali 3:5-6',
      subtitle: 'Mtumaini Bwana kwa moyo wako wote, wala usizitegemee akili zako mwenyewe; Katika njia zako zote mkiri yeye...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Yeremia 29:11',
      subtitle: 'Maana nayajua mawazo ninayowawazia ninyi, asema Bwana, ni mawazo ya amani wala si ya mabaya...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Zaburi 91:1-2',
      subtitle: 'Aketiye mahali pa siri pake Aliye Juu Atakaa katika uvuli wake Mwenyezi. Nitasema, Bwana ndiye kimbilio langu...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),
    SearchResultItem(
      title: 'Yohana 14:1-3',
      subtitle: 'Msifadhaike mioyoni mwenu; mnamwamini Mungu, niaminini na mimi. Nyumbani mwa Baba yangu mna makao mengi...',
      category: 'Biblia',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F52BA),
    ),

    // Tenzi za Rohoni
    SearchResultItem(
      title: 'Tenzi 130: Salama Rohoni Mwangu',
      subtitle: 'Nionapo amani kama shwari, au nionapo shida; Kwa hali yoyote umenifundisha: Ni salama rohoni mwangu...',
      category: 'Tenzi',
      icon: Icons.music_note_rounded,
      color: Color(0xFFC59B27),
    ),
    SearchResultItem(
      title: 'Tenzi 1: Mtakatifu, Mtakatifu, Mtakatifu',
      subtitle: 'Mtakatifu, Mtakatifu, Mtakatifu! Bwana Mungu Mwenyezi! Asubuhi na mapema sifa zetu zitaenda Kwako...',
      category: 'Tenzi',
      icon: Icons.music_note_rounded,
      color: Color(0xFFC59B27),
    ),
    SearchResultItem(
      title: 'Tenzi 23: Yesu Kwetu Ni Rafiki',
      subtitle: 'Yesu kwetu ni Rafiki, Hwambiwa haja pia; Tukiomba kwa Babaye, Maombi asikia...',
      category: 'Tenzi',
      icon: Icons.music_note_rounded,
      color: Color(0xFFC59B27),
    ),
    SearchResultItem(
      title: 'Tenzi 47: Cha Kutumaini Sina',
      subtitle: 'Cha kutumaini sina, ila damu yake Bwana; Sina wema wa kutosha, Dhambi zangu kuziosha...',
      category: 'Tenzi',
      icon: Icons.music_note_rounded,
      color: Color(0xFFC59B27),
    ),
    SearchResultItem(
      title: 'Tenzi 88: Usinipite Mwokozi',
      subtitle: 'Usinipite Mwokozi, Unisikie; Unapowazuru wengine, Usinipite...',
      category: 'Tenzi',
      icon: Icons.music_note_rounded,
      color: Color(0xFFC59B27),
    ),

    // Redio za Mtandaoni (Gospel & News)
    SearchResultItem(
      title: 'Praiseworld Radio (Nigeria)',
      subtitle: 'Afro Gospel, Praise, Worship & Contemporary African Christian Hits',
      category: 'Redio',
      icon: Icons.radio_rounded,
      color: Color(0xFFE50914),
      actionRoute: 'radio',
    ),
    SearchResultItem(
      title: 'Radio Safina (Tanzania)',
      subtitle: 'Nyimbo za injili za Kiswahili, mafundisho na maombi ya moja kwa moja',
      category: 'Redio',
      icon: Icons.radio_rounded,
      color: Color(0xFFE50914),
      actionRoute: 'radio',
    ),
    SearchResultItem(
      title: 'Radio Maria Tanzania',
      subtitle: 'Sala ya asubuhi, rozari, misa na nyimbo za kikatoliki',
      category: 'Redio',
      icon: Icons.radio_rounded,
      color: Color(0xFFE50914),
      actionRoute: 'radio',
    ),
    SearchResultItem(
      title: 'BBC Swahili Radio',
      subtitle: 'Matangazo ya habari za ulimwengu, Dira ya Dunia na makala za Kiswahili',
      category: 'Redio',
      icon: Icons.radio_rounded,
      color: Color(0xFFDC2626),
      actionRoute: 'radio',
    ),
    SearchResultItem(
      title: 'DW Swahili (Deutsche Welle)',
      subtitle: 'Habari za Afrika na kimataifa, uchambuzi na masuala ya kijamii',
      category: 'Redio',
      icon: Icons.radio_rounded,
      color: Color(0xFFDC2626),
      actionRoute: 'radio',
    ),

    // Matangazo ya Kanisa
    SearchResultItem(
      title: 'Ujenzi wa Hekalu — Harambee ya Mabati & Sakafu',
      subtitle: 'Ununuzi wa mabati 120 kwa hekalu jipya la Mbagala Kwa Matope. Lipa Namba 5524101',
      category: 'Matangazo',
      icon: Icons.campaign_rounded,
      color: Color(0xFFF59E0B),
      actionRoute: 'notifications',
    ),
    SearchResultItem(
      title: 'Maombi ya Vikundi vya Nyumbani (Jumuiya)',
      subtitle: 'Vikundi vyote 5 vya maombi vinakutana Ijumaa saa 10:00 Jioni majumbani',
      category: 'Matangazo',
      icon: Icons.groups_rounded,
      color: Color(0xFF16A34A),
      actionRoute: 'notifications',
    ),
    SearchResultItem(
      title: 'Mazoezi ya Kwaya Kuu & Galilaya',
      subtitle: 'Waimbaji wote kufika mazoezini Jumamosi saa 09:00 Asubuhi',
      category: 'Matangazo',
      icon: Icons.music_note_rounded,
      color: Color(0xFFF59E0B),
      actionRoute: 'notifications',
    ),

    // Jumuiya & Matawi
    SearchResultItem(
      title: 'Jumuiya ya Sayuni Kwa Matope',
      subtitle: 'Kiongozi: Mzee Boniface Mlay • Mkutano: Kila Ijumaa Saa 10:00 Jioni',
      category: 'Jumuiya',
      icon: Icons.groups_rounded,
      color: Color(0xFF16A34A),
    ),
    SearchResultItem(
      title: 'Tawi la Sayuni Arusha (Sakina)',
      subtitle: 'Mchungaji Msaidizi Alex • Ibada za Jumapili na Jumatano',
      category: 'Jumuiya',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF16A34A),
    ),
  ];

  List<SearchResultItem> _getAllDatabase() {
    final List<SearchResultItem> fullList = [];

    // 1. Inject live dynamic profiles from MemberDirectoryService
    for (final profile in _directoryService.allProfiles) {
      fullList.add(
        SearchResultItem(
          title: '${profile.fullName} (${profile.profession})',
          subtitle: '${profile.category} • ${profile.location} • ${profile.description}',
          category: 'Waumini & Ujuzi',
          icon: Icons.badge_rounded,
          color: const Color(0xFF10B981),
          memberProfile: profile,
          phone: profile.phone,
        ),
      );
    }

    // 2. Add static items
    fullList.addAll(_staticDatabase);

    return fullList;
  }

  List<SearchResultItem> get _filteredResults {
    final all = _getAllDatabase();
    final q = _query.trim().toLowerCase();

    return all.where((item) {
      final matchesCategory = _selectedCategory == 'Zote' || item.category == _selectedCategory;
      final matchesQuery = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q) ||
          (item.memberProfile?.profession.toLowerCase().contains(q) ?? false) ||
          (item.memberProfile?.category.toLowerCase().contains(q) ?? false) ||
          (item.memberProfile?.location.toLowerCase().contains(q) ?? false);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _onSelectResult(SearchResultItem item) {
    AppHaptics.mediumImpact();

    if (item.category == 'Waumini & Ujuzi' && item.memberProfile != null) {
      _showMemberProfileSheet(item.memberProfile!);
      return;
    }

    Navigator.pop(context);

    if (item.actionRoute == 'radio') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OnlineRadioScreen()),
      );
    } else if (item.actionRoute == 'notifications') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    } else if (item.category == 'Biblia' || item.category == 'Tenzi') {
      widget.onNavigateToTab?.call(3); // Book tab
    } else if (item.category == 'Mahubiri') {
      widget.onNavigateToTab?.call(2); // Media tab
    } else if (item.category == 'Jumuiya') {
      widget.onNavigateToTab?.call(1); // Community tab
    }
  }

  void _showMemberProfileSheet(MemberSkillProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(profile.avatarEmoji, style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: AppTypography.titleMedium(color: AppColors.textPrimary),
                          ),
                          Text(
                            profile.profession,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '📍 ${profile.location} • ${profile.jumuiya}',
                            style: AppTypography.caption(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    profile.description,
                    style: AppTypography.bodySmall(color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          AppHaptics.mediumImpact();
                          final clean = profile.phone.replaceAll(' ', '');
                          final uri = Uri.parse('tel:$clean');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.phone_in_talk_rounded),
                        label: const Text('Piga Simu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          AppHaptics.mediumImpact();
                          final clean = profile.phone.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '');
                          final msg = Uri.encodeComponent(
                            'Bwana Yesu Asifiwe ${profile.fullName}, nimepata mawasiliano yako kwenye App ya Kanisa la Zion Jerusalem.',
                          );
                          final uri = Uri.parse('https://wa.me/$clean?text=$msg');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: const Color(0xFF181C23).withOpacity(0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: const Color(0xFF0D52CD).withOpacity(0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D52CD).withOpacity(0.3),
              blurRadius: 36,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag Indicator Handle
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFC59B27)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF0A2540),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tafuta Katika Sayuni',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Waumini, kazi, Biblia, tenzi, redio na matangazo',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search TextField
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: false,
                  cursorColor: AppColors.primary,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w500),
                  onChanged: (val) => setState(() => _query = val),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E2530),
                    hintText: 'Tafuta muumini, andiko, tenzi, redio au habari...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 18),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Instagram-Style Category Filter Pills
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (ctx, idx) {
                  final cat = _filters[idx];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        AppHaptics.selectionClick();
                        setState(() => _selectedCategory = cat);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF1E6BFF), Color(0xFF0D52CD)],
                                )
                              : null,
                          color: isSelected ? null : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0D52CD)
                                : Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Trending Explore Pills (When search query is empty)
            if (_query.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Row(
                  children: [
                    const Icon(Icons.explore_rounded, color: AppColors.primary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'ZINAZOTAFUTWA ZAIDI:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _trendingPills.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 6),
                  itemBuilder: (ctx, idx) {
                    final pill = _trendingPills[idx];
                    return InkWell(
                      onTap: () {
                        AppHaptics.selectionClick();
                        _controller.text = pill['query'];
                        setState(() => _query = pill['query']);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2530),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF334155),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          pill['label'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Results Counter & Active List
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Matokeo (${results.length})',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_query.isNotEmpty)
                    Text(
                      'Kutafuta "$_query"',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 56,
                            color: Colors.white.withOpacity(0.25),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _query.isEmpty
                                ? 'Andika neno kutafuta popote'
                                : 'Hakuna matokeo ya "$_query"',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Offer Spiritual Guidance Shortcut
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MoodPsalmsScreen(initialQuery: _query),
                                ),
                              );
                            },
                            icon: const Icon(Icons.spa_rounded, color: AppColors.gold, size: 16),
                            label: const Text('Tafuta Ushauri wa Kiroho & Sala'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: results.length,
                      itemBuilder: (ctx, idx) {
                        final item = results[idx];
                        final isMember = item.category == 'Waumini & Ujuzi';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => _onSelectResult(item),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: item.color.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: isMember && item.memberProfile != null
                                        ? Text(item.memberProfile!.avatarEmoji, style: const TextStyle(fontSize: 18))
                                        : Icon(item.icon, color: item.color, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: item.color.withOpacity(0.18),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.category.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: item.color,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ),
                                            if (item.phone != null) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                item.phone!,
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.5),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.subtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.65),
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white38,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
