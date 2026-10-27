import 'package:flutter/material.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/services/pdpa_service.dart';

/// Dedicated Bilingual Privacy Policy Screen for Sayuni Jerusalem Church.
/// Complies with:
/// 1. Tanzania Personal Data Protection Act (PDPA 2022 / Sheria Na. 11 ya 2022).
/// 2. Google Play Developer Distribution Agreement & Apple App Store Review Guidelines.
/// 3. Zero-PIN Storage & Financial Security Standards for Tanzania Lipa Namba (M-Pesa, Tigo Pesa, Airtel Money, CRDB).
class PrivacyPolicyScreen extends StatefulWidget {
  final bool isModal;

  const PrivacyPolicyScreen({
    super.key,
    this.isModal = false,
  });

  /// Launch full-screen
  static void show(BuildContext context) {
    AppHaptics.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(isModal: false),
      ),
    );
  }

  /// Launch as a modal bottom sheet
  static void showModal(BuildContext context) {
    AppHaptics.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: const PrivacyPolicyScreen(isModal: true),
        ),
      ),
    );
  }

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _isSwahili = true;

  @override
  Widget build(BuildContext context) {
    final isDark = ChurchThemeService().isDarkMode;
    final primaryColor = ChurchThemeService().primaryColor;

    return Scaffold(
      backgroundColor: isDark ? AppColors.canvasDark : AppColors.canvasLight,
      appBar: AppBar(
        title: Text(
          _isSwahili
              ? 'Sera ya Faragha (PDPA 2022)'
              : 'Privacy Policy (PDPA 2022)',
          style: AppTypography.titleMedium(
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        leading: widget.isModal
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          // Language Switcher Chip (Kiswahili / English)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: Icon(
                Icons.language_rounded,
                size: 16,
                color: isDark ? Colors.white : primaryColor,
              ),
              label: Text(
                _isSwahili ? 'English' : 'Kiswahili',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryColor,
                ),
              ),
              backgroundColor: primaryColor.withOpacity(isDark ? 0.25 : 0.12),
              side: BorderSide(color: primaryColor.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onPressed: () {
                AppHaptics.selectionClick();
                setState(() => _isSwahili = !_isSwahili);
              },
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 40 + MediaQuery.of(context).padding.bottom),
        children: [
          // Header Badge & Compliance Banner
          _buildComplianceBanner(isDark, primaryColor),
          const SizedBox(height: 16),

          // Policy Sections
          if (_isSwahili)
            ..._buildSwahiliContent(isDark, primaryColor)
          else
            ..._buildEnglishContent(isDark, primaryColor),

          const SizedBox(height: 24),
          _buildDpoContactCard(isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildComplianceBanner(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF07192F),
            const Color(0xFF0A2540),
            primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: AppColors.goldLight, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSwahili
                          ? 'ULINZI WA TAARIFA BINAFSI'
                          : 'DATA PROTECTION COMPLIANCE',
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isSwahili
                          ? 'Sheria ya Ulinzi wa Taarifa Binafsi ya Tanzania (Sheria Na. 11 ya 2022)'
                          : 'Tanzania Personal Data Protection Act (PDPA No. 11 of 2022)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isSwahili
                ? 'Kanisa la Zion Jerusalem (Mbagala, Dar es Salaam) limejitolea kulinda faragha ya waumini na watumiaji wote kulingana na miongozo ya kisheria ya Tanzania na masoko ya programu ya Google Play na Apple App Store.'
                : 'Sayuni Jerusalem Church (Mbagala, Dar es Salaam) is fully committed to protecting the privacy of our members and visitors in compliance with Tanzanian Law and App Store guidelines.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSwahili
                ? 'Toleo 2026.2 • Oktoba 2026 • Linatumika mara moja'
                : 'Version 2026.2 • October 2026 • Effective immediately',
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the processor register that the PDPA service actually uses, so the
  /// privacy text can never drift away from the services the code contacts.
  String _processorsText(bool sw) {
    final b = StringBuffer();
    for (final p in PdpaService.dataInventory) {
      String v(String k) {
        final key = sw ? k : '${k}En';
        return (p[key] ?? p[k] ?? '').toString();
      }

      b.write('• ${v('who')}\n');
      b.write('    ${sw ? 'Anashikilia' : 'Holds'}: ${v('what')}\n');
      b.write('    ${sw ? 'Kwa nini' : 'Purpose'}: ${v('why')}\n');
      b.write('    ${sw ? 'Mahali' : 'Where'}: ${v('where')}\n');
    }
    return b.toString().trimRight();
  }

  List<Widget> _buildSwahiliContent(bool isDark, Color primaryColor) {
    return [
      _buildSection(
        icon: Icons.person_rounded,
        title: '1. Taarifa Tunazokusanya (Personal Information)',
        content:
            'Ili kutoa huduma za kichungaji, ushirika wa kidijitali na mawasiliano ya kanisa, tunaweza kukusanya:\n'
            '• Jina Kamili la Muumini au Mgeni.\n'
            '• Namba ya Simu ya Tanzania (+255) kwa ajili ya mawasiliano ya ushirika na arifa za ibada.\n'
            '• Barua Pepe (hiari) kwa ajili ya mawasiliano rasmi na akaunti ya msimamizi.\n'
            '• Jumuiya ya Nyumbani na Idara (k.m. Kwaya, Vijana, Wazee) ili kukuunganisha na huduma unayohudumu.\n'
            '• Hadhi ya Ubatizo na Nambari ya Utambulisho wa Muumini (Member ID).',
        isDark: isDark,
        primaryColor: primaryColor,
      ),
      _buildSection(
        icon: Icons.pin_drop_rounded,
        title: '2. Mahali & GPS (Location Data)',
        content:
            '• Tunatumia eneo lako pekee pale unapotafuta maelekezo ya kufika kwenye tawi la kanisa (k.m. Kwa Matope Mbagala, Kijichi, au matawi mengine ya Sayuni).\n'
            '• Hatufuatilii wala kurekodi mienendo yako ya kila siku (No continuous background GPS tracking).\n'
            '• Ruhusa ya eneo ni ya hiari na unaweza kuizima wakati wowote kupitia mipangilio ya simu yako.',
        isDark: isDark,
        primaryColor: primaryColor,
      ),
      _buildSection(
        icon: Icons.mic_none_rounded,
        title: '3. Sauti & Maikrofoni (Audio & Voice Processing)',
        content:
            '• Programu inajumuisha usomaji wa Biblia na maombi kwa sauti (Text-to-Speech / TTS).\n'
            '• Mchakato wote wa sauti unafanyika ndani ya simu yako (on-device processing).\n'
            '• Haturekodi sauti za faragha za muumini, na hakuna maongezi au maombi yanayotumwa kwenye seva zetu.',
        isDark: isDark,
        primaryColor: primaryColor,
      ),
      _buildSection(
        icon: Icons.account_balance_wallet_rounded,
        title: '4. Taarifa za Fedha & Lipa Namba (Zero PIN Storage)',
        content:
            '• Utoaji wa Sadaka, Zaka, na Michango ya Ujenzi unafanyika kwa kutumia namba rasmi za Lipa Namba za Kanisa (M-Pesa 5524101, Tigo Pesa 8919293, Airtel Money 3310022, au CRDB Bank).\n'
            '• USALAMA MKUU: Hatukusanyi, hatuombi, na HATUHIFADHI kamwe namba ya siri (PIN), namba ya kadi ya benki wala taarifa za siri za kifedha.\n'
            '• Malipo yote yanakamilishwa kupitia mifumo rasmi ya simu (USSD) au programu za simu za benki za mtoa huduma wako.',
        isDark: isDark,
        primaryColor: primaryColor,
        isHighlight: true,
      ),
      _buildSection(
        icon: Icons.security_rounded,
        title: '5. Miundombinu ya Seva & Usalama (Security & Infrastructure)',
        content:
            '• Taarifa za kanisa zinalindwa kwa njia fiche ya kiwango cha juu (TLS/HTTPS Encryption).\n'
            '• Kuingia na kuthibitisha mtu: Google Firebase Authentication. Hifadhi ya data: Cloud Firestore.\n'
            '• Ufikiaji wa data unadhibitiwa na kanuni za `firestore.rules` zilizoandikwa wazi: kila cheo (Msimamizi, Mchungaji, Katibu, Shemasha, Kiongozi) kinaona na kubadilisha kile tu ambacho kinahitaji kwa huduma yake; uundaji wa majukumu hauwezi kufanyika na programu mwenyewe.\n'
            '• Nyenzo nzito (sauti za mahubiri, video na picha) huhifadhiwa kwenye Cloudinary; orodha ya vituo vya redio hutoka radio-browser.info (orodha pekee — hakuna taarifa yako inayohusika).\n'
            '• Muhtasari wa mahubiri unaotengenezwa na Google Gemini unatumika kwenye portal ya wasimamizi tu, si kwenye simu yako.\n'
            '• Kumbukumbu za nje ya mtandao (maandishi ya mahubiri, sura zilizohifadhiwa, alama za kusoma) huhifadhiwa ndani ya simu yako pekee.',
        isDark: isDark,
        primaryColor: primaryColor,
      ),
      _buildSection(
        icon: Icons.delete_forever_rounded,
        title: '6. Haki Zako Chini ya PDPA 2022 (Access, Withdrawal, Erasure)',
        content:
            'Chini ya Sheria ya Ulinzi wa Taarifa Binafsi (PDPA 2022) na Miongozo ya Google Play / Apple App Store:\n'
            '• Kila matumizi ya taarifa zako yana msingi wa kisheria unaodhibitishwa na rekodi ya idhini. Unapobadilisha maazimo, rekodi mpya huongezwa — rekodi za zamani hazirekebishwi ili kanisa liweze kuonyesha ulichokubaliwa kwa tarehe fulani.\n'
            '• Haki ya KUFIKIA data yako: Wasifu → "Haki zangu za PDPA" → "Tengeneza nakala" ili kupata JSON kamili ya kile kilichohifadhiwa kwenye kifaa hiki na, ikiwa Firebase iko, kile kilicho kwenye wingu.\n'
            '• Haki ya KUONDOA IDHINI: unaweza kuondoa matumizi yasiyo ya lazima wakati wowote; matumizi ya uanachama na ya fedha hubaki kwa sababu yake ya kisheria.\n'
            '• Haki ya KUFUTA: "Futa akaunti" hufuta akaunti yako ya Firebase pamoja na rekodi zako za utambulisho na maombi — kwenye wingu na kwenye kifaa hiki.\n'
            '• HAKIFUTWI: rekodi za fedha (aseli, michango, mapato na matumizi) — sheria ya mapato na ukaguzi wa kanisa lazimu zihifadhiwe; pia nakala za dharura (backups) za wingu zinaweza kuchukua muda kabla ya kupita.\n'
            '• Maombi ya haki hizi hushughulikiwa ndani ya siku 30. Wasiliana privacy@zionjerusalem.org.',
        isDark: isDark,
        primaryColor: primaryColor,
        isHighlight: true,
      ),
      _buildSection(
        icon: Icons.share_rounded,
        title: '7. Washirika wa Data — Nani Anayeshikilia Taarifa Zako',
        content:
            'Kanisa ndilo mmiliki wa taarifa hizi (data controller). Wahudumiaji ambao taarifa zinapita kwao ni hawa:\n'
            '${_processorsText(true)}\n'
            '• Hakuna taarifa yako inayouzwa au inayopewa mtu yeyote kwa masoko ya biashara.',
        isDark: isDark,
        primaryColor: primaryColor,
      ),
    ];
  }

  List<Widget> _buildEnglishContent(bool isDark, Color primaryColor) {
    return [
      _buildSection(
        icon: Icons.person_rounded,
        title: '1. Information We Collect',
        content:
            'To provide spiritual ministry, digital church fellowship, and community communications, we may collect:\n'
            '• Full Name of member or visitor.\n'
            '• Tanzanian Phone Number (+255) for fellowship updates and church reminders.\n'
            '• Email Address (optional) for formal communication and administrative access.\n'
            '• Home Cell (Jumuiya) and Church Department (Choir, Youth, Elders) to connect you to your ministry.\n'
            '• Baptism status and Church Member ID.',
        isDark: isDark,
        primaryColor: primaryColor,
      ),
      _buildSection(
        icon: Icons.pin_drop_rounded,
        title: '2. Location & GPS Disclosures',
        content:
            '• We use location access solely to provide turn-by-turn navigation to church branches (Kwa Matope Mbagala, Kijichi, etc.).\n'
            '• We NEVER conduct continuous background GPS tracking or movement monitoring.\n'
            '• Location permission is completely optional and can be revoked at any time via device settings.',
        isDark: isDark,
        primaryColor: primaryColor,
      ),
      _buildSection(
        icon: Icons.mic_none_rounded,
        title: '3. Voice & Audio Processing',
        content:
            '• The app provides Text-to-Speech (TTS) scripture reading and audio devotionals.\n'
            '• All speech synthesis runs locally on your device (on-device processing).\n'
            '• We do not record your microphone, voice, or private prayers, nor transmit audio to remote servers.',
        isDark: isDark,
        primaryColor: primaryColor,
      ),
      _buildSection(
        icon: Icons.account_balance_wallet_rounded,
        title: '4. Giving, Tithes & Zero PIN Storage',
        content:
            '• Tithes, offerings, and building donations are made using official Church Lipa Namba channels (M-Pesa 5524101, Tigo Pesa 8919293, Airtel Money 3310022, CRDB Bank).\n'
            '• ZERO PIN STORAGE: We NEVER ask for, capture, or store mobile money PINs, CVVs, or bank secrets.\n'
            '• All payments are processed externally through official USSD or your telecommunication/banking provider.',
        isDark: isDark,
        primaryColor: primaryColor,
        isHighlight: true,
      ),
      _buildSection(
        icon: Icons.security_rounded,
        title: '5. Security & Infrastructure',
        content:
            '• Church data transmissions are secured with industry-standard TLS/HTTPS encryption.\n'
            '• Sign-in and identity verification run on Google Firebase Authentication; records are stored in Cloud Firestore.\n'
            '• Access is enforced by written security rules (`firestore.rules`): each office (Administrator, Pastor, Secretary, Deacon, Leader) can read and change only what its service requires, and no client app can grant itself a role.\n'
            '• Heavy media (sermon audio, video, department photos) is hosted on Cloudinary; the radio station list comes from radio-browser.info (lists only — none of your personal data).\n'
            '• Sermon summaries produced with Google Gemini run in the admin portal only, never from your phone.\n'
            '• Offline sermon notes, cached chapters, and devotional bookmarks remain stored strictly on your local device.',
        isDark: isDark,
        primaryColor: primaryColor,
      ),
      _buildSection(
        icon: Icons.delete_forever_rounded,
        title: '6. Your Rights Under PDPA 2022 (Access, Withdrawal, Erasure)',
        content:
            'Under Tanzania PDPA 2022 and Google Play / Apple App Store Guidelines:\n'
            '• Every use of your data rests on a lawful basis evidenced by a consent register. Changing your choices appends a new record — earlier records are never edited, so the church can still prove what was agreed on a given date.\n'
            '• RIGHT OF ACCESS: Profile → "My PDPA rights" → "Prepare a copy of my data" produces a complete JSON export of what this device holds and, when Firebase is connected, what the cloud holds.\n'
            '• RIGHT TO WITHDRAW: you can switch off any optional purpose at any time; membership and financial purposes remain because the law requires them.\n'
            '• RIGHT TO ERASURE: "Delete account" removes your Firebase account together with your identity and prayer records — in the cloud and on this device.\n'
            '• WHAT IS NOT ERASED: financial records (tithes, offerings, income and expenditure) are retained because church bookkeeping and audit law require it; cloud disaster-recovery backups may also take time to roll off.\n'
            '• Requests of this kind are handled within 30 days. Contact privacy@zionjerusalem.org.',
        isDark: isDark,
        primaryColor: primaryColor,
        isHighlight: true,
      ),
      _buildSection(
        icon: Icons.share_rounded,
        title: '7. Data Processors — Who Holds Your Information',
        content:
            'The church is the data controller for this information. The processors your data passes through are:\n'
            '${_processorsText(false)}\n'
            '• Nothing you share is sold or handed to anyone for commercial marketing.',
        isDark: isDark,
        primaryColor: primaryColor,
      ),
    ];
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
    required Color primaryColor,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        borderColor: isHighlight
            ? AppColors.gold.withOpacity(0.6)
            : (isDark ? const Color(0xFF26354A) : AppColors.borderLight),
        backgroundColor: isHighlight
            ? (isDark ? const Color(0xFF142238) : const Color(0xFFFBF8EE))
            : (isDark ? AppColors.surfaceDark : Colors.white),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isHighlight ? AppColors.gold : primaryColor)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isHighlight ? AppColors.goldDark : primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color:
                    isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDpoContactCard(bool isDark, Color primaryColor) {
    return AppCard(
      borderColor: primaryColor.withOpacity(0.4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_mail_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                _isSwahili
                    ? 'Mawasiliano ya Faragha (DPO Contact)'
                    : 'Data Protection Officer (DPO)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isSwahili
                ? 'Ikiwa una maswali yoyote kuhusu sera hii au unataka kutumia haki zako za ulinzi wa taarifa, wasiliana na Afisa wetu wa Ulinzi wa Taarifa (Data Protection Officer):'
                : 'For any privacy inquiries or to exercise your rights under PDPA 2022, please contact our Data Protection Officer:',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          _buildContactRow(Icons.email_outlined,
              'Barua Pepe / Email: privacy@zionjerusalem.org', isDark),
          const SizedBox(height: 6),
          _buildContactRow(Icons.location_on_outlined,
              'Ofisi Kuu: ${ChurchProfile.location}', isDark),
          const SizedBox(height: 6),
          _buildContactRow(Icons.phone_outlined,
              'Simu ya Utawala: ${ChurchProfile.pastoralHelpline}', isDark),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon,
            size: 14,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textMutedLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
