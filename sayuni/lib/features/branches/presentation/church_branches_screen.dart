import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/module_decor.dart';
import '../../../core/theme/church_theme_service.dart';
import '../models/branch_model.dart';

class ChurchBranchesScreen extends StatefulWidget {
  const ChurchBranchesScreen({super.key});

  @override
  State<ChurchBranchesScreen> createState() => _ChurchBranchesScreenState();
}

class _ChurchBranchesScreenState extends State<ChurchBranchesScreen> {
  String _selectedCity = 'Yote';
  String _searchQuery = '';

  final List<String> _cities = [
    'Yote',
    'Dar es Salaam',
    'Pwani',
    'Morogoro',
    'Bukoba (Kagera)',
    'Njombe',
    'Makambako',
  ];

  Future<void> _makePhoneCall(String phoneNumber) async {
    AppHaptics.lightImpact();
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Haikuweza kupiga simu: $phoneNumber'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String waNumber, String churchName) async {
    AppHaptics.lightImpact();
    final message = Uri.encodeComponent(
      'Habari ya Bwana Yesu. Natamani kuwasiliana na $churchName kwa ajili ya ushauri na huduma.',
    );
    final Uri url = Uri.parse('https://wa.me/$waNumber?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Haikuweza kufungua WhatsApp'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBranches = ChurchBranch.defaultBranches.where((branch) {
      final matchesCity = _selectedCity == 'Yote' || branch.city == _selectedCity;
      final matchesSearch = branch.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          branch.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          branch.pastor.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          branch.location.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCity && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Matawi ya Kanisa & Misheni',
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                ModuleBanner(
                  eyebrow: 'Mikoa • Misheni • Mabalo',
                  title: 'Matawi ya Kanisa',
                  subtitle: 'Tafuta tawi karibu nawe, pigia simu au tuma WhatsApp.',
                  imageAsset: 'assets/images/3d_branch_network.png',
                  gradient: const <Color>[Color(0xFF0D52CD), Color(0xFF0A2540)],
                  stats: <ModuleBannerStat>[
                    ModuleBannerStat('${filteredBranches.length}', 'Matawi'),
                    const ModuleBannerStat('8', 'Mikoa'),
                    const ModuleBannerStat('24/7', 'Maombi'),
                  ],
                ),
                const SizedBox(height: 14),

                // Search Field
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tafuta tawi, mji, au mchungaji...',
                    hintStyle: AppTypography.bodySmall(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    filled: true,
                    fillColor: AppColors.canvas,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // City Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cities.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final city = _cities[idx];
                      final isSelected = _selectedCity == city;
                      return ChoiceChip(
                        label: Text(city),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            AppHaptics.selectionClick();
                            setState(() => _selectedCity = city);
                          }
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.canvas,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Branches List
          Expanded(
            child: filteredBranches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 116,
                          height: 92,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/3d_branch_network.png',
                            fit: BoxFit.contain,
                            errorBuilder: (BuildContext c, Object e, StackTrace? st) => Icon(
                              Icons.church_rounded,
                              size: 44,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Hakuna tawi lililopatikana',
                          style: AppTypography.titleMedium(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jaribu kubadilisha jina la mji au neno la kutafuta',
                          style: AppTypography.bodySmall(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBranches.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final branch = filteredBranches[index];
                      return _buildBranchCard(branch, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(ChurchBranch branch, int index) {
    final accent = ModuleAccents.at(index);
    final isDark = ChurchThemeService().isDarkMode;

    return AppCard(
      borderColor: accent.withOpacity(0.34),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rangi ya tawi - upau wa kushoto
              Container(width: 5, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accent.withOpacity(0.24), accent.withOpacity(0.08)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: accent.withOpacity(0.32)),
                            ),
                            child: Icon(
                              branch.isHeadquarters
                                  ? Icons.account_balance_rounded
                                  : Icons.church_rounded,
                              color: accent,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (branch.isHeadquarters)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 5),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'MAKAO MAKUU (HQ)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                        letterSpacing: 0.7,
                                      ),
                                    ),
                                  ),
                                Text(
                                  branch.name,
                                  style: AppTypography.titleMedium(
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, size: 13, color: accent),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        branch.location,
                                        style: AppTypography.caption(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: accent.withOpacity(0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 7),
                                Text(
                                  'Kiongozi:',
                                  style: AppTypography.caption(color: AppColors.textMuted),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    branch.pastor,
                                    style: AppTypography.bodySmall(
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.schedule_rounded, size: 14, color: accent),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    branch.serviceTimes,
                                    style: AppTypography.caption(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _makePhoneCall(branch.phone),
                              icon: const Icon(Icons.phone_rounded, size: 15),
                              label: const Text(
                                'Piga Simu',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                side: BorderSide(color: accent.withOpacity(0.7)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openWhatsApp(branch.whatsapp, branch.name),
                              icon: const Icon(Icons.chat_rounded, size: 15),
                              label: const Text(
                                'WhatsApp',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
