import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/module_decor.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final List<Map<String, dynamic>> _myAppointments = [
    {
      'id': '1',
      'pastor': 'Askofu Mercy Mgalla',
      'category': 'Ushauri wa Kiroho & Maombi',
      'date': '2026-09-12',
      'time': '10:30 Asubuhi',
      'status': 'Approved',
      'location': 'Ofisi Kuu ya Hekaluni, Mbagala',
    },
    {
      'id': '2',
      'pastor': 'Mchungaji Msaidizi Alex',
      'category': 'Ushauri wa Ndoa & Familia',
      'date': '2026-08-20',
      'time': '14:00 Mchana',
      'status': 'Completed',
      'location': 'Ofisi ya Kichungaji, Tawi la Arusha',
    },
  ];

  String _selectedPastor = 'Askofu Mercy Mgalla';
  String _selectedCategory = 'Ushauri wa Kiroho & Maombi';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _reasonController = TextEditingController();

  final List<String> _pastors = [
    'Askofu Mercy Mgalla',
    'Mchungaji Msaidizi Alex',
    'Mchungaji Peter Mabula (Mwanza)',
    'Mchungaji Grace Mwambene (Dodoma)',
  ];

  final List<String> _categories = [
    'Ushauri wa Kiroho & Maombi',
    'Ushauri wa Ndoa & Familia',
    'Kufunguliwa & Vita vya Kiroho',
    'Uongozi wa Biashara & Kazi',
    'Huduma ya Nyumbani / Wagonjwa',
  ];

  Future<void> _pickDate() async {
    AppHaptics.lightImpact();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    AppHaptics.lightImpact();
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _submitAppointment() {
    AppHaptics.mediumImpact();
    if (_selectedDate == null ||
        _selectedTime == null ||
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Tafadhali jaza tarehe, muda na maelezo mafupi ya miadi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final timeStr = _selectedTime!.format(context);

    setState(() {
      _myAppointments.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'pastor': _selectedPastor,
        'category': _selectedCategory,
        'date': dateStr,
        'time': timeStr,
        'status': 'Pending',
        'location': 'Ofisi Kuu ya Hekaluni / Tawi husika',
      });
      _reasonController.clear();
      _selectedDate = null;
      _selectedTime = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ombi la miadi limetumwa kwa uongozi wa kichungaji!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Miadi ya Kichungaji',
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ModuleBanner(
            eyebrow: 'Ushauri • Maombi • Ulinzi',
            title: 'Miadi ya Kichungaji',
            subtitle:
                'Omba muda wa kuonana na mchungaji kwa siri kamili ya kichungaji.',
            imageAsset: 'assets/images/3d_pastoral_meeting.png',
            gradient: const <Color>[Color(0xFF0E9E8F), Color(0xFF0A2540)],
            stats: <ModuleBannerStat>[
              ModuleBannerStat('${_myAppointments.length}', 'Maombi Yangu'),
              const ModuleBannerStat('24h', 'Majibu'),
              const ModuleBannerStat('Siri', '100%'),
            ],
          ),
          const SizedBox(height: 16),

          // Emergency Helpline Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.10),
                  AppColors.primaryLight.withOpacity(0.07),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.22)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.28)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.support_agent_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dharura ya Kiroho au Maombi?',
                            style: AppTypography.bodySmall(
                                    color: AppColors.textPrimary)
                                .copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ofisi ya kichungaji inapatikana Jumanne hadi Jumamosi saa 03:00 - 10:00 Jioni.',
                            style: AppTypography.caption(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      AppHaptics.mediumImpact();
                      final uri = Uri.parse('tel:${ChurchProfile.pastorPhone}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.phone_forwarded_rounded, size: 16),
                    label: const Text('Piga Simu Moja kwa Moja',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Booking Form
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ModuleSectionLabel(
                            label: 'Fomu ya Ombi',
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                    Container(
                      width: 46,
                      height: 42,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF7C3AED).withOpacity(0.28),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/3d_counsel.png',
                        fit: BoxFit.contain,
                        errorBuilder:
                            (BuildContext c, Object e, StackTrace? st) =>
                                const SizedBox(),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Omba Miadi Mpya na Mchungaji',
                  style: AppTypography.titleMedium(color: AppColors.textPrimary)
                      .copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),

                // Pastor selector
                Text('Mchungaji Unayetaka Kuonana Naye',
                    style:
                        AppTypography.caption(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _selectedPastor,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _pastors
                      .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPastor = val);
                  },
                ),

                const SizedBox(height: 12),

                // Category selector
                Text('Lengo Kuu la Miadi',
                    style:
                        AppTypography.caption(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),

                const SizedBox(height: 12),

                // Date & Time pickers
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon:
                            const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(
                          _selectedDate == null
                              ? 'Chagua Tarehe'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time_rounded, size: 16),
                        label: Text(
                          _selectedTime == null
                              ? 'Chagua Saa'
                              : _selectedTime!.format(context),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Notes / Description
                Text('Maelezo Mafupi (Siri ya Kichungaji)',
                    style:
                        AppTypography.caption(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Eleza kwa ufupi jambo unalotaka kuzungumza...',
                    hintStyle:
                        AppTypography.caption(color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Wasilisha Ombi la Miadi',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Submitted Appointments
          const ModuleSectionLabel(
            label: 'Historia ya Maombi',
            color: Color(0xFF7C3AED),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Maombi Yangu ya Miadi',
                  style: AppTypography.titleMedium(color: AppColors.textPrimary)
                      .copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_myAppointments.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._myAppointments.map((app) {
            final status = app['status'] as String;
            final isApproved = status == 'Approved';
            final isPending = status == 'Pending';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                borderColor: (isApproved
                        ? const Color(0xFF16A34A)
                        : isPending
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF0284C7))
                    .withOpacity(0.34),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          app['pastor'],
                          style: AppTypography.bodyMedium(
                                  color: AppColors.textPrimary)
                              .copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? const Color(0xFFDCFCE7)
                                : isPending
                                    ? const Color(0xFFEDE9FE)
                                    : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isApproved
                                ? 'IMEKUBALIWA'
                                : isPending
                                    ? 'INASUBIRI'
                                    : 'IMEKAMILIKA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isApproved
                                  ? const Color(0xFF15803D)
                                  : isPending
                                      ? const Color(0xFF6D28D9)
                                      : const Color(0xFF0369A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app['category'],
                      style: AppTypography.caption(color: AppColors.primary)
                          .copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.event_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${app['date']} saa ${app['time']}',
                            style: AppTypography.caption(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            app['location'],
                            style: AppTypography.caption(
                                color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
