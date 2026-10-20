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

  Widget _buildContent() {
    switch (_activeSubTab) {
      case 0:
        return const BibleScreen(initialModuleIndex: 0);
      case 1:
        return const BibleScreen(initialModuleIndex: 1);
      case 2:
        return const NotesScreen();
      default:
        return const BibleScreen(initialModuleIndex: 0);
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
            // Liquid Glass Switcher Bar (Biblia, Tenzi, Madokezo)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
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
                                setState(() => _activeSubTab = idx);
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : null,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.35),
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
                                    size: 17,
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

            // Main Content Area
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }
}
