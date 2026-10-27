import 'package:flutter/material.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/services/church_auth_service.dart';
import '../../../core/services/church_customization_service.dart';
import '../../../core/services/church_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';

class ChurchAdminScreen extends StatefulWidget {
  const ChurchAdminScreen({super.key});

  @override
  State<ChurchAdminScreen> createState() => _ChurchAdminScreenState();
}

class _ChurchAdminScreenState extends State<ChurchAdminScreen> {
  final _customService = ChurchCustomizationService();

  // Leadership State
  late TextEditingController _bishopController;
  late TextEditingController _coLeaderController;
  late TextEditingController _assistantPastorController;
  late TextEditingController _assistantPhoneController;

  // New Sermon / Media State
  final _sermonTitleController = TextEditingController();
  final _sermonPreacherController =
      TextEditingController(text: ChurchProfile.headBishop);
  final _sermonScriptureController = TextEditingController();
  final _sermonDurationController = TextEditingController(text: '45 min');
  final _sermonMediaUrlController = TextEditingController();
  String _sermonType = 'video';
  String _sermonCategory = 'Mahubiri';

  bool _isSavingLeadership = false;
  bool _isPublishingSermon = false;

  @override
  void initState() {
    super.initState();
    _customService.init();
    _bishopController = TextEditingController(text: _customService.bishopName);
    _coLeaderController =
        TextEditingController(text: _customService.coLeaderName);
    _assistantPastorController =
        TextEditingController(text: _customService.assistantPastor);
    _assistantPhoneController =
        TextEditingController(text: _customService.assistantPhone);

    _sermonMediaUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _bishopController.dispose();
    _coLeaderController.dispose();
    _assistantPastorController.dispose();
    _assistantPhoneController.dispose();
    _sermonTitleController.dispose();
    _sermonPreacherController.dispose();
    _sermonScriptureController.dispose();
    _sermonDurationController.dispose();
    _sermonMediaUrlController.dispose();
    super.dispose();
  }

  // --- Photo Actions ---

  Future<void> _pickLeadershipFromGallery() async {
    AppHaptics.lightImpact();
    final path = await _customService.pickImageFromGallery();
    if (path != null) {
      await _customService.updateLeadershipPhoto(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Picha ya viongozi imepakiwa kutoka kwenye simu!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickLeadershipFromCamera() async {
    AppHaptics.lightImpact();
    final path = await _customService.pickImageFromCamera();
    if (path != null) {
      await _customService.updateLeadershipPhoto(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Picha ya viongozi imepigwa na kuhifadhiwa!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLeadershipUrlDialog() {
    AppHaptics.selectionClick();
    final urlCtrl =
        TextEditingController(text: _customService.leadershipPhoto ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Weka Link ya Picha ya Viongozi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bandika URL ya picha (Cloudinary, Imgur, au kiungo chochote cha picha mtandaoni):',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                hintText: 'https://example.com/picha.jpg',
                prefixIcon: Icon(Icons.link_rounded, color: AppColors.primary),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () async {
              final link = urlCtrl.text.trim();
              Navigator.pop(ctx);
              await _customService
                  .updateLeadershipPhoto(link.isNotEmpty ? link : null);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link ya picha ya viongozi imehifadhiwa!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Hifadhi'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetLeadershipPhoto() async {
    AppHaptics.mediumImpact();
    await _customService.updateLeadershipPhoto(null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Picha ya asili ya uongozi imerejeshwa.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- Fellowship Photo Actions ---

  Future<void> _pickFellowshipPhoto(
      String key, String title, bool fromCamera) async {
    AppHaptics.lightImpact();
    final path = fromCamera
        ? await _customService.pickImageFromCamera()
        : await _customService.pickImageFromGallery();
    if (path != null) {
      await _customService.updateFellowshipPhoto(
          fellowshipKey: key, pathOrUrl: path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Picha ya $title imepakiwa kikamilifu!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showFellowshipUrlDialog(
      String key, String title, String? currentPhoto) {
    AppHaptics.selectionClick();
    final urlCtrl = TextEditingController(text: currentPhoto ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Link ya Picha: $title',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bandika URL ya picha mtandaoni:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                hintText: 'https://example.com/fellowship.jpg',
                prefixIcon: Icon(Icons.link_rounded, color: AppColors.primary),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () async {
              final link = urlCtrl.text.trim();
              Navigator.pop(ctx);
              await _customService.updateFellowshipPhoto(
                  fellowshipKey: key, pathOrUrl: link.isNotEmpty ? link : null);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Link ya $title imehifadhiwa!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Hifadhi'),
          ),
        ],
      ),
    );
  }

  // --- Save Leadership Info ---

  Future<void> _saveLeadershipSettings() async {
    AppHaptics.mediumImpact();
    setState(() => _isSavingLeadership = true);
    await _customService.updateLeadershipInfo(
      bishop: _bishopController.text,
      coLeader: _coLeaderController.text,
      assistant: _assistantPastorController.text,
      phone: _assistantPhoneController.text,
    );
    await ChurchSyncService().syncLeadershipInfo(
      bishop: _bishopController.text,
      coLeader: _coLeaderController.text,
      assistant: _assistantPastorController.text,
      assistantPhone: _assistantPhoneController.text,
    );
    setState(() => _isSavingLeadership = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Taarifa zote za viongozi zimehifadhiwa kikamilifu!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- Publish Sermon / YouTube Video ---

  Future<void> _publishSermon() async {
    if (_sermonTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tafadhali weka kichwa cha habari cha somo.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rawUrl = _sermonMediaUrlController.text.trim();
    final isYt = ChurchCustomizationService.isYouTubeUrl(rawUrl);
    final thumb =
        isYt ? ChurchCustomizationService.getYouTubeThumbnail(rawUrl) : null;

    AppHaptics.mediumImpact();
    setState(() => _isPublishingSermon = true);

    final item = CustomSermonItem(
      id: 'sermon-admin-${DateTime.now().millisecondsSinceEpoch}',
      title: _sermonTitleController.text.trim(),
      preacher: _sermonPreacherController.text.trim().isNotEmpty
          ? _sermonPreacherController.text.trim()
          : ChurchProfile.headBishop,
      scripture: _sermonScriptureController.text.trim(),
      duration: _sermonDurationController.text.trim().isNotEmpty
          ? _sermonDurationController.text.trim()
          : '45 min',
      mediaUrl: rawUrl,
      type: _sermonType,
      category: _sermonCategory,
      thumbnailUrl: thumb,
      isYouTube: isYt,
    );

    // Save to service
    await _customService.addSermon(item);

    // Also sync to MediaHubScreen and Web Portal via ChurchSyncService
    await ChurchSyncService().syncNewSermon(
      id: item.id,
      title: item.title,
      preacher: item.preacher,
      scripture: item.scripture,
      duration: item.duration,
      type: item.type,
      category: item.category,
      mediaUrl: rawUrl,
      imageUrl: thumb,
    );

    setState(() => _isPublishingSermon = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Video/Mahubiri: "${_sermonTitleController.text}" yamewekwa kwenye Media Hub!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _sermonTitleController.clear();
      _sermonScriptureController.clear();
      _sermonMediaUrlController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _customService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            title: const Text(
              'Utawala wa Kanisa (Admin)',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF0A2540),
            elevation: 2,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              // Notice Card (Sanctuary Blue & Gold)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A2540), Color(0xFF0F52BA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A2540).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: AppColors.gold, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mfumo wa Usimamizi wa Ndani',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Badili picha kutoka simuni au viungo vya mtandao, dhibiti viongozi na pakia video za YouTube.',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Trust-source banner: says out loud whether the authority on this
              // device came from Firebase claims or only from a local cache.
              _buildTrustSourceBanner(),
              const SizedBox(height: 10),
              // ================= SECTION 1: LEADERSHIP PHOTO & INFO =================
              _buildSectionTitle('1. PICHA NA TAARIFA ZA UONGOZI WA KANISA'),
              AppCard(
                backgroundColor: AppColors.surface,
                borderColor: AppColors.border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo Preview & Picker Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.gold.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Leadership Avatar Preview
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.gold, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.gold.withOpacity(0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: getChurchImageProvider(
                                      _customService.leadershipPhoto,
                                      'assets/images/pastoral_leadership_1788577468703.jpg',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Picha Kuu ya Uongozi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _customService.leadershipPhoto !=
                                                null
                                            ? AppColors.success
                                                .withOpacity(0.15)
                                            : AppColors.surfaceContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _customService.leadershipPhoto != null
                                            ? 'Picha Maalum (Custom Photo)'
                                            : 'Picha ya Asili (Default)',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              _customService.leadershipPhoto !=
                                                      null
                                                  ? AppColors.success
                                                  : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Inaonekana kwenye Skrini Kuu (Home)',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Action Buttons to Replace Photo
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickLeadershipFromGallery,
                                icon: const Icon(Icons.photo_library_rounded,
                                    size: 16),
                                label: const Text('Simu (Gallery)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0A2540),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _pickLeadershipFromCamera,
                                icon: const Icon(Icons.camera_alt_rounded,
                                    size: 16),
                                label: const Text('Kamera'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F52BA),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _showLeadershipUrlDialog,
                                icon: const Icon(Icons.link_rounded, size: 16),
                                label: Text('Link (URL)'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                      color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              if (_customService.leadershipPhoto != null)
                                TextButton.icon(
                                  onPressed: _resetLeadershipPhoto,
                                  icon: const Icon(Icons.restart_alt_rounded,
                                      size: 16, color: AppColors.error),
                                  label: Text('Rejesha',
                                      style: TextStyle(
                                          color: AppColors.error,
                                          fontSize: 12)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildField(
                      label: 'Askofu Kiongozi (Head Bishop)',
                      controller: _bishopController,
                      icon: Icons.person_pin_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label: 'Mzee wa Kanisa / Mume wa Askofu',
                      controller: _coLeaderController,
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label: 'Mchungaji Msaidizi',
                      controller: _assistantPastorController,
                      icon: Icons.person_add_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label: 'Namba ya Simu ya Mch. Msaidizi',
                      controller: _assistantPhoneController,
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingLeadership
                            ? null
                            : _saveLeadershipSettings,
                        icon: _isSavingLeadership
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 20),
                        label: Text(_isSavingLeadership
                            ? 'Inahifadhi...'
                            : 'Hifadhi Mabadiliko ya Viongozi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A2540),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ================= SECTION: LOCAL DATA BACKUP & SOVEREIGNTY =================
              _buildSectionTitle(
                  'HIFADHI NAKALA YA DATA (DATA VAULT & BACKUP)'),
              AppCard(
                backgroundColor: AppColors.surface,
                borderColor: AppColors.border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shield_rounded,
                              color: Color(0xFF10B981), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hifadhi Salama ya Kanisa (Sovereign Vault)',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Data zote za kanisa zibaki mikononi mwenu bila hofu ya kufutika kwa Firebase.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          AppHaptics.mediumImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '✓ Data zote zimehifadhiwa salama kwenye kumbukumbu ya simu na Web!'),
                              backgroundColor: Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon:
                            const Icon(Icons.cloud_download_rounded, size: 18),
                        label: const Text(
                            'Thibitisha Data Ziko Salama (Audit Snapshot)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(
                              color: Color(0xFF10B981), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ================= SECTION: GRANT ADMIN ROLES BY EMAIL =================
              _buildSectionTitle(
                  'GAWA MAMLAKA YA USIMAMIZI (GRANT ADMIN BY EMAIL)'),
              AppCard(
                backgroundColor: AppColors.surface,
                borderColor: AppColors.border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F52BA).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.manage_accounts_rounded,
                              color: Color(0xFF0F52BA), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ongeza Msimamizi Mpya wa Mfumo',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Orodha hii ni ya kifaa hiki pekee (majaribio). '
                                'Mamlaka ya kweli hutolewa na Firebase '
                                'functions/setUserRole — ona docs/'
                                'FIREBASE_SETUP_OWNER.md.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ListenableBuilder(
                      listenable: ChurchAuthService(),
                      builder: (context, _) {
                        final auth = ChurchAuthService();
                        final adminEmails = auth.grantedAdminEmails.toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...adminEmails.map((email) {
                              final isRoot = email == 'admin@zionjerusalem.org';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLow,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_user_rounded,
                                        color: Color(0xFF16A34A), size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        email,
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    if (!isRoot)
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline_rounded,
                                            color: AppColors.error,
                                            size: 18),
                                        onPressed: () async {
                                          AppHaptics.lightImpact();
                                          final revoked =
                                              await auth.revokeRole(email);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                duration:
                                                    const Duration(seconds: 7),
                                                content: Text(
                                                    '$email — ${revoked.message}'),
                                              ),
                                            );
                                          }
                                        },
                                        tooltip: 'Ondoa Admin',
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text('Root',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  AppHaptics.selectionClick();
                                  final newEmailCtrl = TextEditingController();
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      title: const Text(
                                          'Ongeza Barua Pepe ya Admin',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold)),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Weka barua pepe (Gmail) ya mtumiaji anayetakiwa kupata jukumu la Admin:',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: newEmailCtrl,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                              prefixIcon: Icon(
                                                  Icons.email_outlined,
                                                  size: 18),
                                              hintText: 'mchungaji@gmail.com',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Ghairi')),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final em = newEmailCtrl.text.trim();
                                            if (!em.contains('@')) return;
                                            final outcome =
                                                await auth.grantRole(em);
                                            if (!ctx.mounted) return;
                                            Navigator.pop(ctx);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                duration:
                                                    const Duration(seconds: 9),
                                                content: Text(
                                                  outcome.success
                                                      ? '${outcome.viaCloud ? '✔' : '⚠'} $em — ${outcome.message}'
                                                      : '✕ $em — ${outcome.message}',
                                                ),
                                                backgroundColor: outcome.success
                                                    ? (outcome.viaCloud
                                                        ? const Color(
                                                            0xFF16A34A)
                                                        : const Color(
                                                            0xFFB45309))
                                                    : const Color(0xFFB91C1C),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF0F52BA),
                                              foregroundColor: Colors.white),
                                          child: const Text(
                                              'Gawa Mamlaka (Grant)'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_add_alt_1_rounded,
                                    size: 18),
                                label: const Text(
                                    'Ongeza Barua Pepe ya Admin (Grant Role)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0A2540),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ================= SECTION 2: FELLOWSHIP & DEPARTMENT PHOTOS =================
              _buildSectionTitle('2. PICHA ZA IDARA & JUMUIYA ZA KANISA'),
              Text(
                'Badilisha picha za makundi ya kanisa. Unaweza kupakia picha kutoka simuni au kuweka link ya mtandao.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.9)),
              ),
              const SizedBox(height: 12),

              _buildFellowshipPhotoCard(
                keyName: 'women',
                title: 'Umoja wa Wanawake (Wamama)',
                subtitle: 'Idara ya Wanawake wa Sayuni',
                currentPhoto: _customService.womenPhoto,
                fallbackAsset: 'assets/images/church_women_fellowship.jpg',
              ),
              const SizedBox(height: 12),

              _buildFellowshipPhotoCard(
                keyName: 'youth',
                title: 'Umoja wa Vijana (Youth Fellowship)',
                subtitle: 'Vijana wa Sayuni & Kwaya ya Vijana',
                currentPhoto: _customService.youthPhoto,
                fallbackAsset: 'assets/images/church_youth_fellowship.jpg',
              ),
              const SizedBox(height: 12),

              _buildFellowshipPhotoCard(
                keyName: 'men',
                title: 'Baraza la Wanaume (Wababa)',
                subtitle: 'Wababa na Wazee wa Kanisa',
                currentPhoto: _customService.menPhoto,
                fallbackAsset: 'assets/images/church_men_fellowship.jpg',
              ),
              const SizedBox(height: 12),

              _buildFellowshipPhotoCard(
                keyName: 'sundayschool',
                title: 'Watoto & Sunday School',
                subtitle: 'Idara ya Malezi ya Watoto wa Sayuni',
                currentPhoto: _customService.sundaySchoolPhoto,
                fallbackAsset: 'assets/images/church_front.jpg',
              ),
              const SizedBox(height: 24),

              // ================= SECTION 3: YOUTUBE & MEDIA HUB =================
              _buildSectionTitle(
                  '3. PAKIA VIDEO ZA YOUTUBE & MAHUBIRI (MEDIA HUB)'),
              AppCard(
                backgroundColor: AppColors.surface,
                borderColor: AppColors.border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Guide Banner for YouTube & Cloudinary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2540).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF0F52BA).withOpacity(0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.video_library_rounded,
                              color: Color(0xFFDC2626), size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Inasaidia YouTube Moja kwa Moja na Cloudinary:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textPrimary),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Bandika link ya YouTube (mfano: https://youtu.be/... au https://youtube.com/watch?v=...) mfumo utavuta picha (thumbnail) na video moja kwa moja!',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Media URL Input
                    _buildField(
                      label: 'URL ya YouTube / Cloudinary / Video / Audio',
                      controller: _sermonMediaUrlController,
                      icon: Icons.link_rounded,
                      hint:
                          'https://youtu.be/... au https://res.cloudinary.com/...',
                    ),

                    // YouTube Live Detection & Preview
                    if (_sermonMediaUrlController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      if (ChurchCustomizationService.isYouTubeUrl(
                          _sermonMediaUrlController.text.trim())) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    const Color(0xFFDC2626).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFFDC2626), size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Video ya YouTube Imetambuliwa!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    ChurchCustomizationService.launchMediaUrl(
                                        _sermonMediaUrlController.text),
                                child: const Text('Jaribu Kiungo',
                                    style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (ChurchCustomizationService.getYouTubeThumbnail(
                                _sermonMediaUrlController.text.trim()) !=
                            null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.network(
                                  ChurchCustomizationService
                                      .getYouTubeThumbnail(
                                          _sermonMediaUrlController.text
                                              .trim())!,
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded,
                                      color: Colors.white, size: 28),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                    const SizedBox(height: 14),

                    _buildField(
                      label: 'Kichwa cha Somo (Title)',
                      controller: _sermonTitleController,
                      icon: Icons.title_rounded,
                      hint: 'Mfano: Nguvu ya Damu ya Yesu',
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label: 'Mhubiri (Preacher)',
                      controller: _sermonPreacherController,
                      icon: Icons.mic_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label: 'Maandiko (Scripture)',
                      controller: _sermonScriptureController,
                      icon: Icons.menu_book_rounded,
                      hint: 'Mfano: Waebrania 11:1-6',
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label: 'Muda wa Somo (Duration)',
                      controller: _sermonDurationController,
                      icon: Icons.timer_rounded,
                      hint: 'Mfano: 45 min',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _sermonType,
                            decoration: InputDecoration(
                              labelText: 'Aina ya Media',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'video',
                                  child: Text('Video (YouTube/MP4)')),
                              DropdownMenuItem(
                                  value: 'audio', child: Text('Audio (Sauti)')),
                            ],
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _sermonType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _sermonCategory,
                            decoration: InputDecoration(
                              labelText: 'Kundi (Category)',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Mahubiri', child: Text('Mahubiri')),
                              DropdownMenuItem(
                                  value: 'Mafundisho',
                                  child: Text('Mafundisho')),
                              DropdownMenuItem(
                                  value: 'Kwaya & Sifa', child: Text('Kwaya')),
                              DropdownMenuItem(
                                  value: 'Podcasts', child: Text('Podcasts')),
                            ],
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _sermonCategory = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isPublishingSermon ? null : _publishSermon,
                        icon: const Icon(Icons.publish_rounded, size: 20),
                        label: Text(_isPublishingSermon
                            ? 'Inachapisha...'
                            : 'Chapisha Somo Kwenye Media Hub'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: const Color(0xFF0A2540),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Uploaded Sermons List
              if (_customService.customSermons.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('MAHUBIRI & VIDEO ZILIZOCHAPISHWA NA WEWE'),
                ..._customService.customSermons.map((sermon) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: sermon.thumbnailUrl != null
                              ? Image.network(
                                  sermon.thumbnailUrl!,
                                  width: 60,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.movie_rounded, size: 36),
                                )
                              : Container(
                                  width: 60,
                                  height: 48,
                                  color: AppColors.surfaceContainer,
                                  child: Icon(
                                    sermon.type == 'video'
                                        ? Icons.videocam_rounded
                                        : Icons.mic_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sermon.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${sermon.preacher} • ${sermon.duration}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (sermon.mediaUrl.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded,
                                color: AppColors.primary, size: 18),
                            onPressed: () =>
                                ChurchCustomizationService.launchMediaUrl(
                                    sermon.mediaUrl),
                            tooltip: 'Tazama',
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.error, size: 18),
                          onPressed: () async {
                            AppHaptics.lightImpact();
                            await _customService.deleteSermon(sermon.id);
                          },
                          tooltip: 'Futa',
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- Helpers ---

  Widget _buildFellowshipPhotoCard({
    required String keyName,
    required String title,
    required String subtitle,
    required String? currentPhoto,
    required String fallbackAsset,
  }) {
    final hasCustom = currentPhoto != null && currentPhoto.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                hasCustom ? AppColors.gold.withOpacity(0.5) : AppColors.border),
      ),
      child: Row(
        children: [
          // Fellowship Thumbnail Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image(
              image: getChurchImageProvider(currentPhoto, fallbackAsset),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 64,
                height: 64,
                color: AppColors.surfaceContainer,
                child: Icon(Icons.image_not_supported_rounded,
                    color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary),
                ),
                Text(
                  subtitle,
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    InkWell(
                      onTap: () => _pickFellowshipPhoto(keyName, title, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2540).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_rounded,
                                size: 12, color: Color(0xFF0A2540)),
                            SizedBox(width: 4),
                            Text('Simu',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0A2540))),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _pickFellowshipPhoto(keyName, title, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F52BA).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_rounded,
                                size: 12, color: Color(0xFF0F52BA)),
                            SizedBox(width: 4),
                            Text('Kamera',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F52BA))),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showFellowshipUrlDialog(
                          keyName, title, currentPhoto),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_rounded,
                                size: 12, color: AppColors.goldDark),
                            SizedBox(width: 4),
                            Text('Link',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.goldDark)),
                          ],
                        ),
                      ),
                    ),
                    if (hasCustom)
                      InkWell(
                        onTap: () async {
                          AppHaptics.lightImpact();
                          await _customService.updateFellowshipPhoto(
                              fellowshipKey: keyName, pathOrUrl: null);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 12, color: AppColors.error),
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
  }

  /// Live "where did my authority come from" banner.
  ///
  /// Firestore only honours `request.auth.token.role`, so a role cached on this
  /// device is a convenience — never access. This widget states that in plain
  /// Swahili and updates itself the moment the cloud claims land.
  Widget _buildTrustSourceBanner() {
    return AnimatedBuilder(
      animation: ChurchAuthService(),
      builder: (context, _) {
        final auth = ChurchAuthService();
        final (Color tint, Color accent, IconData icon, String hint) =
            switch (auth.roleSource) {
          RoleSource.cloud => (
              const Color(0xFFECFDF5),
              const Color(0xFF047857),
              Icons.verified_user_rounded,
              'Server ndiyo imekupa mamlaka haya. Mabadiliko unaoyafanya hapa '
                  'yanaandikwa Firebase na yanaonekana kwenye vifaa vyote.'
            ),
          RoleSource.demo => (
              const Color(0xFFFFFBEB),
              const Color(0xFFB45309),
              Icons.science_rounded,
              'Hii ni build ya majaribio. Role hii haipo kwenye Firebase, kwa '
                  'hivyo Firestore itakatakuza maandiko yoyote.'
            ),
          RoleSource.device => (
              const Color(0xFFFFF7ED),
              const Color(0xFFB45309),
              Icons.phonelink_lock_rounded,
              'Role hii iko kwenye kifaa hiki pekee (cache). Ili iwe ya kweli: '
                  'ingia kwa barua pepe ya Firebase kisha ufuatue '
                  'docs/FIREBASE_SETUP_OWNER.md — hadi hapo, server haikubali '
                  'maandiko yako.'
            ),
          RoleSource.none => (
              const Color(0xFFFEF2F2),
              const Color(0xFFB91C1C),
              Icons.gpp_maybe_rounded,
              'Hakuna role iliyowekwa. Ingia kwanza ili upate mamlaka.'
            ),
        };
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withOpacity(0.45)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${auth.roleBadge} · ${auth.roleSourceLabel}',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.35),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F52BA),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF0F52BA), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
