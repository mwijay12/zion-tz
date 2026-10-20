import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../models/church_announcement.dart';
import '../services/notifications_data_service.dart';
import '../../../core/services/church_sync_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationsDataService _service = NotificationsDataService();
  String _selectedBranch = 'Zote';

  static const List<String> _branches = [
    'Zote',
    'Mbagala Kwa Matope',
    'Kibondemaji',
    'Morogoro',
    'Bukoba',
    'Njombe',
    'Makambako',
    'Kisemvule',
    'Vikindu',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _shareAnnouncement(ChurchAnnouncement ann) {
    AppHaptics.lightImpact();
    final text = '''
*📢 TANGAZO LA SAYUNI — ZION JERUSALEM CHURCH*
Hekalu Kuu Mbagala Kwa Matope

*${ann.title}*
🗓️ Tarehe: ${ann.date}
⏰ Muda: ${ann.time}
📍 Mahali: ${ann.location}
👤 Kiongozi: ${ann.preacherOrLeader}

${ann.fullDetails}

Mawasiliano: ${ChurchProfile.pastoralHelpline}
Sayuni Jerusalem Church — Nuru ya Mataifa.
''';
    Share.share(text);
  }

  void _openAnnouncementDetails(ChurchAnnouncement ann) {
    AppHaptics.lightImpact();
    _service.markAsRead(ann.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.90,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                          color: AppColors.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ann.isHighPriority
                                ? const Color(0xFFDC2626).withValues(alpha: 0.15)
                                : AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ann.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ann.isHighPriority ? const Color(0xFFDC2626) : AppColors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ann.title,
                      style: AppTypography.headlineMedium(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 14),

                    // Event Details Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.calendar_today_rounded, 'Tarehe:', ann.date),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.access_time_rounded, 'Muda:', ann.time),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.place_rounded, 'Mahali:', ann.location),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.person_rounded, 'Kiongozi:', ann.preacherOrLeader),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Maelezo Kamili:',
                      style: AppTypography.titleSmall(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ann.fullDetails,
                      style: AppTypography.bodyLarge(color: AppColors.textSecondary).copyWith(height: 1.6),
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _shareAnnouncement(ann);
                            },
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('Shiriki Tangazo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.caption(color: AppColors.textMuted).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  void _callChurchOffice() async {
    AppHaptics.lightImpact();
    final uri = Uri.parse('tel:${ChurchProfile.pastoralHelpline.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = 180.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Arifa & Matangazo ya Kanisa',
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              AppHaptics.lightImpact();
              _service.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Matangazo yote yamewekwa yamesomwa.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
            label: const Text('Soma Yote', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Matangazo (${_service.filteredAnnouncements.length})', icon: const Icon(Icons.campaign_rounded, size: 18)),
            const Tab(text: 'Ratiba za Ibada', icon: Icon(Icons.schedule_rounded, size: 18)),
            const Tab(text: 'Ofisi & Mawasiliano', icon: Icon(Icons.contact_phone_rounded, size: 18)),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildAnnouncementsList(bottomInset),
              _buildServicesSchedule(bottomInset),
              _buildChurchHelplines(bottomInset),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementsList(double bottomInset) {
    final rawAnnouncements = _service.filteredAnnouncements;
    final announcements = rawAnnouncements.where((a) {
      if (_selectedBranch == 'Zote') return true;
      return a.branch == 'Zote' || a.branch == _selectedBranch;
    }).toList();

    return Column(
      children: [
        // 1. Live Sync Status Indicator (Calm, dignified, accessible)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: ValueListenableBuilder<String>(
            valueListenable: ChurchSyncService.syncStatusMessage,
            builder: (context, statusMsg, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: ChurchSyncService.isCloudConnected,
                builder: (context, isConnected, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isConnected
                            ? const Color(0xFF16A34A).withValues(alpha: 0.35)
                            : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                          size: 16,
                          color: isConnected ? const Color(0xFF16A34A) : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusMsg,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isConnected ? const Color(0xFF15803D) : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // 2. Branch Filter Pills
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _branches.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final b = _branches[i];
              final isSel = _selectedBranch == b;
              return InkWell(
                onTap: () {
                  AppHaptics.selectionClick();
                  setState(() => _selectedBranch = b);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSel ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      b == 'Zote' ? 'Matawi Yote' : b,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 6),

        // 3. Announcements List View
        Expanded(
          child: announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.campaign_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text(
                        'Hakuna matangazo ya ${_selectedBranch == "Zote" ? "sasa" : _selectedBranch}',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, bottomInset),
                  physics: const BouncingScrollPhysics(),
                  itemCount: announcements.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ann = announcements[index];

                    // Style variation: Bereavement vs Urgent vs Normal
                    Color borderColor;
                    Color badgeBgColor;
                    Color badgeTextColor;
                    String badgeLabel;

                    if (ann.isBereavement) {
                      borderColor = const Color(0xFF475569);
                      badgeBgColor = const Color(0xFF475569).withValues(alpha: 0.15);
                      badgeTextColor = const Color(0xFF334155);
                      badgeLabel = '🕊️ MSIBA / MAOMBOLEZO';
                    } else if (ann.isUrgent) {
                      borderColor = const Color(0xFFEA580C);
                      badgeBgColor = const Color(0xFFEA580C).withValues(alpha: 0.15);
                      badgeTextColor = const Color(0xFFEA580C);
                      badgeLabel = '⚡ DHARURA';
                    } else {
                      borderColor = !ann.isRead ? AppColors.primary : AppColors.border;
                      badgeBgColor = AppColors.surfaceContainer;
                      badgeTextColor = AppColors.primary;
                      badgeLabel = ann.category;
                    }

                    return AppCard(
                      onTap: () => _openAnnouncementDetails(ann),
                      padding: const EdgeInsets.all(16),
                      borderColor: borderColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeBgColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: badgeTextColor,
                                  ),
                                ),
                              ),
                              if (ann.branch != 'Zote') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border, width: 0.6),
                                  ),
                                  child: Text(
                                    '📍 ${ann.branch}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Row(
                                children: [
                                  Text(
                                    ann.date.split(',').first,
                                    style: AppTypography.caption(color: AppColors.textMuted),
                                  ),
                                  if (!ann.isRead) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDC2626),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ann.title,
                            style: AppTypography.titleMedium(color: AppColors.textPrimary).copyWith(
                              fontWeight: !ann.isRead ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ann.summary,
                            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    ann.time.split('-').first,
                                    style: AppTypography.caption(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share_rounded, size: 20, color: AppColors.primary),
                                    tooltip: 'Shiriki',
                                    onPressed: () => _shareAnnouncement(ann),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                                ],
                              ),
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

  Widget _buildServicesSchedule(double bottomInset) {
    const schedules = [
      {
        'day': 'Jumapili (Sunday)',
        'title': 'Ibada Kuu ya Ushindi & Sifa',
        'time': 'Saa 02:30 Asubuhi - 07:00 Mchana',
        'desc': 'Ibada Kuu ya Hekaluni, meza ya Bwana, sifa za kwaya na maombi ya uponyaji.',
        'icon': Icons.wb_sunny_rounded,
        'badge': 'Ibada Kuu',
      },
      {
        'day': 'Jumanne (Tuesday)',
        'title': 'Mazoezi ya Kwaya Kuu & Vijana',
        'time': 'Saa 10:30 Jioni - 12:30 Jioni',
        'desc': 'Mazoezi ya sauti na uimbaji wa nyimbo mpya za sifa.',
        'icon': Icons.music_note_rounded,
        'badge': 'Muziki',
      },
      {
        'day': 'Jumatano (Wednesday)',
        'title': 'Ibada ya Mafundisho ya Neno & Biblia',
        'time': 'Saa 10:00 Jioni - 12:00 Jioni',
        'desc': 'Kujifunza misingi ya imani, uinjilisti na uongozi wa kiroho.',
        'icon': Icons.menu_book_rounded,
        'badge': 'Mafundisho',
      },
      {
        'day': 'Alhamisi (Thursday)',
        'title': 'Umoja wa Wanawake (Wamama wa Sayuni)',
        'time': 'Saa 09:30 Alasiri - 11:30 Jioni',
        'desc': 'Maombi ya kina ya familia, kulea watoto na kusaidia wasiojiweza.',
        'icon': Icons.people_outline_rounded,
        'badge': 'Wamama',
      },
      {
        'day': 'Ijumaa (Friday)',
        'title': 'Jumuiya za Nyumbani & Maombi ya Vita',
        'time': 'Saa 10:00 Jioni - 11:30 Jioni',
        'desc': 'Ibada za mitaani na maombezi ya nyumba kwa nyumba.',
        'icon': Icons.home_work_rounded,
        'badge': 'Jumuiya',
      },
      {
        'day': 'Ijumaa ya Mwisho wa Mwezi',
        'title': 'Mkesha Mkuu wa Ukombozi (War Room Overnight)',
        'time': 'Saa 03:00 Usiku - Saa 12:00 Asubuhi',
        'desc': 'Kufunga, kuomba na kubomoa ngome za kiroho usiku mzima.',
        'icon': Icons.shield_moon_rounded,
        'badge': 'Mkesha',
      },
    ];

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
      physics: const BouncingScrollPhysics(),
      itemCount: schedules.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = schedules[index];

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['day'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.goldContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['badge'] as String,
                      style: AppTypography.caption(color: AppColors.onGoldContainer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item['title'] as String,
                style: AppTypography.titleMedium(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    item['time'] as String,
                    style: AppTypography.caption(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['desc'] as String,
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChurchHelplines(double bottomInset) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
      physics: const BouncingScrollPhysics(),
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ofisi ya Hekalu Kuu la Sayuni',
                style: AppTypography.titleMedium(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Mbagala Kwa Matope, Dar es Salaam, Tanzania.',
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.phone_rounded, color: AppColors.primary),
                ),
                title: const Text('Msaada wa Kichungaji (24/7 Helpline)'),
                subtitle: Text(ChurchProfile.pastoralHelpline),
                trailing: ElevatedButton(
                  onPressed: _callChurchOffice,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  child: const Text('Piga'),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.email_rounded, color: AppColors.primary),
                ),
                title: const Text('Barua Pepe ya Kanisa'),
                subtitle: Text(ChurchProfile.email),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
