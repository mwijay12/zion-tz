import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/top_notification.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/module_decor.dart';

class DiscipleshipGrowthScreen extends StatefulWidget {
  const DiscipleshipGrowthScreen({super.key});

  @override
  State<DiscipleshipGrowthScreen> createState() =>
      _DiscipleshipGrowthScreenState();
}

class _DiscipleshipGrowthScreenState extends State<DiscipleshipGrowthScreen> {
  final List<Map<String, dynamic>> _milestones = [
    {
      'id': 'salvation',
      'title': 'Wokovu (Kumpokea Kristo)',
      'scripture': 'Warumi 10:9-10',
      'description':
          'Kukiri kwa kinywa na kuamini moyoni kwamba Yesu Kristo ni Bwana na Mwokozi wako.',
      'icon': Icons.favorite_rounded,
      'isCompleted': true,
      'date': 'Mwanzo wa Safari',
    },
    {
      'id': 'baptism',
      'title': 'Ubatizo wa Maji Mengi',
      'scripture': 'Mathayo 28:19, Warumi 6:4',
      'description':
          'Kuzikwa pamoja na Kristo kwa njia ya ubatizo na kufufuliwa katika upya wa uzima.',
      'icon': Icons.water_drop_rounded,
      'isCompleted': false,
      'date': null,
    },
    {
      'id': 'foundation',
      'title': 'Darasa la Msingi la Imani',
      'scripture': 'Waebrania 6:1-2',
      'description':
          'Kuhitimu mafundisho ya wiki 4 ya misingi ya wokovu, maombi, neno na uongozi wa Roho.',
      'icon': Icons.menu_book_rounded,
      'isCompleted': false,
      'date': null,
    },
    {
      'id': 'jumuiya',
      'title': 'Kushiriki Jumuiya ya Nyumbani',
      'scripture': 'Matendo ya Mitume 2:46',
      'description':
          'Kuwa mshirika hai wa jumuiya ya maombi ya mtaa wako kwa ajili ya ushirika wa karibu.',
      'icon': Icons.groups_rounded,
      'isCompleted': false,
      'date': null,
    },
    {
      'id': 'service',
      'title': 'Utumishi & Huduma Hekaluni',
      'scripture': '1 Petro 4:10',
      'description':
          'Kutumia karama yako kutumikia kanisani (Kwaya, Ukaribisho/Ushers, Media, au Sunday School).',
      'icon': Icons.handshake_rounded,
      'isCompleted': false,
      'date': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMilestoneProgress();
  }

  Future<void> _loadMilestoneProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var milestone in _milestones) {
        final key = 'milestone_${milestone['id']}';
        if (prefs.containsKey(key)) {
          milestone['isCompleted'] = prefs.getBool(key) ?? false;
        }
      }
    });
  }

  Future<void> _toggleMilestone(int index) async {
    AppHaptics.mediumImpact();
    final milestone = _milestones[index];
    final newStatus = !(milestone['isCompleted'] as bool);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('milestone_${milestone['id']}', newStatus);

    setState(() {
      milestone['isCompleted'] = newStatus;
      milestone['date'] = newStatus ? 'Imekamilika' : null;
    });

    if (mounted) {
      AppTopAlert.show(
        context,
        title: newStatus ? 'Hatua Imekamilika!' : 'Hatua Imewekwa Upya',
        message: newStatus
            ? 'Hongera sana kwa hatua ya: ${milestone['title']}!'
            : 'Hatua imewekwa upya.',
        type: newStatus ? TopAlertType.success : TopAlertType.info,
      );
    }
  }

  void _showActionModal(String type) {
    AppHaptics.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          type == 'baptism'
              ? 'Kujiandikisha Ubatizo'
              : 'Kujiunga na Darasa la Msingi',
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
        content: Text(
          type == 'baptism'
              ? 'Je, unahitaji kubatizwa kwenye ibada ijayo ya ubatizo wa maji mengi? Timu ya kichungaji itawasiliana nawe kwa maandalizi.'
              : 'Darasa la Msingi linaanza Jumapili ijayo saa 07:30 Asubuhi. Bofya kuthibitisha ushiriki wako.',
          style: AppTypography.bodySmall(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Baadaye'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppTopAlert.show(
                context,
                title: 'Ombi Limepokelewa',
                message: type == 'baptism'
                    ? 'Ombi lako la Ubatizo wa Maji Mengi limepokelewa na jopo la wachungaji!'
                    : 'Ombi lako limepokelewa na Idara ya Uanafunzi!',
                type: TopAlertType.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thibitisha Ombi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount =
        _milestones.where((m) => m['isCompleted'] == true).length;
    final progress = completedCount / _milestones.length;

    return ListenableBuilder(
      listenable: ChurchThemeService(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.canvasOf(context),
          appBar: AppBar(
            title: Text(
              'Safari ya Ukuaji wa Kiroho',
              style: AppTypography.titleMedium(
                  color: AppColors.textPrimaryOf(context)),
            ),
            backgroundColor: AppColors.surfaceOf(context),
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ModuleBanner(
                eyebrow: 'Roadmap ya Uanafunzi',
                title: 'Safari ya Kiroho',
                subtitle:
                    'Fuatilia hatua zako za ukuaji kutoka Wokovu hadi Utumishi.',
                imageAsset: 'assets/images/3d_growth_steps.png',
                gradient: const <Color>[Color(0xFF16A34A), Color(0xFF0A2540)],
                stats: <ModuleBannerStat>[
                  ModuleBannerStat(
                      '$completedCount/${_milestones.length}', 'Hatua'),
                  const ModuleBannerStat('7', 'Vigawanyo'),
                  const ModuleBannerStat('Biblia', 'Msingi'),
                ],
              ),
              const SizedBox(height: 18),

              // Growth Ring Progress Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D52CD), Color(0xFF031B4E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A2540).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Circular Progress Indicator
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 76,
                          height: 76,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primaryLight),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MTI WA UANAFUNZI WA SAYUNI',
                            style: AppTypography.caption(
                                    color: AppColors.primaryLight)
                                .copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completedCount kati ya ${_milestones.length} Zimekamilika',
                            style:
                                AppTypography.titleMedium(color: Colors.white)
                                    .copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            progress == 1.0
                                ? 'Umekomaa na kuzaa matunda mengi kwa utukufu wa Mungu!'
                                : 'Endelea mbele katika kimo na maarifa ya Bwana wetu.',
                            style: AppTypography.caption(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick Registration Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showActionModal('baptism'),
                      icon: const Icon(Icons.water_drop_rounded, size: 16),
                      label: const Text('Jiunge Ubatizo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showActionModal('foundation'),
                      icon: const Icon(Icons.school_rounded, size: 16),
                      label: const Text('Darasa la Msingi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Timeline of Milestones
              const ModuleSectionLabel(
                label: 'Mti wa Uanafunzi',
                color: Color(0xFF16A34A),
              ),
              const SizedBox(height: 8),
              Text(
                'Hatua za Safari Yako',
                style: AppTypography.titleMedium(color: AppColors.textPrimary)
                    .copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),

              ...List.generate(_milestones.length, (idx) {
                final milestone = _milestones[idx];
                final isCompleted = milestone['isCompleted'] as bool;
                final isLast = idx == _milestones.length - 1;
                final stepColor = ModuleAccents.at(idx);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Node Column (Circle + Vertical line)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleMilestone(idx),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color:
                                  isCompleted ? stepColor : AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isCompleted ? stepColor : AppColors.border,
                                width: 2,
                              ),
                              boxShadow: [
                                if (isCompleted)
                                  BoxShadow(
                                    color: stepColor.withOpacity(0.32),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check_rounded
                                  : (milestone['icon'] as IconData),
                              size: 20,
                              color: isCompleted
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 70,
                            color: isCompleted
                                ? stepColor.withOpacity(0.45)
                                : AppColors.border,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Milestone Detail Card
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: AppCard(
                          borderColor: isCompleted
                              ? stepColor.withOpacity(0.38)
                              : AppColors.border,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      milestone['title'],
                                      style: AppTypography.bodyMedium(
                                              color: AppColors.textPrimary)
                                          .copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: isCompleted,
                                    thumbColor: WidgetStatePropertyAll(
                                        const Color(0xFF16A34A)),
                                    activeTrackColor: const Color(0xFF16A34A)
                                        .withOpacity(0.5),
                                    onChanged: (_) => _toggleMilestone(idx),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                milestone['scripture'],
                                style: AppTypography.caption(color: stepColor)
                                    .copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                milestone['description'],
                                style: AppTypography.caption(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
