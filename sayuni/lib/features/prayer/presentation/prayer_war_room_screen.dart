import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/services/app_language_service.dart';
import '../../../core/services/church_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/top_notification.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/module_decor.dart';

class PrayerWarRoomScreen extends StatefulWidget {
  const PrayerWarRoomScreen({super.key});

  @override
  State<PrayerWarRoomScreen> createState() => _PrayerWarRoomScreenState();
}

class _PrayerWarRoomScreenState extends State<PrayerWarRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;

  // Fasting State
  final DateTime _fastEndDate =
      DateTime.now().add(const Duration(days: 7, hours: 14, minutes: 30));
  Duration _timeLeft = Duration.zero;
  bool _isParticipatingFast = false;
  int _fastParticipantsCount = 142;

  // War Room Prayer Requests
  final List<Map<String, dynamic>> _prayerRequests = [
    {
      'id': '1',
      'title': 'Uombezi wa Mkutano Mkuu wa Uamsho',
      'author': 'Askofu Mercy Mgalla',
      'urgency': 'Critical',
      'description':
          'Tunaomba ulinzi wa kiroho na kufunguliwa kwa maelfu ya roho kwenye mkutano ujao. Vita vya kiroho ni vikali lakini ushindi ni wa Bwana.',
      'date': 'Leo Saa 06:00',
      'intercessors': 89,
      'hasJoined': false,
    },
    {
      'id': '2',
      'title': 'Kuponywa kwa Ndugu Walioko Hospitalini',
      'author': 'Mwangalizi wa Maombi',
      'urgency': 'High',
      'description':
          'Tuwaombee washirika wetu watatu waliolazwa hospitali ya Muhimbili na Temeke. Mungu wa Sayuni awanyooshee mkono wa uponyaji sasa.',
      'date': 'Jana Saa 18:30',
      'intercessors': 64,
      'hasJoined': false,
    },
    {
      'id': '3',
      'title': 'Ujenzi wa Hekalu Jipya la Sayuni',
      'author': 'Kamati ya Maendeleo',
      'urgency': 'Normal',
      'description':
          'Mungu afungue milango ya fedha, vifaa na neema ya kukamilisha ujenzi bila vikwazo vyovyote vya kifedha.',
      'date': 'Juzi',
      'intercessors': 112,
      'hasJoined': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateTimeLeft();
    _loadFastingStatus();
    _loadInitialPrayers();

    ChurchSyncService.livePrayersNotifier.addListener(_onLivePrayersUpdated);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateTimeLeft();
    });
  }

  @override
  void dispose() {
    ChurchSyncService.livePrayersNotifier.removeListener(_onLivePrayersUpdated);
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPrayers() async {
    final saved = await ChurchSyncService().getSavedPrayerRequests();
    if (saved.isNotEmpty && mounted) {
      setState(() {
        final existingIds = _prayerRequests.map((p) => p['id']).toSet();
        for (final s in saved) {
          if (!existingIds.contains(s['id'])) {
            _prayerRequests.insert(0, s);
          }
        }
      });
    }
  }

  void _onLivePrayersUpdated() {
    final live = ChurchSyncService.livePrayersNotifier.value;
    if (live.isNotEmpty && mounted) {
      setState(() {
        final existingMap = {for (final p in _prayerRequests) p['id']: p};
        for (final item in live) {
          final id = item['id'];
          if (id != null) {
            existingMap[id] = item;
          }
        }
        _prayerRequests.clear();
        _prayerRequests.addAll(existingMap.values);
      });
    }
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final difference = _fastEndDate.difference(now);
    if (mounted) {
      setState(() {
        _timeLeft = difference.isNegative ? Duration.zero : difference;
      });
    }
  }

  Future<void> _loadFastingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isParticipatingFast = prefs.getBool('is_fasting_participant') ?? false;
        if (_isParticipatingFast) {
          _fastParticipantsCount += 1;
        }
      });
    }
  }

  Future<void> _toggleFastingParticipation() async {
    AppHaptics.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    final newStatus = !_isParticipatingFast;
    await prefs.setBool('is_fasting_participant', newStatus);

    setState(() {
      _isParticipatingFast = newStatus;
      _fastParticipantsCount += newStatus ? 1 : -1;
    });

    if (mounted) {
      AppTopAlert.show(
        context,
        title: newStatus ? 'Zion Fasting Active' : 'Fasting Updated',
        message: newStatus
            ? 'Umejiunga na Mfungo wa Sayuni! Bwana akutie nguvu.'
            : 'Umejiondoa kwenye orodha ya mfungo.',
        type: newStatus ? TopAlertType.success : TopAlertType.info,
      );
    }
  }

  void _toggleStandInGap(int index) {
    AppHaptics.lightImpact();
    final req = _prayerRequests[index];
    final reqId = req['id']?.toString() ?? '';
    setState(() {
      final current = req['hasJoined'] as bool;
      req['hasJoined'] = !current;
      req['intercessors'] = (req['intercessors'] as int) + (!current ? 1 : -1);
    });

    if (reqId.isNotEmpty) {
      ChurchSyncService().togglePrayerStandInGap(reqId);
    }

    AppTopAlert.show(
      context,
      title: 'Standing in the Gap',
      message: 'Umesimama kwenye pengo! Sala yako ina nguvu sana.',
      type: TopAlertType.success,
    );
  }

  void _showAddPrayerDialog() {
    AppHaptics.lightImpact();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String urgency = 'High';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Wasilisha Ombi la Maombi',
                        style: AppTypography.titleMedium(
                            color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Kichwa cha Ombi',
                      labelStyle: AppTypography.bodySmall(
                          color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: urgency,
                    decoration: InputDecoration(
                      labelText: 'Kiwango cha Uharaka',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Critical',
                          child: Text('Dharura Kubwa (Critical)')),
                      DropdownMenuItem(
                          value: 'High', child: Text('Muhimu (High)')),
                      DropdownMenuItem(
                          value: 'Normal', child: Text('Kawaida (Normal)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => urgency = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Maelezo ya Maombi',
                      labelStyle: AppTypography.bodySmall(
                          color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final desc = descController.text.trim();
                        if (title.isEmpty) return;

                        final newId =
                            'prayer-${DateTime.now().millisecondsSinceEpoch}';
                        final newPrayer = {
                          'id': newId,
                          'title': title,
                          'author': 'Muumini wa Sayuni',
                          'urgency': urgency,
                          'description': desc,
                          'date': 'Punde hivi',
                          'intercessors': 1,
                          'hasJoined': true,
                          'pastorInterceded': false,
                        };

                        setState(() {
                          _prayerRequests.insert(0, newPrayer);
                        });

                        Navigator.pop(ctx);

                        await ChurchSyncService().syncNewPrayerRequest(
                          id: newId,
                          title: title,
                          author: 'Muumini wa Sayuni',
                          urgency: urgency,
                          description: desc,
                        );

                        if (context.mounted) {
                          AppTopAlert.show(
                            context,
                            title: 'Prayer Request Submitted',
                            message:
                                'Ombi limewasilishwa kwenye Chumba cha Maombi na Mfumo wa Kanisa!',
                            type: TopAlertType.success,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tuma Ombi kwa Waombezi',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Chumba cha Maombi & Mfungo',
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(
                icon: Icon(Icons.timer_rounded, size: 20),
                text: 'Mfungo wa Sayuni'),
            Tab(
                icon: Icon(Icons.shield_rounded, size: 20),
                text: 'Maombi ya Dharura'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFastingTab(),
          _buildWarRoomTab(),
        ],
      ),
    );
  }

  Widget _buildFastingTab() {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      child: Column(
        children: [
          ModuleBanner(
            eyebrow: 'War Room • Mfungo • Maombi',
            title: 'Chumba cha Maombi',
            subtitle:
                'Simama pamoja na jamii katika vita vya kiroho masaa yote.',
            imageAsset: 'assets/images/3d_intercession.png',
            gradient: const <Color>[Color(0xFF7C3AED), Color(0xFF0A2540)],
            stats: const <ModuleBannerStat>[
              ModuleBannerStat('21', 'Siku za Mfungo'),
              ModuleBannerStat('24/7', 'Maombi'),
            ],
          ),
          const SizedBox(height: 18),

          // Hero Timer Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A2540), Color(0xFF031B4E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A2540).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: AppColors.primaryLight, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'MFUNGO WA SAYUNI 2026',
                      style:
                          AppTypography.caption(color: AppColors.primaryLight)
                              .copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Siku 21 za Kufungua Milango',
                  style:
                      AppTypography.titleMedium(color: Colors.white).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Countdown Timer Boxes
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimerUnit('$days', 'SIKU'),
                      _buildTimerSeparator(),
                      _buildTimerUnit('$hours', 'MASAA'),
                      _buildTimerSeparator(),
                      _buildTimerUnit('$minutes', 'DAKIKA'),
                      _buildTimerSeparator(),
                      _buildTimerUnit('$seconds', 'SEKUNDE'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  '"Je! mfungo niliouchagua si wa namna hii? Kufungua vifungo vya uovu, kuzilegeza kamba za nira..." — Isaya 58:6',
                  style: AppTypography.caption(color: Colors.white70).copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Participation Button
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.groups_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Washirika Walioko Kwenye Mfungo',
                            style: AppTypography.caption(
                                color: AppColors.textSecondary),
                          ),
                          Text(
                            '$_fastParticipantsCount Waumini Wamejiunga',
                            style: AppTypography.titleMedium(
                                    color: AppColors.textPrimary)
                                .copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _toggleFastingParticipation,
                    icon: Icon(
                      _isParticipatingFast
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _isParticipatingFast
                          ? 'Niko Kwenye Mfungo (Nimeshiriki)'
                          : 'Jiunge na Mfungo Huu',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isParticipatingFast
                          ? const Color(0xFF16A34A)
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Fasting Guidelines
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Miongozo ya Mfungo wa Sayuni',
                  style: AppTypography.titleMedium(color: AppColors.textPrimary)
                      .copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildGuidelineItem(
                  icon: Icons.water_drop_rounded,
                  title: 'Aina ya Mfungo',
                  description:
                      'Kuanzia Saa 00:00 Usiku hadi Saa 12:00 Jioni (Kunywa maji pekee kwa wenye afya nzuri).',
                ),
                _buildGuidelineItem(
                  icon: Icons.menu_book_rounded,
                  title: 'Usomaji wa Maandiko',
                  description:
                      'Kusoma sura 3 za Biblia kila siku (Asubuhi, Mchana, na Jioni).',
                ),
                _buildGuidelineItem(
                  icon: Icons.schedule_rounded,
                  title: 'Ibada ya Kufungua',
                  description:
                      'Kukusanyika Hekaluni au Jumuiyani kila siku saa 11:30 jioni kwa ajili ya maombi ya pamoja.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarRoomTab() {
    final langService = AppLanguageService();
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
          itemCount: _prayerRequests.length + 1,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, idx) {
            if (idx == 0) {
              return AppCard(
                backgroundColor: const Color(0xFF0A2540),
                borderColor: AppColors.primaryLight.withOpacity(0.55),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.22),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_in_talk_rounded,
                            color: AppColors.primaryLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Msaada wa Maombi ya Dharura',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Mch. Msaidizi Alex • ${ChurchProfile.assistantPastorPhone}',
                                style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Je, una uhitaji mkubwa, dharura ya kiafya, au unahitaji muujiza sasa hivi? Bonyeza kupiga simu moja kwa moja kuomba na mchungaji.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          AppHaptics.mediumImpact();
                          final uri = Uri.parse(
                              'tel:${ChurchProfile.assistantPastorPhone}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Piga Simu Moja kwa Moja'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: const Color(0xFF062A4E),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final reqIndex = idx - 1;
            final req = _prayerRequests[reqIndex];
            final urgency = req['urgency'] as String;
            final isCritical = urgency == 'Critical';
            final isHigh = urgency == 'High';
            final hasJoined = req['hasJoined'] as bool;

            return AppCard(
              borderColor: isCritical
                  ? Colors.redAccent.withOpacity(0.6)
                  : isHigh
                      ? Colors.orangeAccent.withOpacity(0.4)
                      : AppColors.border,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCritical
                                  ? Colors.redAccent.withOpacity(0.15)
                                  : isHigh
                                      ? Colors.orangeAccent.withOpacity(0.15)
                                      : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isCritical
                                  ? 'DHARURA KUBWA'
                                  : isHigh
                                      ? 'MUHIMU'
                                      : 'KAWAIDA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCritical
                                    ? Colors.redAccent
                                    : isHigh
                                        ? Colors.orange[800]
                                        : AppColors.primary,
                              ),
                            ),
                          ),
                          if (req['pastorInterceded'] == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF16A34A).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded,
                                      size: 10, color: Color(0xFF16A34A)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Askofu Ameombea',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        req['date'],
                        style: AppTypography.caption(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    req['title'],
                    style:
                        AppTypography.titleMedium(color: AppColors.textPrimary)
                            .copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kutoka kwa: ${req['author']}',
                    style: AppTypography.caption(color: AppColors.primaryDark)
                        .copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    req['description'],
                    style:
                        AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.shield_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${req['intercessors']} Wamesimama',
                                style: AppTypography.caption(
                                    color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _toggleStandInGap(reqIndex),
                        icon: Icon(
                          hasJoined
                              ? Icons.check_rounded
                              : Icons.volunteer_activism_rounded,
                          size: 14,
                        ),
                        label: Text(
                          hasJoined ? 'Nimesimama' : 'Ombea Hili',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: hasJoined
                              ? const Color(0xFF16A34A)
                              : AppColors.primary,
                          backgroundColor: hasJoined
                              ? const Color(0xFF16A34A).withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: _showAddPrayerDialog,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              langService.t(en: 'Submit Prayer', sw: 'Omba Maombi'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            value.padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSeparator() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall(color: AppColors.textPrimary)
                      .copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.caption(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
