import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../models/jumuiya_model.dart';
import '../services/jumuiya_service.dart';
import '../../../core/services/church_customization_service.dart';

class JumuiyaScreen extends StatefulWidget {
  final bool isEmbedded;
  final int initialTabIndex;
  final bool showInternalTabSelector;
  const JumuiyaScreen({
    super.key,
    this.isEmbedded = false,
    this.initialTabIndex = 0,
    this.showInternalTabSelector = true,
  });

  @override
  State<JumuiyaScreen> createState() => _JumuiyaScreenState();
}

class _JumuiyaScreenState extends State<JumuiyaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final JumuiyaService _service = JumuiyaService();
  List<PrayerRequestItem> _prayers = [];
  bool _isLoadingPrayers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadPrayers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrayers() async {
    setState(() => _isLoadingPrayers = true);
    final data = await _service.getPrayerRequests();
    setState(() {
      _prayers = data;
      _isLoadingPrayers = false;
    });
  }

  void _callLeader(String phone) async {
    AppHaptics.lightImpact();
    final cleanPhone = phone.replaceAll(' ', '').replaceAll('-', '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Namba ya simu: $phone')),
        );
      }
    }
  }

  void _showSubmitPrayerDialog() {
    AppHaptics.lightImpact();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final detailsController = TextEditingController();
    String selectedCategory = 'Uponyaji';
    bool isConfidential = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.88,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                    top: 14,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Wasilisha Ombi la Maombi',
                              style: AppTypography.headlineMedium(color: AppColors.textPrimary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Jina Lako au la Mhitaji *',
                            hintText: 'Mf. Peter Mwita / Mgeni',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Namba ya Simu',
                            hintText: '+255...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: const InputDecoration(labelText: 'Kategoria ya Maombi'),
                          items: const [
                            DropdownMenuItem(value: 'Uponyaji', child: Text('Uponyaji & Afya')),
                            DropdownMenuItem(value: 'Familia', child: Text('Familia & Ndoa')),
                            DropdownMenuItem(value: 'Biashara', child: Text('Kazi, Ajira & Uchumi')),
                            DropdownMenuItem(value: 'Ukombozi', child: Text('Ukombozi & Vita vya Kiroho')),
                            DropdownMenuItem(value: 'Shukrani', child: Text('Shukrani kwa Mungu')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCategory = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: detailsController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Maelezo ya Maombi *',
                            hintText: 'Eleza hitaji lako kwa wachungaji na wazee wa maombi...',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Ombi la Siri (Wachungaji Pekee)'),
                          subtitle: const Text('Litaonekana kwa Askofu na Wazee bila kuwekwa hadharani'),
                          value: isConfidential,
                           thumbColor: WidgetStatePropertyAll(AppColors.primary),
                           onChanged: (val) {
                            setModalState(() => isConfidential = val);
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.trim().isEmpty ||
                                  detailsController.text.trim().isEmpty) {
                                return;
                              }
                              AppHaptics.mediumImpact();
                              final newPrayer = PrayerRequestItem(
                                id: 'prayer-${DateTime.now().millisecondsSinceEpoch}',
                                senderName: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                category: selectedCategory,
                                details: detailsController.text.trim(),
                                isConfidential: isConfidential,
                                date: DateTime.now(),
                              );
                              await _service.submitPrayerRequest(newPrayer);
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadPrayers();

                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Ombi lako la maombi limewasilishwa kwa wachungaji!'),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: const Text('Tuma Ombi la Maombi'),
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
      },
    );
  }

  Widget _buildTabSelector() {
    final tabs = [
      {'title': 'Vikundi vya Huduma', 'icon': Icons.supervised_user_circle_rounded},
      {'title': 'Jumuiya za Nyumbani', 'icon': Icons.home_work_rounded},
      {'title': 'Maombi Maalum', 'icon': Icons.favorite_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
        ),
        child: Row(
          children: List.generate(tabs.length, (idx) {
            final isSelected = _tabController.index == idx;
            final item = tabs[idx];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  _tabController.animateTo(idx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 6,
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
                        size: 15,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          item['title'] as String,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // With extendBody: false in main_scaffold, a clean 32-40px bottom padding is ideal
    final bottomInset = 36.0 + MediaQuery.of(context).padding.bottom;

    final content = Column(
      children: [
        if (widget.showInternalTabSelector) _buildTabSelector(),
        Expanded(
          child: widget.showInternalTabSelector
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMinistryGroupsList(bottomInset),
                    _buildCellsList(bottomInset),
                    _buildPrayersList(bottomInset),
                  ],
                )
              : (widget.initialTabIndex == 1
                  ? _buildCellsList(bottomInset)
                  : (widget.initialTabIndex == 2
                      ? _buildPrayersList(bottomInset)
                      : _buildMinistryGroupsList(bottomInset))),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Vikundi & Jumuiya za Sayuni',
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
      ),
      floatingActionButton: _tabController.index == 2
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: FloatingActionButton.extended(
                onPressed: _showSubmitPrayerDialog,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.favorite_rounded),
                label: const Text('Wasilisha Ombi'),
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: content,
      ),
    );
  }

  Widget _buildMinistryGroupsList(double bottomInset) {
    final groups = JumuiyaService.ministryGroups;
    final customService = ChurchCustomizationService();

    return ListenableBuilder(
      listenable: customService,
      builder: (context, _) {
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 6, 16, bottomInset),
          physics: const BouncingScrollPhysics(),
          itemCount: groups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final group = groups[index];
            String? customPhoto;
            if (group.id == 'group-youth') {
              customPhoto = customService.youthPhoto;
            } else if (group.id == 'group-women') {
              customPhoto = customService.womenPhoto;
            } else if (group.id == 'group-men') {
              customPhoto = customService.menPhoto;
            }

            return AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Photo Banner with Gradient Overlay & Badges
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image(
                          image: getChurchImageProvider(customPhoto, group.imagePath),
                          height: 155,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 140,
                            color: AppColors.surfaceContainer,
                            child: const Center(
                              child: Icon(Icons.groups_rounded, size: 48, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.65),
                            Colors.transparent,
                            Colors.black.withOpacity(0.75),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        group.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 13, color: AppColors.gold),
                          const SizedBox(width: 4),
                          Text(
                            'Wanachama ${group.membersCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Group Details & Leader Information
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.description,
                      style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Meeting Schedule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              group.meetingSchedule,
                              style: AppTypography.bodySmall(color: AppColors.textPrimary).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Activities Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: group.activities.map((act) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLow,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            act,
                            style: AppTypography.caption(color: AppColors.textMuted),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Leader & Phone Call Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.leaderTitle,
                                style: AppTypography.caption(color: AppColors.textMuted),
                              ),
                              Text(
                                group.leader,
                                style: AppTypography.labelLarge(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _callLeader(group.phone),
                          icon: const Icon(Icons.call_rounded, size: 16),
                          label: const Text('Piga Simu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainer,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  },
);
}

  Widget _buildCellsList(double bottomInset) {
    final cells = JumuiyaService.homeCells;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 6, 16, bottomInset),
      physics: const BouncingScrollPhysics(),
      itemCount: cells.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cell = cells[index];

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cell.name,
                      style: AppTypography.titleMedium(color: AppColors.textPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Waumini ${cell.membersCount}',
                      style: AppTypography.caption(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    cell.area,
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      '${cell.meetingDay} • ${cell.meetingTime}',
                      style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kiongozi wa Jumuiya',
                        style: AppTypography.caption(color: AppColors.textMuted),
                      ),
                      Text(
                        cell.leader,
                        style: AppTypography.labelLarge(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _callLeader(cell.phone),
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: const Text('Piga Simu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainer,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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

  Widget _buildPrayersList(double bottomInset) {
    if (_isLoadingPrayers) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Action Banner to submit prayer
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Una Hitaji la Maombi?',
                        style: AppTypography.labelLarge(color: AppColors.textPrimary),
                      ),
                      Text(
                        'Wachungaji & maombezi wapo tayari kuomba nawe.',
                        style: AppTypography.caption(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _showSubmitPrayerDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Wasilisha'),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _prayers.isEmpty
              ? EmptyStateView(
                  icon: Icons.favorite_rounded,
                  title: 'Hakuna Maombi Yaliyotumwa',
                  description: 'Bofya kitufe cha juu kutuma hitaji lako la maombi kwa wachungaji.',
                  actionLabel: 'Wasilisha Hitaji',
                  onAction: _showSubmitPrayerDialog,
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _prayers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final prayer = _prayers[index];

                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.goldContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  prayer.category,
                                  style: AppTypography.caption(color: AppColors.onGoldContainer),
                                ),
                              ),
                              Text(
                                AppFormatters.formatSwahiliDate(prayer.date),
                                style: AppTypography.caption(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            prayer.details,
                            style: AppTypography.bodyLarge(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_rounded, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Kutoka: ${prayer.senderName}',
                                style: AppTypography.caption(color: AppColors.textMuted),
                              ),
                              if (prayer.isConfidential) ...[
                                const SizedBox(width: 10),
                                const Icon(Icons.lock_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 2),
                                Text(
                                  'Siri',
                                  style: AppTypography.caption(color: AppColors.primary),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
