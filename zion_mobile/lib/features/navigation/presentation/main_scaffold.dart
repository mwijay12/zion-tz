import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/church_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../home/presentation/home_screen.dart';
import '../../community/presentation/community_hub_screen.dart';
import '../../media/presentation/media_hub_screen.dart';
import '../../book/presentation/book_hub_screen.dart';
import '../../notifications/models/church_announcement.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../notifications/services/notifications_data_service.dart';
import 'liquid_glass_nav_bar.dart';
import 'persistent_mini_player.dart';
import 'quick_more_options_sheet.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  Timer? _bannerDismissTimer;

  @override
  void initState() {
    super.initState();
    ChurchSyncService.currentInAppNotice.addListener(_handleInAppNoticeChange);
  }

  @override
  void dispose() {
    ChurchSyncService.currentInAppNotice.removeListener(_handleInAppNoticeChange);
    _bannerDismissTimer?.cancel();
    super.dispose();
  }

  void _handleInAppNoticeChange() {
    _bannerDismissTimer?.cancel();
    if (ChurchSyncService.currentInAppNotice.value != null) {
      _bannerDismissTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) {
          ChurchSyncService.currentInAppNotice.value = null;
        }
      });
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      AppHaptics.selectionClick();
      setState(() => _currentIndex = index);
    }
  }

  void _showQuickMoreOptions() {
    AppHaptics.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickMoreOptionsSheet(
        onNavigateToTab: _onTabTapped,
      ),
    );
  }

  Future<void> _showExitConfirmationDialog() async {
    AppHaptics.lightImpact();
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.church_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kufunga App ya Sayuni?',
                style: AppTypography.titleMedium(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          'Je, una uhakika unataka kufunga application ya Zion Jerusalem Church?',
          style: AppTypography.bodySmall(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Baki Ndani',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ndio, Funga App'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  Widget _buildInAppNotificationBanner() {
    return ValueListenableBuilder<ChurchAnnouncement?>(
      valueListenable: ChurchSyncService.currentInAppNotice,
      builder: (context, notice, _) {
        if (notice == null) return const SizedBox.shrink();

        return Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 14,
          right: 14,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -50.0, end: 0.0),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            builder: (context, translateY, child) {
              return Transform.translate(
                offset: Offset(0, translateY),
                child: child,
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A2540), Color(0xFF082F70), Color(0xFF0D52CD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.gold, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Bell / Horn Icon with pulse styling
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.campaign_rounded,
                          color: AppColors.gold,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Notice Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TANGAZO JIPYA LA KATIBU',
                                  style: TextStyle(
                                    color: Color(0xFF0A2540),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                notice.category,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notice.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notice.summary.isNotEmpty ? notice.summary : notice.fullDetails,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Action: Fungua
                    ElevatedButton(
                      onPressed: () {
                        AppHaptics.mediumImpact();
                        ChurchSyncService.currentInAppNotice.value = null;
                        NotificationsDataService().markAsRead(notice.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF0A2540),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Fungua',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Close (X)
                    GestureDetector(
                      onTap: () {
                        AppHaptics.lightImpact();
                        ChurchSyncService.currentInAppNotice.value = null;
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateToTab: _onTabTapped),
      const CommunityHubScreen(),
      const MediaHubScreen(),
      const BookHubScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        _showExitConfirmationDialog();
      },
      child: Scaffold(
        extendBody: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            _buildInAppNotificationBanner(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PersistentMiniPlayer(),
              LiquidGlassNavBar(
                currentIndex: _currentIndex,
                onTabSelected: _onTabTapped,
                onMoreTapped: _showQuickMoreOptions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
