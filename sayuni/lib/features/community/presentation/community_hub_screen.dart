import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../jumuiya/presentation/jumuiya_screen.dart';
import '../../prayer/presentation/prayer_war_room_screen.dart';
import '../../branches/presentation/church_branches_screen.dart';
import 'member_directory_screen.dart';
import '../../navigation/presentation/universal_search_sheet.dart';

class CommunityHubScreen extends StatefulWidget {
  final int initialSubTab;
  const CommunityHubScreen({super.key, this.initialSubTab = 0});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  late int _activeSubTab;
  bool _isHeaderCollapsed = false;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Vikundi', 'icon': Icons.groups_rounded, 'badge': 'Sayuni'},
    {'title': 'Jumuiya', 'icon': Icons.home_work_rounded, 'badge': 'Mitaa'},
    {
      'title': 'Ujuzi & Kazi',
      'icon': Icons.handshake_rounded,
      'badge': 'Biashara'
    },
    {'title': 'War Room', 'icon': Icons.shield_moon_rounded, 'badge': 'Maombi'},
  ];

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialSubTab.clamp(0, _tabs.length - 1);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      final pixels = notification.metrics.pixels;
      if (pixels <= 12 && _isHeaderCollapsed) {
        setState(() => _isHeaderCollapsed = false);
      } else if (delta > 4 && pixels > 20 && !_isHeaderCollapsed) {
        setState(() => _isHeaderCollapsed = true);
      } else if (delta < -5 && _isHeaderCollapsed) {
        setState(() => _isHeaderCollapsed = false);
      }
    }
    return false;
  }

  Widget _buildSubTabView() {
    switch (_activeSubTab) {
      case 0:
        return const JumuiyaScreen(
          key: ValueKey('subtab_vikundi'),
          isEmbedded: true,
          initialTabIndex: 0,
          showInternalTabSelector: false,
        );
      case 1:
        return const JumuiyaScreen(
          key: ValueKey('subtab_jumuiya'),
          isEmbedded: true,
          initialTabIndex: 1,
          showInternalTabSelector: false,
        );
      case 2:
        return const MemberDirectoryScreen(
          key: ValueKey('subtab_directory'),
          isEmbedded: true,
        );
      case 3:
        return const PrayerWarRoomScreen(
          key: ValueKey('subtab_warroom'),
          isEmbedded: true,
        );
      default:
        return const JumuiyaScreen(
          key: ValueKey('subtab_default'),
          isEmbedded: true,
          initialTabIndex: 0,
          showInternalTabSelector: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Smoothly Collapsible Header + Search Bar on Scroll (ClipRect ensures true 0px height collapse)
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                heightFactor: _isHeaderCollapsed ? 0.0 : 1.0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 190),
                  curve: Curves.easeOut,
                  opacity: _isHeaderCollapsed ? 0.0 : 1.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Liturgical Header Title + Direct Matawi Quick Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.diversity_3_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ushirika & Jamii',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Vikundi vya Kanisa, Jumuiya & Maombi',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Dedicated Matawi button (Quick access without crowding tabs)
                          InkWell(
                            onTap: () {
                              AppHaptics.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ChurchBranchesScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.account_balance_rounded,
                                      size: 14, color: AppColors.primary),
                                  SizedBox(width: 5),
                                  Text(
                                    'Matawi (8)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Integrated Search / Filter Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                      child: InkWell(
                        onTap: () {
                          AppHaptics.lightImpact();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const UniversalSearchSheet(),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Tafuta jumuiya, vikundi au waumini...',
                                  style: TextStyle(
                                      color: Color(0xFF64748B), fontSize: 12.5),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _tabs[_activeSubTab]['badge'] as String,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

            // Streamlined 4-Pill Tab Bar (Always accessible, extra compact when scrolled)
            AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.fromLTRB(
                  16, _isHeaderCollapsed ? 6 : 2, 16, 6),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(_tabs.length, (idx) {
                    final item = _tabs[idx];
                    final isSelected = _activeSubTab == idx;
                    return Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (_activeSubTab != idx) {
                              AppHaptics.selectionClick();
                              setState(() {
                                _activeSubTab = idx;
                                _isHeaderCollapsed = false;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item['title'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Content Area with Scroll Detection & Smooth SubTab Transition
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.025),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildSubTabView(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
