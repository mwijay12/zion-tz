import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/services/app_language_service.dart';
import '../../../core/services/church_auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/top_notification.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/theme/app_typography.dart';

class OnboardingAuthScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingAuthScreen({super.key, this.onCompleted});

  @override
  State<OnboardingAuthScreen> createState() => _OnboardingAuthScreenState();
}

class _OnboardingAuthScreenState extends State<OnboardingAuthScreen> {
  final ChurchAuthService _authService = ChurchAuthService();
  final AppLanguageService _langService = AppLanguageService();

  final bool _isDemo = kDebugMode || const bool.fromEnvironment('DEMO_MODE', defaultValue: false);

  int _selectedMode = 0; // 0 = Member, 1 = Guest, 2 = Admin

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _adminEmailController = TextEditingController(text: 'admin@zionjerusalem.org');
  final TextEditingController _adminPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authService.init().then((_) {
      if (mounted) {
        if (_authService.name != 'Muumini wa Sayuni' &&
            _authService.name != 'Mgeni Karibu' &&
            _authService.name != 'Msimamizi Mkuu (Admin)') {
          _nameController.text = _authService.name;
        }
        if (_authService.phone != '+255 754 000 123') {
          _phoneController.text = _authService.phone;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  void _finishAuth() {
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScaffold()),
      );
    }
  }

  Future<void> _handleSubmit() async {
    // 1. Admin Login Mode
    if (_selectedMode == 2) {
      final email = _adminEmailController.text.trim();
      final password = _adminPasswordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        AppTopAlert.show(
          context,
          title: _langService.t(en: 'Missing Credentials', sw: 'Vitambulisho Vinakosekana'),
          message: _langService.t(
            en: 'Please enter Administrator Email and Password.',
            sw: 'Tafadhali weka barua pepe na nenosiri la Msimamizi.',
          ),
          type: TopAlertType.warning,
        );
        return;
      }

      setState(() => _isSubmitting = true);
      AppHaptics.mediumImpact();

      final success = await _authService.loginAsAdmin(
        emailOrUser: email,
        password: password,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        AppTopAlert.show(
          context,
          title: _langService.t(en: 'Admin Login Successful', sw: 'Umeingia kama Msimamizi'),
          message: _langService.t(
            en: 'Welcome, Church Administrator!',
            sw: 'Karibu Msimamizi Mkuu wa Sayuni!',
          ),
          type: TopAlertType.success,
        );
        _finishAuth();
      } else {
        AppTopAlert.show(
          context,
          title: _langService.t(en: 'Invalid Password', sw: 'Nenosiri Si Sahihi'),
          message: _langService.t(
            en: 'Check the administrator credentials and try again.',
            sw: 'Angalia vitambulisho vya msimamizi na ujaribu tena.',
          ),
          type: TopAlertType.error,
        );
      }
      return;
    }

    // 2. Member / Guest Mode (Strictly Name + Phone)
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      AppTopAlert.show(
        context,
        title: _langService.t(en: 'Name Required', sw: 'Jina Linahitajika'),
        message: _langService.t(
          en: 'Please enter your full name to proceed.',
          sw: 'Tafadhali weka jina lako kamili kuendelea.',
        ),
        type: TopAlertType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    AppHaptics.mediumImpact();

    if (_selectedMode == 0) {
      // Member login
      await _authService.loginAsMember(
        name: name,
        phone: phone.isNotEmpty ? phone : '+255 754 000 000',
        memberId: 'ZION-${name.hashCode.abs().toString().padLeft(6, '0').substring(0, 5)}',
        jumuiya: 'Mbagala Kijichi',
      );
    } else {
      // Guest login
      await _authService.loginAsGuest(
        name: name,
        phone: phone,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      AppTopAlert.show(
        context,
        title: _langService.t(
          en: _selectedMode == 0 ? 'Welcome, Church Member!' : 'Welcome, Honored Guest!',
          sw: _selectedMode == 0 ? 'Karibu Sayuni, Muumini!' : 'Karibu Sayuni, Mgeni!',
        ),
        message: '$name (${phone.isNotEmpty ? phone : "Sayuni Cathedral"})',
        type: TopAlertType.success,
      );
      _finishAuth();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    AppHaptics.mediumImpact();
    setState(() => _isSubmitting = true);

    // Quick selection dialog
    final chosenAccount = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_circle_rounded, color: Color(0xFF4285F4), size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _langService.t(en: 'Choose Google Account', sw: 'Chagua Akaunti ya Google'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF4285F4),
                child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: const Text('Muumini wa Sayuni', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              subtitle: const Text('muumini@zionjerusalem.org', style: TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(ctx, 'muumini@zionjerusalem.org'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(_langService.t(en: 'Cancel', sw: 'Ghairi')),
          ),
        ],
      ),
    );

    if (chosenAccount != null && chosenAccount.isNotEmpty) {
      final namePart = chosenAccount.split('@').first.replaceAll('.', ' ');
      await _authService.signInWithGoogle(
        googleEmail: chosenAccount,
        displayName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : namePart,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      AppTopAlert.show(
        context,
        title: _langService.t(en: 'Signed in with Google', sw: 'Umeingia na Google'),
        message: chosenAccount,
        type: TopAlertType.success,
      );
      _finishAuth();
    } else {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleSkip() async {
    AppHaptics.lightImpact();
    await _authService.loginAsGuest(name: 'Mgeni wa Sayuni');
    if (!mounted) return;
    AppTopAlert.show(
      context,
      title: _langService.t(en: 'Welcome as Guest', sw: 'Karibu kama Mgeni'),
      message: _langService.t(
        en: 'Exploring Sayuni Jerusalem Church',
        sw: 'Unagundua huduma za Hekalu la Sayuni',
      ),
      type: TopAlertType.info,
    );
    _finishAuth();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasColor = AppColors.canvasOf(context);
    final surfaceColor = AppColors.surfaceOf(context);
    final textColor = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return Scaffold(
      backgroundColor: canvasColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar with Language Toggle & App Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ZION APP v2.4',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // Language Switcher Toggle (EN / SW)
                  InkWell(
                    onTap: () {
                      AppHaptics.lightImpact();
                      _langService.toggleLanguage();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.gold, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language_rounded, size: 16, color: AppColors.gold),
                          const SizedBox(width: 6),
                          Text(
                            _langService.isEnglish ? 'English' : 'Kiswahili',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Church Logo - Increased Size for Prominence
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated Glow Background (Midnight Sanctuary Theme)
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.25),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // The Church Logo
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 4.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/zion_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Featuring Modern Spiritual Tools (3D Icons Preview)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _build3DIconBadge('assets/images/3d_bible.png', _langService.t(en: 'Bible', sw: 'Biblia')),
                    _build3DIconBadge('assets/images/3d_praying_hands.png', _langService.t(en: 'Prayer', sw: 'Maombi')),
                    _build3DIconBadge('assets/images/3d_offering.png', _langService.t(en: 'Offering', sw: 'Sadaka')),
                    _build3DIconBadge('assets/images/3d_roadmap.png', _langService.t(en: 'Journey', sw: 'Safari')),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Animated Welcome Title
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1400),
                builder: (context, value, child) {
                  return Opacity(opacity: value, child: child);
                },
                child: Column(
                  children: [
                    Text(
                      _langService.t(en: 'Welcome to Zion', sw: 'Karibu Hekalu la Sayuni'),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _langService.t(
                        en: 'Cathedral of Victory • Mbagala Kwa Matope',
                        sw: 'Hekalu Kuu la Ushindi • Mbagala Kwa Matope',
                      ),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mode Tabs: Member | Guest | Admin
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _buildRoleSegmentTab(
                      0,
                      _langService.t(en: 'Member', sw: 'Muumini'),
                      Icons.verified_user_rounded,
                    ),
                    _buildRoleSegmentTab(
                      1,
                      _langService.t(en: 'Guest', sw: 'Mgeni'),
                      Icons.person_add_rounded,
                    ),
                    _buildRoleSegmentTab(
                      2,
                      _langService.t(en: 'Admin', sw: 'Msimamizi'),
                      Icons.admin_panel_settings_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Form Container (Glassmorphism / Midnight Sanctuary)
              GlassCard(
                padding: const EdgeInsets.all(24),
                tintColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header label
                    Row(
                      children: [
                        Icon(
                          _selectedMode == 2
                              ? Icons.admin_panel_settings_rounded
                              : (_selectedMode == 0 ? Icons.shield_rounded : Icons.explore_rounded),
                          color: _selectedMode == 2 ? AppColors.primary : AppColors.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedMode == 2
                                ? _langService.t(en: 'Church Admin Portal', sw: 'Mamlaka ya Usimamizi')
                                : (_selectedMode == 0
                                    ? _langService.t(en: 'Registered Member Details', sw: 'Taarifa za Muumini Aliyesajiliwa')
                                    : _langService.t(en: 'Welcome, Honored Guest', sw: 'Karibu Hekaluni, Mgeni')),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_selectedMode == 2) ...[
                      _buildAuthField(
                        controller: _adminEmailController,
                        label: _langService.t(en: 'Admin Email', sw: 'Barua Pepe ya Msimamizi'),
                        hint: 'admin@zionjerusalem.org',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),

                      _buildAuthField(
                        controller: _adminPasswordController,
                        label: _langService.t(en: 'Admin Password', sw: 'Nenosiri la Msimamizi'),
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ] else ...[
                      // Member & Guest Inputs: STRICTLY Full Name + Phone Number
                      _buildAuthField(
                        controller: _nameController,
                        label: _langService.t(en: 'Full Name', sw: 'Jina Lako Kamili'),
                        hint: _langService.t(en: 'e.g. John Peter', sw: 'Mf. Yohana Petro'),
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 12),

                      _buildAuthField(
                        controller: _phoneController,
                        label: _langService.t(en: 'Phone Number / WhatsApp', sw: 'Namba ya Simu / WhatsApp'),
                        hint: '+255 7XX XXX XXX',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Primary Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedMode == 2 ? AppColors.primary : AppColors.gold,
                          foregroundColor: _selectedMode == 2 ? Colors.white : const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : Text(
                                _selectedMode == 2
                                    ? _langService.t(en: 'Sign in as Administrator', sw: 'Ingia kama Msimamizi')
                                    : (_selectedMode == 0
                                        ? _langService.t(en: 'Continue as Member', sw: 'Ingia kama Muumini')
                                        : _langService.t(en: 'Explore as Guest', sw: 'Gundua kama Mgeni')),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Divider OR
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            _langService.t(en: 'OR', sw: 'AU'),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted),
                          ),
                        ),
                        Expanded(child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sign in with Google Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _handleGoogleSignIn,
                        icon: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4285F4),
                          ),
                          alignment: Alignment.center,
                          child: const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                        label: Text(
                          _langService.t(en: 'Sign in with Google', sw: 'Ingia kwa Google'),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Skip Button
              TextButton(
                onPressed: _handleSkip,
                child: Text(
                  _langService.t(en: 'Skip for now • Continue as Guest', sw: 'Ruka kwa sasa • Endelea kama Mgeni'),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Easy Access for Leaders during testing
              if (_isDemo) _buildDemoSection(isDark),
              const SizedBox(height: 12),

              // Privacy Policy
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.shield_outlined, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Text(
                      _langService.t(
                        en: 'Your privacy is protected (PDPA 2022). ',
                        sw: 'Taarifa zako zinalindwa (PDPA 2022). ',
                      ),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    GestureDetector(
                      onTap: () => PrivacyPolicyScreen.show(context),
                      child: Text(
                        _langService.t(en: 'Privacy Policy', sw: 'Sera ya Faragha'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSegmentTab(int mode, String label, IconData icon) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppHaptics.selectionClick();
          setState(() => _selectedMode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
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
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textMutedOf(context),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondaryOf(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Container(
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        cursorColor: AppColors.primary,
        style: TextStyle(
          color: AppColors.textPrimaryOf(context),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: fieldBg,
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textMutedOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textMutedOf(context).withOpacity(0.6),
            fontSize: 12,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDemoSection(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(height: 1, width: 30, color: AppColors.gold.withOpacity(0.3)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                _langService.t(en: 'QUICK DEMO ACCESS', sw: 'INGIA HARAKA (MAJARIBIO)'),
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Container(height: 1, width: 30, color: AppColors.gold.withOpacity(0.3)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _buildLeaderButton('Askofu', 'pastor', Icons.account_balance_rounded, AppColors.primary),
            _buildLeaderButton('Katibu', 'secretary', Icons.description_rounded, Colors.blue),
            _buildLeaderButton('Hazina', 'treasurer', Icons.account_balance_wallet_rounded, Colors.teal),
            _buildLeaderButton(_langService.t(en: 'Member', sw: 'Muumini'), 'member', Icons.person_rounded, AppColors.gold),
          ],
        ),
      ],
    );
  }

  Widget _build3DIconBadge(String assetPath, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
            ),
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderButton(String label, String role, IconData icon, Color color) {
    return InkWell(
      onTap: _isSubmitting ? null : () async {
        setState(() => _isSubmitting = true);
        AppHaptics.heavyImpact();
        if (role == 'member') {
          await _authService.loginAsMember(
            name: 'Muumini wa Sayuni',
            phone: '+255 754 000 001',
            memberId: 'ZION-DEMO1',
            jumuiya: 'Mbagala Kijichi',
          );
        } else {
          await _authService.loginAsLeader(role);
        }
        if (mounted) {
          setState(() => _isSubmitting = false);
          _finishAuth();
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
