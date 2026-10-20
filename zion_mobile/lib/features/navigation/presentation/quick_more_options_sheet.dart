import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../branches/presentation/church_branches_screen.dart';
import '../../jumuiya/presentation/connect_card_screen.dart';
import '../../giving/presentation/giving_screen.dart';
import '../../prayer/presentation/prayer_war_room_screen.dart';
import '../../notes/presentation/notes_screen.dart';
import '../../growth/presentation/discipleship_growth_screen.dart';
import '../../pastoral/presentation/appointments_screen.dart';
import 'universal_search_sheet.dart';

class QuickMoreOptionsSheet extends StatelessWidget {
  final Function(int tabIndex) onNavigateToTab;

  const QuickMoreOptionsSheet({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = ChurchThemeService();
    final isDark = themeService.isDarkMode;

    final quickItems = [
      {
        'title': 'Tafuta Kila Kitu',
        'subtitle': 'Biblia, Tenzi, Waumini, Mahubiri',
        'icon': Icons.search_rounded,
        'color': AppColors.primary,
        'action': () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => UniversalSearchSheet(onNavigateToTab: onNavigateToTab),
          );
        },
      },
      {
        'title': 'Kadi ya Mgeni',
        'subtitle': 'Usajili na ukaribisho wa wageni',
        'icon': Icons.badge_rounded,
        'color': AppColors.gold,
        'action': () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectCardScreen()));
        },
      },
      {
        'title': 'Matawi ya Sayuni',
        'subtitle': 'Mbagala, Morogoro, Bukoba, Njombe...',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFF0284C7),
        'action': () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChurchBranchesScreen()));
        },
      },
      {
        'title': 'Sadaka & Michango',
        'subtitle': 'Lipa namba na akaunti za benki',
        'icon': Icons.volunteer_activism_rounded,
        'color': const Color(0xFF16A34A),
        'action': () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const GivingScreen()));
        },
      },
      {
        'title': 'Chumba cha Maombi',
        'subtitle': 'Mfungo wa siku 7 & maombi ya dharura',
        'icon': Icons.shield_rounded,
        'color': const Color(0xFFDC2626),
        'action': () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerWarRoomScreen()));
        },
      },
      {
        'title': 'Miadi na Askofu',
        'subtitle': 'Ushauri wa kichungaji na familia',
        'icon': Icons.calendar_month_rounded,
        'color': const Color(0xFF8B5CF6),
        'action': () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsScreen()));
        },
      },
      {
        'title': 'Daftari la Mahubiri',
        'subtitle': 'Kumbukumbu na madokezo ya kiroho',
        'icon': Icons.edit_note_rounded,
        'color': const Color(0xFFF59E0B),
        'action': () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
        },
      },
      {
        'title': 'Mti wa Uanafunzi',
        'subtitle': 'Hatua za makuzi ya kiroho',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF10B981),
        'action': () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscipleshipGrowthScreen()));
        },
      },
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: isDark ? 0.96 : 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle pill
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.grid_view_rounded,
                              color: AppColors.goldLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Huduma Zote za Sayuni',
                                style: AppTypography.titleMedium(color: AppColors.textPrimary),
                              ),
                              Text(
                                'Fikia vitu vyote muhimu bila kusumbuka',
                                style: AppTypography.caption(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2-Column Grid of Action Cards
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.55,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: quickItems.length,
                      itemBuilder: (context, index) {
                        final item = quickItems[index];
                        final color = item['color'] as Color;

                        return Material(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () {
                              AppHaptics.selectionClick();
                              (item['action'] as VoidCallback)();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.22),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          item['icon'] as IconData,
                                          color: color,
                                          size: 18,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 11,
                                        color: AppColors.textMuted.withValues(alpha: 0.6),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['title'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['subtitle'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Bottom Quick Links: Dark Mode Toggle & Office Call
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            AppHaptics.lightImpact();
                            final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                            themeService.setThemeMode(newMode);
                          },
                          icon: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: 16,
                            color: AppColors.gold,
                          ),
                          label: Text(
                            isDark ? 'Hali ya Mchana' : 'Hali ya Usiku',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
                            backgroundColor: AppColors.surfaceContainer,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            AppHaptics.lightImpact();
                            final cleanPhone = ChurchProfile.pastoralHelpline.replaceAll(' ', '');
                            final uri = Uri.parse('tel:$cleanPhone');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          icon: const Icon(Icons.support_agent_rounded, size: 16),
                          label: const Text(
                            'Wasiliana na Ofisi',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
