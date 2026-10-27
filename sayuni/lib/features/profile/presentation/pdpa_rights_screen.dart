import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../../core/services/church_auth_service.dart';
import '../../../core/services/church_role_grant_service.dart';
import '../../../core/services/pdpa_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/onboarding_auth_screen.dart';

/// "Haki zangu" — the member's own PDPA 2022 control centre:
/// consent record, access (DSAR export), withdrawal and erasure.
class PdpaRightsScreen extends StatefulWidget {
  const PdpaRightsScreen({super.key, this.askOnOpen = false});

  /// When true the screen is being shown as the onboarding consent step.
  final bool askOnOpen;

  static Future<void> push(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PdpaRightsScreen()),
      );

  /// Opens the consent sheet only when the current policy version has not been
  /// accepted yet. Returns true if it was shown.
  static Future<bool> maybeAsk(BuildContext context) async {
    final pdpa = PdpaService();
    await pdpa.init();
    if (pdpa.hasCurrentConsent) return false;
    if (!context.mounted) return false;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const PdpaRightsScreen(askOnOpen: true),
    ));
    return true;
  }

  @override
  State<PdpaRightsScreen> createState() => _PdpaRightsScreenState();
}

class _PdpaRightsScreenState extends State<PdpaRightsScreen> {
  final PdpaService _pdpa = PdpaService();
  final ChurchAuthService _auth = ChurchAuthService();
  late final Set<String> _chosen = <String>{};
  bool _busy = false;
  String? _exportJson;
  String? _status;

  @override
  void initState() {
    super.initState();
    _pdpa.init().then((_) {
      if (!mounted) return;
      setState(() {
        _chosen
          ..clear()
          ..addAll(_pdpa.activePurposes);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ChurchThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        final isDark = themeService.isDarkMode;
        final primary = themeService.primaryColor;

        return ListenableBuilder(
          listenable: _pdpa,
          builder: (context, __) {
            return Scaffold(
              backgroundColor: AppColors.canvas,
              appBar: AppBar(
                title: const Text('Haki zangu za faragha'),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(30),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sheria ya Ulinzi wa Taarifa Binafsi — Tanzania, 2022',
                        style: TextStyle(fontSize: 11.5, color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
              body: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, 60 + MediaQuery.of(context).padding.bottom),
                children: [
                  _buildHero(isDark, primary),
                  const SizedBox(height: 16),

                  // ---------- 1. CONSENT ----------
                  _buildSectionTitle('1. Idhini yangu', primary),
                  _buildStatusCard(isDark),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chagua kanisa linaweza kutumia taarifa zako kwa nini',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lazima'
                          ' zilizo na alama ya kufululwa ni msingi wa uanachama — '
                          'bila hizo programu haiwezi kufanya kazi yake.',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                              height: 1.35),
                        ),
                        const SizedBox(height: 6),
                        for (final p in PdpaService.purposes)
                          _buildPurposeRow(p, isDark),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _busy ? null : _saveConsent,
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: Text(_pdpa.hasCurrentConsent
                                    ? 'Hifadhi chaguo langu'
                                    : 'Nakubali idhini hii'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            if (_pdpa.active != null) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _busy ? null : _askWithdraw,
                                child: const Text('Ondoa idhini'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(height: 16),

                  // ---------- 2. ACCESS ----------
                  _buildSectionTitle('2. Kufikia data yangu', primary),
                  _buildAccessCard(isDark, primary),
                  const SizedBox(height: 16),

                  // ---------- 3. WHO HOLDS MY DATA ----------
                  _buildSectionTitle('3. Nani anayeshikilia data yangu', primary),
                  _buildInventoryCard(isDark),
                  const SizedBox(height: 16),

                  // ---------- 4. ERASURE ----------
                  _buildSectionTitle('4. Kufuta data yangu', primary),
                  _buildErasureCard(isDark),
                  const SizedBox(height: 18),
                  _buildContactFoot(isDark),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------------ helpers

  Widget _buildSectionTitle(String label, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF07152B), Color(0xFF0F52BA)]
              : [primary.withOpacity(0.10), AppColors.gold.withOpacity(0.14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.privacy_tip_rounded,
                color: AppColors.gold, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unamiliki data yako',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Skrini hii ndiyo mahali pengine pekee unapoweza kuona, '
                  'kubadilisha au kufuta taarifa zako mwenyewe — bila kuomba '
                  'mtu, bila kwingilia simu.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    final active = _pdpa.active;
    final ok = _pdpa.hasCurrentConsent;
    final color = ok ? AppColors.success : AppColors.warning;
    return AppCard(
      borderColor: color.withOpacity(0.45),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ok ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
              color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok
                      ? 'Idhini imetolewa — toleo ${PdpaService.consentVersion}'
                      : 'Hujatoa idhini kwa toleo la sasa',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  active == null
                      ? 'Rekodi yako ya kwanza itandikwa hapa ukibofya '
                          '"Nakubali idhini hii".'
                      : 'Imetolewa ${_fmt(active.at)} kwa njia '
                          '"${active.method}". Rekodi zote ${_pdpa.history.length} '
                          'zimehifadhiwa — kanisa linaweza kuthibitisha ulichokubali.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeRow(PdpaPurpose p, bool isDark) {
    final on = p.required || _chosen.contains(p.key);
    return CheckboxListTile(
      value: on,
      onChanged: p.required
          ? null
          : (v) => setState(() {
                if (v == true) {
                  _chosen.add(p.key);
                } else {
                  _chosen.remove(p.key);
                }
              }),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.success,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(
            p.labelSw,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          if (p.required)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Lazima',
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.goldDark),
              ),
            ),
        ],
      ),
      subtitle: Text(
        p.basis,
        style: TextStyle(
          fontSize: 11,
          height: 1.35,
          color: isDark ? const Color(0xFF94A3B8) : AppColors.textMutedLight,
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _saveConsent() async {
    setState(() => _busy = true);
    await _pdpa.record(
      _chosen,
      method: widget.askOnOpen ? 'onboarding_form' : 'settings_toggle',
    );
    // The register on this device is written first so the member is never kept
    // waiting on the network; the server copy is appended right after.
    final mirrored =
        _auth.hasCloudSession && await _pdpa.mirrorActiveToCloud(_auth.uid ?? '');
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(
      mirrored
          ? 'Idhini yako imeandikwa (toleo ${PdpaService.consentVersion}) na '
              'rekodi imetumwa kwenye wingu.'
          : 'Idhini yako imeandikwa kwenye kifaa hiki (toleo '
              '${PdpaService.consentVersion}). Rekodi ya wingu itatumwa '
              'Firebase inapokuwepo na mtandao upo.',
      AppColors.success,
    );
    if (widget.askOnOpen && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------- access (DSAR)

  Widget _buildAccessCard(bool isDark, Color primary) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.download_rounded, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pakia nakala ya data yangu',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Haki yako ya kufikia (right of access). Programu inakusanya '
            'kile chenyewe ili kwenye kifaa hiki na, kama Firebase iko, '
            'kile kilicho kwenye wingu — kisha kukupa JSON moja kamili.',
            style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _busy
                ? const FilledButton(
                    onPressed: null,
                    child: Text('Inakusanya…'),
                  )
                : FilledButton.icon(
                    onPressed: _runExport,
                    icon: const Icon(Icons.description_rounded, size: 18),
                    label: Text(_exportJson == null
                        ? 'Tengeneza nakala'
                        : 'Tengeneza tena'),
                  ),
          ),
          if (_status != null && _status!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _status!,
                      style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_exportJson != null) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF07152B)
                    : AppColors.surfaceLowLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _exportJson!,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      height: 1.35,
                      color: AppColors.textSecondaryDark),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _copyExport,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Nakili JSON'),
                ),
                OutlinedButton.icon(
                  onPressed: _runExport,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Sasisha'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runExport() async {
    setState(() {
      _busy = true;
      _status = null;
      _exportJson = null;
    });

    Map<String, dynamic> cloud = const <String, dynamic>{};
    String note;
    if (_auth.hasCloudSession) {
      cloud = await ChurchRoleGrantService.exportMyData() ??
          const <String, dynamic>{};
      note = cloud.isEmpty
          ? 'Wingu hakurudishi kitu: functions/exportMyData bado haijapakiwa '
              'kwenye Firebase, au mtandao umekata. Nakala hii ina data ya '
              'kifaa hiki pekee.'
          : 'Data ya wingu imejumuishwa katika nakala hii.';
    } else {
      note = 'Hakuna akaunti ya Firebase kwenye kifaa hiki, kwa hivyo nakala '
          'hii ina data iliyohifadhiwa hapa kwenye simu/bronseri yako pekee.';
    }

    final json = await _pdpa.exportJson(
      identity: <String, dynamic>{
        'name': _auth.name,
        'phone': _auth.phone,
        'email': _auth.email,
        'memberId': _auth.memberId,
        'jumuiya': _auth.jumuiya,
        'department': _auth.department,
        'role': _auth.roleTitle,
        'roleSource': _auth.roleSourceLabel,
        'uid': _auth.uid,
      },
      cloud: cloud,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _exportJson = json;
      _status = note;
    });
  }

  Future<void> _copyExport() async {
    final text = _exportJson;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _snack('Nakala ya data yangu imekwenda kwenye clipboard.',
        AppColors.success);
  }

  // ----------------------------------------------------------- processor table

  Widget _buildInventoryCard(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Washirika wanaoshughulikia taarifa zako',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Orodha hii ni ya kweli — imetokana na msimbo uliomo kwenye programu '
            'hii. Hakuna kitu kinachouzwa au kugawanywa na watu wasioorodheshwa hapa.',
            style: TextStyle(
                fontSize: 11.5, height: 1.4, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          for (final row in PdpaService.dataInventory) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.domain_rounded,
                          size: 14, color: AppColors.gold),
                       const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          row['who'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ANASHIKILIA: ${row['what'] ?? ''}',
                    style: TextStyle(
                        fontSize: 11, height: 1.35, color: AppColors.textMuted),
                  ),
                  Text(
                    'KWA NINI: ${row['why'] ?? ''}',
                    style: TextStyle(
                        fontSize: 11, height: 1.35, color: AppColors.textMuted),
                  ),
                  Text(
                    'MAHALI: ${row['where'] ?? ''}',
                    style: TextStyle(
                        fontSize: 11, height: 1.35, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ erasure

  Widget _buildErasureCard(bool isDark) {
    final what = <String, String>{
      'KITAKAFUTWA':
          'Akaunti yako ya Firebase, profile yako, maombi yako ya sala na '
              'rekodi zako za idhini.',
      'KITAKABAKA':
          'Rekodi za fedha (aseli/michango) kwa sababu sheria ya mapato na '
              'ukaguzi wa kanisa lazimu zihifadhiwe; na kila kitu ambako haina '
              'taarifa yako ya kibinafsi (mahubiri, matangazo).',
      'HALI YA WINGU':
          'Kama functions za Firebase bado hazijapakiwa, kitakachofutwa ni data '
              'za kwenye kifaa hiki pekee — wasiliana na Katibu ili data ya '
              'wingu ifutwe.',
    };
    return AppCard(
      borderColor: AppColors.error.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_rounded,
                    color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Futa akaunti yangu na data yangu',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final e in what.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMutedLight),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _askErase,
              icon: const Icon(Icons.warning_amber_rounded, size: 16),
              label: const Text('Futa akaunti yangu kabisa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactFoot(bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Huna uhakika na kitu?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Andika kwa afisa wa ulinzi wa taarifa za kanisa (Data Protection '
            'Officer): privacy@zionjerusalem.org — tutakujibu ndani ya siku 30 '
            'kama sheria inavyotaka.',
            style: TextStyle(
                fontSize: 11.5, height: 1.4, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _askWithdraw() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Ondoa idhini yako?'),
        content: const Text(
          'Itaondolewa mawasiliano ya simu/SMS/email, uhifadhi wa maombi yako ya '
          'sala na ruhusa ya picha zako. Uanachama na rekodi za fedha hitaondolewa '
          'kwa sababu sheria inazitaka. Unaweza kurudisha idhini wakati wowote.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Simama'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Ndiyo, ninaiondoa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await _pdpa.withdrawAll();
    final mirrored =
        _auth.hasCloudSession && await _pdpa.mirrorActiveToCloud(_auth.uid ?? '');
    if (!mounted) return;
    setState(() {
      _busy = false;
      _chosen.clear();
    });
    _snack(
      mirrored
          ? 'Idhini za hiari zimeondolewa — na rekodi ya wingu imesasishwa.'
          : 'Idhini za hiari zimeondolewa kwenye kifaa hiki. Rekodi za '
              'uanachama na fedha zimebaki.',
      AppColors.warning,
    );
  }

  Future<void> _askErase() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded,
            color: AppColors.error, size: 30),
        title: const Text('Futa akaunti yangu?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hii ni hatua ya mwisho na hairudishiki:',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            _bullet('Utaondolewa kwenye Firebase na kifaa hiki kitatenganishwa na '
                'akaunti yako.'),
            _bullet('Member ID yako itafutwa na utarudi kuwa mgeni.'),
            _bullet('Rekodi za fedha za kanisa zitabaki kwa sababu ya sheria (hizi si taarifa zako za kibinafsi pekee).'),
            const SizedBox(height: 8),
            Text(
              'Shauri: tengeneza nakala ya data yako kwanza (sehemu ya 2) ili uwe na '
              'kumbukumbu yako.',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Ghairi'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Futa kabisa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final result = await _auth.eraseAccount();
    if (!mounted) return;
    setState(() => _busy = false);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: Icon(
          result.viaCloud ? Icons.shield_rounded : Icons.phonelink_erase_rounded,
          color: result.viaCloud ? AppColors.success : AppColors.warning,
        ),
        title: Text(result.viaCloud
            ? 'Akaunti yako ya wingu imefutwa'
            : 'Data za kifaa hiki zimefutwa'),
        content: Text(result.message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Sawa'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingAuthScreen()),
      (route) => false,
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.5, height: 1.35, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
