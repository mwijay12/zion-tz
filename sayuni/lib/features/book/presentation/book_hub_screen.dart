import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../bible/presentation/bible_screen.dart';
import '../../notes/presentation/notes_screen.dart';

class BookHubScreen extends StatefulWidget {
  final int initialSubTab;
  const BookHubScreen({super.key, this.initialSubTab = 0});

  @override
  State<BookHubScreen> createState() => _BookHubScreenState();
}

class _BookHubScreenState extends State<BookHubScreen> {
  late int _activeSubTab;
  bool _isHeaderCollapsed = false;
  double _lastScrollPixels = 0.0;

  final List<Map<String, dynamic>> _tabs = [
    {
      'title': 'Biblia',
      'icon': Icons.auto_stories_rounded,
      'badge': 'SUV & KJV',
    },
    {
      'title': 'Tenzi',
      'icon': Icons.queue_music_rounded,
      'badge': 'Nyimbo 161',
    },
    {
      'title': 'Madokezo',
      'icon': Icons.edit_note_rounded,
      'badge': 'Mahubiri',
    },
  ];

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialSubTab;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final pixels = notification.metrics.pixels;
    final delta = pixels - _lastScrollPixels;

    if (pixels > 40 && delta > 7 && !_isHeaderCollapsed) {
      setState(() => _isHeaderCollapsed = true);
    } else if ((delta < -7 || pixels <= 16) && _isHeaderCollapsed) {
      setState(() => _isHeaderCollapsed = false);
    }
    _lastScrollPixels = pixels;
    return false;
  }

  Widget _buildContent() {
    switch (_activeSubTab) {
      case 0:
        return const BibleScreen(
            key: ValueKey('book_tab_bible'), initialModuleIndex: 0);
      case 1:
        return const BibleScreen(
            key: ValueKey('book_tab_tenzi'), initialModuleIndex: 1);
      case 2:
        return const NotesScreen(key: ValueKey('book_tab_notes'));
      default:
        return const BibleScreen(
            key: ValueKey('book_tab_bible_default'), initialModuleIndex: 0);
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
            // Collapsible Liquid Glass Switcher Bar (Biblia, Tenzi, Madokezo)
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                heightFactor: _isHeaderCollapsed ? 0.0 : 1.0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 190),
                  opacity: _isHeaderCollapsed ? 0.0 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.16),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: List.generate(_tabs.length, (idx) {
                              final item = _tabs[idx];
                              final isSelected = _activeSubTab == idx;
                              return Expanded(
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
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 7),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected ? AppColors.primary : null,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          item['icon'] as IconData,
                                          size: 16,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          item['title'] as String,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main Content Area with scroll detection & fluid tab transition
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.02),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
