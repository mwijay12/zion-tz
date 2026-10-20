import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../models/giving_channel.dart';
import '../services/giving_service.dart';
import '../../profile/presentation/privacy_policy_screen.dart';

class GivingScreen extends StatefulWidget {
  const GivingScreen({super.key});

  @override
  State<GivingScreen> createState() => _GivingScreenState();
}

class _GivingScreenState extends State<GivingScreen> {
  final GivingService _givingService = GivingService();
  List<GivingRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final data = await _givingService.getRecords();
    setState(() => _records = data);
  }

  void _copyToClipboard(String text, String label) {
    AppHaptics.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ($text) imenakiliwa kikamilifu!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _dialUssd(String ussdCode) async {
    AppHaptics.lightImpact();
    // USSD needs uri encoding for #
    final encoded = Uri.encodeComponent(ussdCode);
    final uri = Uri.parse('tel:$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Piga USSD: $ussdCode')),
        );
      }
    }
  }

  void _showRecordGivingDialog() {
    AppHaptics.lightImpact();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final amountController = TextEditingController();
    final refController = TextEditingController();
    String selectedCategory = 'Sadaka ya Jumapili';
    String selectedChannel = 'M-Pesa (5524101)';

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
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rekodi Sadaka au Zaka',
                          style: AppTypography.headlineMedium(color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Aina ya Utoaji'),
                      items: const [
                        DropdownMenuItem(value: 'Sadaka ya Jumapili', child: Text('Sadaka ya Jumapili')),
                        DropdownMenuItem(value: 'Zaka (Fungu la Kumi)', child: Text('Zaka (Fungu la Kumi)')),
                        DropdownMenuItem(value: 'Ujenzi wa Hekalu', child: Text('Ujenzi wa Hekalu (Mabati/Sakafu)')),
                        DropdownMenuItem(value: 'Sadaka ya Shukrani', child: Text('Sadaka ya Shukrani')),
                        DropdownMenuItem(value: 'Sadaka ya Vikundi', child: Text('Sadaka ya Jumuiya ya Nyumbani')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kiasi (TSh) *',
                        hintText: 'Mf. 20000',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedChannel,
                      decoration: const InputDecoration(labelText: 'Njia Uliyotumia'),
                      items: const [
                        DropdownMenuItem(value: 'M-Pesa (5524101)', child: Text('Vodacom M-Pesa (5524101)')),
                        DropdownMenuItem(value: 'TigoPesa (8919293)', child: Text('Tigo Pesa (8919293)')),
                        DropdownMenuItem(value: 'Airtel Money (3310022)', child: Text('Airtel Money (3310022)')),
                        DropdownMenuItem(value: 'Benki ya CRDB', child: Text('Benki ya CRDB (0150829103900)')),
                        DropdownMenuItem(value: 'Pesa Taslimu', child: Text('Pesa Taslimu (Bahashani)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedChannel = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: refController,
                      decoration: const InputDecoration(
                        labelText: 'Namba ya Muamala / Reference',
                        hintText: 'Mf. 8A72B9X...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final amount = double.tryParse(amountController.text.trim()) ?? 0;
                          if (amount <= 0) return;

                          AppHaptics.mediumImpact();
                          final newRecord = GivingRecord(
                            id: 'rec-${DateTime.now().millisecondsSinceEpoch}',
                            category: selectedCategory,
                            amount: amount,
                            paymentChannel: selectedChannel,
                            referenceNumber: refController.text.trim(),
                            date: DateTime.now(),
                          );
                          await _givingService.addRecord(newRecord);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadRecords();

                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Kumbukumbu ya sadaka imehifadhiwa salama!'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text('Hifadhi Rekodi Yangu'),
                      ),
                    ),
                  ],
                ),
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
          'Sadaka, Zaka & Ujenzi',
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: _showRecordGivingDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 96),
        children: [
          // Building Project Tracker Card (Stitch specification)
          _buildBuildingProjectCard(),
          const SizedBox(height: 24),

          // Official Church Payment Channels (1-tap copy & USSD)
          SectionHeader(
            title: 'Njia Rasmi za Kutoa',
            subtitle: 'Bofya namba kunakili au bofya USSD kupiga moja kwa moja',
          ),
          ...GivingService.channels.map((channel) => _buildChannelTile(channel)),
          const SizedBox(height: 24),

          // Scripture Promise on Giving
          _buildScriptureCard(),
          const SizedBox(height: 14),

          // Zero PIN Storage & PDPA 2022 Compliance Notice
          _buildSecurityComplianceBadge(),
          const SizedBox(height: 24),

          // Personal Giving History
          SectionHeader(
            title: 'Kumbukumbu Zangu za Utoaji',
            subtitle: 'Rekodi zako za siri za sadaka na zaka',
            actionText: 'Ongeza',
            onAction: _showRecordGivingDialog,
          ),
          _buildHistoryList(),
        ],
      ),
    );
  }

  Widget _buildBuildingProjectCard() {
    const target = GivingService.buildingTarget;
    const raised = GivingService.buildingRaised;
    const progress = raised / target;

    return AppCard(
      backgroundColor: AppColors.surface,
      borderColor: AppColors.gold,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MRADI WA KANISA',
                  style: AppTypography.caption(color: AppColors.onGoldContainer),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% Imekamilika',
                style: AppTypography.labelLarge(color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            GivingService.buildingProjectName,
            style: AppTypography.titleMedium(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zilizopatikana', style: AppTypography.caption(color: AppColors.textMuted)),
                  Text(AppFormatters.formatTsh(raised), style: AppTypography.labelLarge(color: AppColors.textPrimary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Lengo Kuu', style: AppTypography.caption(color: AppColors.textMuted)),
                  Text(AppFormatters.formatTsh(target), style: AppTypography.labelLarge(color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTile(GivingChannel channel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: channel.brandColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(channel.icon, color: channel.brandColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(channel.name, style: AppTypography.titleMedium(color: AppColors.textPrimary)),
                      Text(channel.accountName, style: AppTypography.caption(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Namba ya Malipo:', style: AppTypography.caption(color: AppColors.textMuted)),
                      Text(
                        channel.payNumber,
                        style: AppTypography.titleMedium(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _copyToClipboard(channel.payNumber, channel.name),
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label: const Text('Nakili'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainer,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _dialUssd(channel.ussdCode),
                          icon: const Icon(Icons.phone_rounded, size: 14),
                          label: const Text('Piga USSD'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      ),
    );
  }

  Widget _buildScriptureCard() {
    return AppCard(
      backgroundColor: AppColors.surfaceContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"Leteni zaka zote ghalani, ili kiwemo chakula katika nyumba yangu; mkanijaribu kwa njia hiyo, asema Bwana wa majeshi; mjue kama sitawafungulia madirisha ya mbinguni, na kuwamwagia baraka, hata isiwepo nafasi ya kutosha."',
            style: AppTypography.scriptureVerse(
              color: AppColors.textPrimary,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— Malaki 3:10',
              style: AppTypography.labelLarge(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityComplianceBadge() {
    return AppCard(
      backgroundColor: AppColors.canvas,
      borderColor: AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Utoaji Salama • Zero PIN Storage',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Malipo yote yanalindwa (PDPA 2022). Hatuhifadhi nenosiri wala taarifa za kibenki.',
                  style: AppTypography.caption(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => PrivacyPolicyScreen.show(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Sera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_records.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded, color: AppColors.textMuted, size: 36),
              const SizedBox(height: 8),
              Text(
                'Hujarekodi utoaji wowote bado',
                style: AppTypography.labelLarge(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Rekodi zako za utoaji hukaa salama kwenye simu yako.',
                style: AppTypography.caption(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _records.map((rec) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.category, style: AppTypography.labelLarge(color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '${rec.paymentChannel} • ${AppFormatters.formatSwahiliDate(rec.date)}',
                      style: AppTypography.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
                Text(
                  AppFormatters.formatTsh(rec.amount),
                  style: AppTypography.labelLarge(color: AppColors.success),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
