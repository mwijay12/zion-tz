import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../models/home_content.dart';
import '../services/home_service.dart';
import '../../notes/presentation/notes_screen.dart';
import '../../branches/presentation/church_branches_screen.dart';
import '../../prayer/presentation/prayer_war_room_screen.dart';
import '../../growth/presentation/discipleship_growth_screen.dart';
import '../../pastoral/presentation/appointments_screen.dart';
import '../../giving/presentation/giving_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../notifications/services/notifications_data_service.dart';
import '../../../core/services/church_customization_service.dart';
import '../../navigation/presentation/universal_search_sheet.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex) onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ChurchCustomizationService().init();
  }

  void _shareDevotional(DevotionalContent devotional) {
    AppHaptics.lightImpact();
    final hymnText = (devotional.recommendedHymnNumber != null &&
            devotional.recommendedHymnTitle != null)
        ? '\n🎵 *Wimbo wa Tenzi wa Leo:* Tenzi #${devotional.recommendedHymnNumber} — ${devotional.recommendedHymnTitle}\n'
        : '';
    final text = '''
*NENO LA SIKU — ZION JERUSALEM CHURCH*
Kwa Matope, Mbagala, Dar es Salaam
(100% Inafanya Kazi Bila Bando / Offline)

📖 *${devotional.reference}*
"${devotional.scriptureText}"

💡 *Tafakari:*
${devotional.reflection}

🙏 *Maombi:*
${devotional.prayer}
$hymnText
Ubarikiwe na Mungu wa Sayuni!
''';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final devotional = HomeService.todayDevotional;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Sticky Pinned App Bar (Protected from Status Bar Collision)
            SliverAppBar(
              pinned: true,
              floating: false,
              primary: false,
              elevation: 0,
              backgroundColor: const Color(0xFF07192F),
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              toolbarHeight: 60,
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primaryLight.withOpacity(0.45),
                          width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    // Zoomed + cropped so the heavy gold letter-ring of the raw
                    // asset no longer shows around the medallion.
                    child: Transform.scale(
                      scale: 1.3,
                      child: Image.asset(
                        'assets/images/zion_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ChurchProfile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Kwa Matope, Mbagala • Dar es Salaam',
                          style: TextStyle(
                            color: AppColors.primaryFixed,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ListenableBuilder(
                  listenable: NotificationsDataService(),
                  builder: (context, _) {
                    final unread = NotificationsDataService().unreadCount;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_active_rounded,
                              color: Colors.white, size: 22),
                          tooltip: 'Arifa & Matangazo ya Kanisa',
                          onPressed: () {
                            AppHaptics.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen()),
                            );
                          },
                        ),
                        if (unread > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 16, minHeight: 16),
                              child: Text(
                                '$unread',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                // Circular Profile Avatar Action Button
                Padding(
                  padding: const EdgeInsets.only(right: 14, left: 4),
                  child: InkWell(
                    onTap: () {
                      AppHaptics.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      );
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withOpacity(0.35),
                            Colors.white.withOpacity(0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.goldLight.withOpacity(0.75),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Sleek Sanctuary Hero Header
            SliverToBoxAdapter(
              child: _buildSanctuaryHero(context),
            ),

            // Content Area
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Sunday Service Countdown Banner
                  _buildSundayCountdownBanner(),
                  const SizedBox(height: 20),

                  // Quick Services Actions Grid
                  SectionHeader(
                    title: 'Huduma za Haraka',
                    subtitle: 'Miongozo, sala, na ushirika',
                  ),
                  _buildQuickActionGrid(),
                  const SizedBox(height: 24),

                  // Uongozi wa Kiroho (Pastoral Leadership Section)
                  SectionHeader(
                    title: 'Uongozi wa Kiroho',
                    subtitle: 'Askofu Mkuu na Watumishi wa Bwana',
                    actionText: 'Miadi',
                    onAction: () {
                      AppHaptics.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AppointmentsScreen()),
                      );
                    },
                  ),
                  _buildPastoralLeadershipSection(context),
                  const SizedBox(height: 24),

                  // Matawi & Huduma za Kiroho
                  SectionHeader(
                    title: 'Matawi & Huduma za Kiroho',
                    subtitle: 'Matawi ya kanisa, chumba cha maombi, na miadi',
                  ),
                  _buildBranchesAndMinistryHub(),
                  const SizedBox(height: 24),

                  // Daily Devotional Card (Neno la Siku)
                  SectionHeader(
                    title: 'Neno la Siku & Tafakari',
                    subtitle: devotional.reference,
                    actionText: 'Shiriki',
                    onAction: () => _shareDevotional(devotional),
                  ),
                  _buildDevotionalCard(devotional),
                  SizedBox(
                      height: 180 +
                          MediaQuery.of(context)
                              .padding
                              .bottom), // Generous clearance for persistent mini player and floating nav bar
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSanctuaryHero(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF07192F), // Seamless match with the pinned SliverAppBar
            Color(0xFF0A2540),
            Color(0xFF0D3262),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.gold.withOpacity(0.45),
            width: 1.3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF07192F).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withOpacity(0.45)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppColors.goldLight, size: 13),
                    SizedBox(width: 5),
                    Text(
                      'Mwaka wa Ushindi Mkuu',
                      style: TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.church_rounded,
                        color: AppColors.primaryFixed, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Sayuni Yerusalemu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Karibu Nyumbani mwa Bwana',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ibada, Neno la Uzima, na Ushirika wa Sayuni',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 14),
          // Prominent Integrated Search Bar (Matching Reference UI)
          InkWell(
            onTap: () {
              AppHaptics.lightImpact();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => UniversalSearchSheet(
                  onNavigateToTab: widget.onNavigateToTab,
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tafuta neno, huduma, biblia, kwaya...',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded,
                            size: 13, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Yote',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastoralLeadershipSection(BuildContext context) {
    return ListenableBuilder(
      listenable: ChurchCustomizationService(),
      builder: (context, _) {
        final customService = ChurchCustomizationService();
        final isDark = ChurchThemeService().isDarkMode;
        final primaryColor = ChurchThemeService().primaryColor;

        return AppCard(
          borderColor: AppColors.primary.withOpacity(0.22),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primaryLight
                              .withOpacity(isDark ? 0.55 : 0.45),
                          width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.20),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      backgroundImage: getChurchImageProvider(
                        customService.leadershipPhoto,
                        'assets/images/pastoral_leadership_1788577468703.jpg',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'UONGOZI WA KIROHO',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customService.bishopName,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Akiwa na Mume wake: ${customService.coLeaderName}',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : AppColors.textSecondaryLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                  height: 1,
                  color:
                      isDark ? const Color(0xFF26354A) : AppColors.borderLight),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        AppHaptics.lightImpact();
                        final uri = Uri.parse(
                            'https://wa.me/255754000111?text=Bwana%20Yesu%20Asifiwe%20Ofisi%20ya%20Askofu%20Zion%20Jerusalem');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 15, color: Color(0xFF16A34A)),
                      label: const Text(
                        'Ofisi ya Askofu',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 9, horizontal: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AppHaptics.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AppointmentsScreen()),
                        );
                      },
                      icon: const Icon(Icons.calendar_month_rounded, size: 15),
                      label: const Text(
                        'Weka Miadi',
                        style: TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 9, horizontal: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSundayCountdownBanner() {
    return AppCard(
      backgroundColor: AppColors.surfaceContainerOf(context),
      borderColor: AppColors.borderOf(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IBADA YA JUMAPILI HII',
                  style: AppTypography.caption(color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kuanzia Saa 08:30 Asubuhi',
                  style: AppTypography.titleMedium(
                      color: AppColors.textPrimaryOf(context)),
                ),
                Text(
                  'Maombi, Sunday School na Ibada Kuu ya Hekaluni',
                  style: AppTypography.caption(
                      color: AppColors.textSecondaryOf(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 288,
        mainAxisExtent: 146,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 4,
      itemBuilder: (context, i) => <Widget>[
        _buildActionTile(
          title: 'Biblia Takatifu',
          subtitle: 'Agano la Kale & Jipya',
          imageAsset: 'assets/images/3d_bible.png',
          accentColor: AppColors.primary,
          onTap: () =>
              widget.onNavigateToTab(3), // Book tab (Biblia, Tenzi, Notes)
        ),
        _buildActionTile(
          title: 'Sadaka & Zaka',
          subtitle: 'M-Pesa, Tigo & Benki',
          imageAsset: 'assets/images/3d_offering.png',
          accentColor: const Color(0xFF0E9E8F),
          onTap: () {
            AppHaptics.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GivingScreen()),
            );
          },
        ),
        _buildActionTile(
          title: 'Daftari la Mahubiri',
          subtitle: 'Kumbukumbu za Ibada',
          imageAsset: 'assets/images/3d_notes.png',
          accentColor: const Color(0xFF0284C7),
          onTap: () {
            AppHaptics.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotesScreen()),
            );
          },
        ),
        _buildActionTile(
          title: 'Vikundi vya Nyumbani',
          subtitle: 'Maombi & Jumuiya',
          imageAsset: 'assets/images/3d_groups.png',
          accentColor: const Color(0xFF16A34A),
          onTap: () => widget.onNavigateToTab(
              1), // Community tab (Jumuiya, War Room, Branches)
        ),
      ][i],
    );
  }

  Widget _buildBranchesAndMinistryHub() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 288,
        mainAxisExtent: 146,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 4,
      itemBuilder: (context, i) => <Widget>[
        _buildActionTile(
          title: 'Matawi ya Kanisa',
          subtitle: 'Mikoa 8 & Misheni',
          imageAsset: 'assets/images/3d_branch_network.png',
          accentColor: const Color(0xFF0284C7),
          onTap: () {
            AppHaptics.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChurchBranchesScreen()),
            );
          },
        ),
        _buildActionTile(
          title: 'Chumba cha Maombi',
          subtitle: 'War Room & Mfungo',
          imageAsset: 'assets/images/3d_praying_hands.png',
          accentColor: const Color(0xFFDC2626),
          onTap: () {
            AppHaptics.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrayerWarRoomScreen()),
            );
          },
        ),
        _buildActionTile(
          title: 'Safari ya Kiroho',
          subtitle: 'Roadmap ya Uanafunzi',
          imageAsset: 'assets/images/3d_roadmap.png',
          accentColor: const Color(0xFF059669),
          onTap: () {
            AppHaptics.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DiscipleshipGrowthScreen()),
            );
          },
        ),
        _buildActionTile(
          title: 'Miadi ya Kichungaji',
          subtitle: 'Ushauri & Maombi',
          imageAsset: 'assets/images/3d_calendar.png',
          accentColor: AppColors.primary,
          onTap: () {
            AppHaptics.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
            );
          },
        ),
      ][i],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    IconData? icon,
    String? imageAsset,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Icon plate is height-capped and clipped, so the 3D artwork can
          // never spill over the card edge.
          SizedBox(
            height: 52,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.contain,
              child: imageAsset != null
                  ? SizedBox(
                      width: 52,
                      height: 52,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Image.asset(imageAsset, fit: BoxFit.contain),
                      ),
                    )
                  : Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelLarge(
                    color: AppColors.textPrimaryOf(context)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(
                    color: AppColors.textMutedOf(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevotionalCard(DevotionalContent devotional) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      devotional.category,
                      style:
                          AppTypography.caption(color: AppColors.onPrimaryFixed)
                              .copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.offline_pin_rounded,
                            size: 13, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'BILA BANDO (OFFLINE)',
                          style: TextStyle(
                            color: Color(0xFF047857),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded,
                    size: 20, color: AppColors.primary),
                onPressed: () => _shareDevotional(devotional),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            devotional.title,
            style: AppTypography.headlineMedium(
                color: AppColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowOf(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${devotional.scriptureText}"',
                  style: AppTypography.scriptureVerse(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '— ${devotional.reference}',
                    style: AppTypography.labelLarge(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            devotional.reflection,
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.church_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  devotional.prayer,
                  style: AppTypography.bodyMedium(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (devotional.recommendedHymnNumber != null &&
              devotional.recommendedHymnTitle != null) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                AppHaptics.selectionClick();
                widget.onNavigateToTab(3); // Navigate to Biblia & Tenzi tab
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.music_note_rounded,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WIMBO WA TENZI WA SIKU (BILA BANDO):',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            'Tenzi #${devotional.recommendedHymnNumber}: ${devotional.recommendedHymnTitle}',
                            style: AppTypography.bodyMedium(
                              color: AppColors.textPrimary,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
