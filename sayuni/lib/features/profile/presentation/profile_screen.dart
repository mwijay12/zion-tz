import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/services/church_auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/onboarding_auth_screen.dart';
import '../../giving/presentation/giving_screen.dart';
import '../../jumuiya/presentation/connect_card_screen.dart';
import 'church_admin_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ChurchAuthService _auth = ChurchAuthService();

  // Member Profile Fields
  String _name = 'Muumini wa Sayuni';
  String _phone = '+255 754 000 123';
  String _email = 'muumini@zionjerusalem.org';
  String _jumuiya = 'Mbagala Kijichi (Mt. Petro)';
  String _department = 'Kwaya ya Galilaya';
  String _memberId = 'ZJC-2026-8894';
  bool _isBaptized = true;

  // Settings State
  bool _sundayReminder = true;
  bool _morningPrayerAlert = true;
  bool _fastingReminder = true;
  String _preferredBible = 'SUV (Union Version)';
  double _speechRate = 1.0;
  int _downloadedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await _auth.init();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = _auth.name;
      _phone = _auth.phone;
      _email = _auth.email;
      _jumuiya = _auth.jumuiya;
      _department = _auth.department;
      _memberId = _auth.memberId;
      _isBaptized = _auth.isBaptized;

      _sundayReminder = prefs.getBool('setting_sunday_reminder') ?? true;
      _morningPrayerAlert = prefs.getBool('setting_morning_prayer') ?? true;
      _fastingReminder = prefs.getBool('setting_fasting_reminder') ?? true;
      _preferredBible = prefs.getString('setting_bible') ?? 'SUV (Union Version)';
      _speechRate = prefs.getDouble('setting_speech_rate') ?? 1.0;
      final offlineChapters = prefs.getStringList('offline_audio_chapters') ?? [];
      _downloadedCount = offlineChapters.length;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_phone', _phone);
    await prefs.setString('user_email', _email);
    await prefs.setString('user_jumuiya', _jumuiya);
    await prefs.setString('user_dept', _department);
    await prefs.setString('user_member_id', _memberId);
    await prefs.setBool('user_baptized', _isBaptized);

    await prefs.setBool('setting_sunday_reminder', _sundayReminder);
    await prefs.setBool('setting_morning_prayer', _morningPrayerAlert);
    await prefs.setBool('setting_fasting_reminder', _fastingReminder);
    await prefs.setString('setting_bible', _preferredBible);
    await prefs.setDouble('setting_speech_rate', _speechRate);
  }

  final FlutterTts _tts = FlutterTts();

  Future<void> _testSpeech() async {
    try {
      AppHaptics.mediumImpact();
      await _tts.stop();
      await _tts.setSpeechRate(_speechRate * 0.5);
      await _tts.setPitch(1.0);
      await _tts.speak('Bwana ndiye mchungaji wangu, sitapungukiwa na kitu. Neno la Sayuni.');
    } catch (_) {}
  }

  void _showEditProfileDialog() {
    AppHaptics.lightImpact();
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);
    final emailCtrl = TextEditingController(text: _email);
    final jumuiyaCtrl = TextEditingController(text: _jumuiya);
    final deptCtrl = TextEditingController(text: _department);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2540),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hariri Wasifu wa Ushirika',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputField('Jina Kamili', nameCtrl, Icons.person_rounded),
                  const SizedBox(height: 12),
                  _buildInputField('Namba ya Simu', phoneCtrl, Icons.phone_rounded),
                  const SizedBox(height: 12),
                  _buildInputField('Barua Pepe (Email)', emailCtrl, Icons.email_rounded),
                  const SizedBox(height: 12),
                  _buildInputField('Jumuiya ya Nyumbani', jumuiyaCtrl, Icons.groups_rounded),
                  const SizedBox(height: 12),
                  _buildInputField('Idara / Huduma', deptCtrl, Icons.volunteer_activism_rounded),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Ghairi', style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _name = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _name;
                              _phone = phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : _phone;
                              _email = emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : _email;
                              _jumuiya = jumuiyaCtrl.text.trim().isNotEmpty ? jumuiyaCtrl.text.trim() : _jumuiya;
                              _department = deptCtrl.text.trim().isNotEmpty ? deptCtrl.text.trim() : _department;
                            });
                            _auth.updateProfile(
                              name: _name,
                              phone: _phone,
                              email: _email,
                              jumuiya: _jumuiya,
                              department: _department,
                            );
                            _savePreferences();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Wasifu umehifadhiwa kikamilifu!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: const Color(0xFF0A2540),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Hifadhi',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F2644),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1.2),
      ),
      child: TextField(
        controller: ctrl,
        cursorColor: AppColors.gold,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF0F2644),
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.gold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(icon, color: AppColors.gold, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _clearOfflineCache() async {
    AppHaptics.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_audio_chapters');
    setState(() => _downloadedCount = 0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sura zote za nje ya mtandao zimefutwa kwenye simu.')),
      );
    }
  }

  void _openWhatsApp() async {
    AppHaptics.lightImpact();
    final uri = Uri.parse('https://wa.me/255754000111?text=Habari%20Ofisi%20ya%20Askofu%20Zion%20Jerusalem');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteAccountDialog() {
    AppHaptics.heavyImpact();
    final isDark = ChurchThemeService().isDarkMode;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161F30) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Futa Akaunti Kabisa?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hatua hii ni ya kudumu na haiwezi kurudishwa nyuma. Kwa mujibu wa Sheria ya Ulinzi wa Taarifa Binafsi ya Tanzania (PDPA 2022) na miongozo ya Google Play / App Store:',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeletionPoint('Taarifa zote za usajili wa muumini na Member ID zitafutwa.'),
                  const SizedBox(height: 4),
                  _buildDeletionPoint('Kumbukumbu za maombi binafsi na madokezo zitafutwa kwenye kifaa.'),
                  const SizedBox(height: 4),
                  _buildDeletionPoint('Utarudishwa mara moja kwenye hadhi ya Mgeni wa kawaida.'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Je, una uhakika unataka kufuta akaunti yako kabisa kwenye simu hii?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Ghairi (Baki)',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              AppHaptics.heavyImpact();
              await _auth.deleteAccount();
              await _loadPreferences();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Akaunti yako na taarifa zote zimefutwa kikamilifu.'),
                    backgroundColor: Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text('Futa Kabisa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletionPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), height: 1.3),
          ),
        ),
      ],
    );
  }

  void _handleLogout() async {
    AppHaptics.mediumImpact();
    await _auth.logout();
    await _loadPreferences();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Umetoka kwenye akaunti ya ushirika.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildThemeSettingsCard() {
    final themeService = ChurchThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        final isDark = themeService.isDarkMode;
        final primaryColor = themeService.primaryColor;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('MANDHARI — MWANGA AU GIZA'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dark Mode / Light Mode Selector
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hali ya Mwanga',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              isDark
                                  ? 'Giza (Dark Mode)'
                                  : 'Mwanga (Nyeupe) — maandishi yasomeka wazi',
                              style: AppTypography.caption(
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : AppColors.surfaceLowLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF26354A) : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildModeSegment(
                            label: 'Mwanga',
                            icon: Icons.light_mode_rounded,
                            selected: !isDark,
                            isDark: isDark,
                            primaryColor: primaryColor,
                            onTap: () {
                              AppHaptics.selectionClick();
                              themeService.setThemeMode(ThemeMode.light);
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildModeSegment(
                            label: 'Giza',
                            icon: Icons.dark_mode_rounded,
                            selected: isDark,
                            isDark: isDark,
                            primaryColor: primaryColor,
                            onTap: () {
                              AppHaptics.selectionClick();
                              themeService.setThemeMode(ThemeMode.dark);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: 15,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textMutedLight,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Mandhari moja tu: buluu na dhahabu. Maandishi, matafutaji, nyimbo na nyaraka husomeka wazi katika mwanga na katika giza.',
                          style: AppTypography.caption(
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
       },
     );
   }

  Widget _buildModeSegment({
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ChurchThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        final isDark = themeService.isDarkMode;
        final primaryColor = themeService.primaryColor;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Akaunti & Mipangilio ya Sayuni',
              style: AppTypography.titleMedium(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_rounded, color: primaryColor),
                tooltip: 'Hariri Wasifu',
                onPressed: _showEditProfileDialog,
              ),
            ],
          ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, 180 + MediaQuery.of(context).padding.bottom),
        children: [
          // 1. Digital Liturgical Member Card (Kadi ya Ushirika wa Sayuni)
          _buildDigitalMemberCard(),
          const SizedBox(height: 14),

          // Account Switcher Card (Muumini / Mgeni Mode)
          _buildAccountStatusCard(),
          const SizedBox(height: 16),

          // Heavenly Themes & Dark Mode Selector
          _buildThemeSettingsCard(),
          const SizedBox(height: 20),

          // 2. Profile Details Overview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('MAELEZO YA USHIRIKA'),
              TextButton.icon(
                onPressed: _showEditProfileDialog,
                icon: Icon(Icons.edit_rounded, size: 14, color: primaryColor),
                label: Text(
                  'Hariri Taarifa',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ),
            ],
          ),
          AppCard(
            child: Column(
              children: [
                _buildInfoRow(Icons.person_rounded, 'Jina Kamili', _name),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                _buildInfoRow(Icons.phone_rounded, 'Namba ya Simu', _phone),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                _buildInfoRow(Icons.email_rounded, 'Barua Pepe (Email)', _email),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                _buildInfoRow(Icons.groups_rounded, 'Jumuiya ya Nyumbani', _jumuiya),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                _buildInfoRow(Icons.volunteer_activism_rounded, 'Idara / Huduma', _department),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                _buildInfoRow(
                  Icons.verified_rounded,
                  'Hadhi ya Ubatizo',
                  _isBaptized ? 'Alibatizwa (Maji Mengi)' : 'Bado Hajabatizwa',
                  accentColor: const Color(0xFF16A34A),
                ),
                if (_auth.isAdmin) ...[
                  Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                  _buildInfoRow(
                    Icons.admin_panel_settings_rounded,
                    'Mamlaka ya Mfumo',
                    'Usimamizi Mkuu (Admin Root)',
                    accentColor: primaryColor,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Spiritual & Liturgical Settings (Biblia & Sauti)
          _buildSectionHeader('MIPANGILIO YA BIBLIA & SAUTI'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.menu_book_rounded, color: primaryColor, size: 20),
                  ),
                  title: Text(
                    'Tafsiri ya Biblia',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    _preferredBible,
                    style: AppTypography.caption(
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: DropdownButton<String>(
                    value: _preferredBible,
                    dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: 'SUV (Union Version)',
                        child: Text(
                          'SUV',
                          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'KJV (King James)',
                        child: Text(
                          'KJV',
                          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _preferredBible = val);
                        _savePreferences();
                      }
                    },
                  ),
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.speed_rounded, color: primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kasi ya Usomaji wa Sauti (TTS)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  _speechRate == 0.8
                                      ? 'Polepole (0.8x)'
                                      : _speechRate == 1.2
                                          ? 'Haraka (1.2x)'
                                          : _speechRate == 1.5
                                              ? 'Kasi Zaidi (1.5x)'
                                              : 'Kawaida (1.0x)',
                                  style: AppTypography.caption(
                                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _testSpeech,
                            icon: const Icon(Icons.volume_up_rounded, size: 16),
                            label: const Text('Jaribu Sauti'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [0.8, 1.0, 1.2, 1.5].map((rate) {
                          final isSelected = _speechRate == rate;
                          final label = rate == 0.8
                              ? '0.8x Polepole'
                              : rate == 1.0
                                  ? '1.0x Kawaida'
                                  : rate == 1.2
                                      ? '1.2x Haraka'
                                      : '1.5x Kasi';
                          return ChoiceChip(
                            label: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surfaceLowLight,
                            side: BorderSide(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark ? const Color(0xFF334155) : AppColors.borderLight),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                            ),
                            onSelected: (_) {
                              AppHaptics.selectionClick();
                              setState(() => _speechRate = rate);
                              _savePreferences();
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.offline_pin_rounded, color: AppColors.gold, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hifadhi ya Sura za Offline',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_downloadedCount Sura zimehifadhiwa',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_downloadedCount > 0)
                        InkWell(
                          onTap: _clearOfflineCache,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3)),
                            ),
                            child: const Text(
                              'Futa',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Hakuna',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF64748B) : AppColors.textMutedLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Notifications & Reminders
          _buildSectionHeader('ARIFA & UKUMBUSHO WA KIPANDE CHA SAYUNI'),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Ukumbusho wa Ibada ya Jumapili',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    'Hupokea arifa Saa 07:30 Asubuhi',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  value: _sundayReminder,
                  thumbColor: WidgetStatePropertyAll(primaryColor),
                  onChanged: (val) {
                    setState(() => _sundayReminder = val);
                    _savePreferences();
                  },
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                SwitchListTile(
                  title: Text(
                    'Saa ya Maombi ya Asubuhi',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    'Hupokea arifa Saa 12:00 Asubuhi (Kusoma Zaburi)',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  value: _morningPrayerAlert,
                  thumbColor: WidgetStatePropertyAll(primaryColor),
                  onChanged: (val) {
                    setState(() => _morningPrayerAlert = val);
                    _savePreferences();
                  },
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                SwitchListTile(
                  title: Text(
                    'Ukumbusho wa Mfungo wa Sayuni',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    'Taarifa ya maombi ya dharura na saa za kufungua',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  value: _fastingReminder,
                  thumbColor: WidgetStatePropertyAll(primaryColor),
                  onChanged: (val) {
                    setState(() => _fastingReminder = val);
                    _savePreferences();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. Quick Links: Giving & Visitor Card
          _buildSectionHeader('MICHANGO & USHIRIKA'),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  onTap: () {
                    AppHaptics.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GivingScreen()),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.gold, size: 26),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sadaka & Zaka',
                        style: AppTypography.titleSmall(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'M-Pesa, Tigo & Benki',
                        style: AppTypography.caption(
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  onTap: () {
                    AppHaptics.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ConnectCardScreen()),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.badge_rounded, color: primaryColor, size: 26),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Kadi ya Mgeni',
                        style: AppTypography.titleSmall(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Jiunge na Idara',
                        style: AppTypography.caption(
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Utawala wa Kanisa (Church Admin Portal)
          _buildSectionHeader('UTAWALA WA KANISA (CHURCH ADMIN)'),
          AppCard(
            borderColor: AppColors.gold.withOpacity(0.5),
            onTap: () {
              AppHaptics.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChurchAdminScreen()),
              );
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.admin_panel_settings_rounded, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Mfumo wa Utawala (Admin)',
                            style: AppTypography.titleSmall(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PORTAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.goldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hariri picha za viongozi, majina, na pakia mahubiri',
                        style: AppTypography.caption(
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF64748B) : AppColors.textMutedLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 6. About Church & Bishop Office
          _buildSectionHeader('KUHUSU KANISA LA SAYUNI'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.account_balance_rounded, color: primaryColor),
                  title: Text(
                    'Sayuni Jerusalem Church',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    'Makao Makuu: Mbagala Kwa Matope, Dar es Salaam',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                ListTile(
                  leading: const Icon(Icons.person_pin_rounded, color: AppColors.gold),
                  title: Text(
                    'Ofisi ya Askofu Mkuu',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    ChurchProfile.headBishop,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A)),
                    onPressed: _openWhatsApp,
                    tooltip: 'WhatsApp ya Kanisa',
                  ),
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.gold),
                  title: Text(
                    'Sera ya Faragha (Privacy Policy)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    'Sheria ya PDPA 2022 & Miongozo ya App Store',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => PrivacyPolicyScreen.show(context),
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? const Color(0xFF64748B) : AppColors.textMutedLight,
                  ),
                  title: Text(
                    'Toleo la Programu',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    'v1.0.0 (Sayuni Liturgical Edition)',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 7. Account Management & Permanent Deletion (Google Play & Apple Guidelines)
          _buildSectionHeader('USALAMA WA AKAUNTI & DATA (ACCOUNT MANAGEMENT)'),
          AppCard(
            borderColor: const Color(0xFFDC2626).withOpacity(0.35),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Toka Kwenye Akaunti',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    'Badili mtumiaji au ingia kama mgeni',
                    style: AppTypography.caption(
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: OutlinedButton(
                    onPressed: _handleLogout,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Ondoka', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                Divider(height: 1, color: isDark ? const Color(0xFF26354A) : AppColors.borderLight),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Futa Akaunti Kabisa (Delete Account)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  subtitle: Text(
                    'Futa taarifa zote za usajili kisheria (PDPA 2022)',
                    style: AppTypography.caption(
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: _showDeleteAccountDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Futa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  },
);
}

  Widget _buildSectionHeader(String title) {
    final primary = ChurchThemeService().primaryColor;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: primary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? accentColor}) {
    final isDark = ChurchThemeService().isDarkMode;
    final primary = ChurchThemeService().primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: (accentColor ?? primary).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accentColor ?? primary),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accentColor ?? (isDark ? Colors.white : AppColors.textPrimaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStatusCard() {
    final bool isAdmin = _auth.isAdmin;
    final bool isMember = _auth.isMember;
    final isDark = ChurchThemeService().isDarkMode;
    final primary = ChurchThemeService().primaryColor;

    final Color badgeColor = isAdmin
        ? primary
        : (isMember ? const Color(0xFF16A34A) : const Color(0xFFD97706));

    final IconData badgeIcon = isAdmin
        ? Icons.admin_panel_settings_rounded
        : (isMember ? Icons.verified_user_rounded : Icons.explore_rounded);

    final String title = _auth.roleBadge;
    final String subtitle = isAdmin
        ? 'Ufikiaji Kamili wa Utawala (Admin & Web Sync)'
        : (isMember
            ? 'Umeunganishwa na Ushirika wa Sayuni'
            : 'Unatumia mfumo kama Mgeni wa Heshima');

    final String buttonText = isAdmin ? 'Dashibodi ya Admin' : (isMember ? 'Badili' : 'Jiunge Rasmi');

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              AppHaptics.mediumImpact();
              if (isAdmin) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChurchAdminScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OnboardingAuthScreen(
                      onCompleted: () {
                        Navigator.pop(context);
                        _loadPreferences();
                      },
                    ),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: badgeColor,
              side: BorderSide(color: badgeColor),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalMemberCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _auth.isAdmin
              ? [const Color(0xFF0A2540), const Color(0xFF082F70), const Color(0xFF0D52CD)]
              : [const Color(0xFF0A2540), const Color(0xFF031B4E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _auth.isAdmin
              ? const Color(0xFF60A5FA).withOpacity(0.6)
              : AppColors.gold.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_auth.isAdmin ? AppColors.primary : const Color(0xFF0A2540)).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Church Header & Seal
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 1.2),
                ),
                child: const Icon(Icons.church_rounded, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KANISA LA SAYUNI YERUSALEMU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'KADI YA USHIRIKA WA SAYUNI',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: _auth.isAdmin
                      ? AppColors.primary.withOpacity(0.3)
                      : (_auth.isMember
                          ? const Color(0xFF16A34A).withOpacity(0.25)
                          : const Color(0xFFD97706).withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _auth.isAdmin
                        ? const Color(0xFF60A5FA)
                        : (_auth.isMember ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24)),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  _auth.isAdmin
                      ? 'MSIMAMIZI ⚡'
                      : (_auth.isMember ? 'MUUMINI 🛡️' : 'MGENI 🕊️'),
                  style: TextStyle(
                    color: _auth.isAdmin
                        ? const Color(0xFF93C5FD)
                        : (_auth.isMember ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A)),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Member Name & Details
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _auth.isAdmin
                        ? [const Color(0xFF38BDF8), const Color(0xFF0D52CD)]
                        : [const Color(0xFFFFD54F), const Color(0xFFC59B27)],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _name.trim().isNotEmpty
                        ? _name.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join()
                        : 'Z',
                    style: TextStyle(
                      color: _auth.isAdmin ? Colors.white : const Color(0xFF0A2540),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _department,
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _jumuiya,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ID Number & Chip Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ID: $_memberId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: _showEditProfileDialog,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_rounded, color: AppColors.goldLight, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Hariri',
                        style: TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
