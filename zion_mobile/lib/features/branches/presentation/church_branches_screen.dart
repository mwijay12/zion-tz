import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
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
                        Icon(Icons.church_rounded, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
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
                      return _buildBranchCard(branch);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(ChurchBranch branch) {
    return AppCard(
      borderColor: branch.isHeadquarters ? AppColors.gold.withOpacity(0.5) : AppColors.border,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + HQ Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: branch.isHeadquarters
                      ? AppColors.gold.withOpacity(0.15)
                      : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  branch.isHeadquarters ? Icons.account_balance_rounded : Icons.church_rounded,
                  color: branch.isHeadquarters ? AppColors.gold : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (branch.isHeadquarters)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'MAKAO MAKUU (HQ)',
                          style: AppTypography.caption(color: AppColors.goldDark).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    Text(
                      branch.name,
                      style: AppTypography.titleMedium(color: AppColors.textPrimary).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            branch.location,
                            style: AppTypography.caption(color: AppColors.textSecondary),
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
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Pastor in charge
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Kiongozi:',
                style: AppTypography.caption(color: AppColors.textSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                branch.pastor,
                style: AppTypography.bodySmall(color: AppColors.textPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Service Schedule
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branch.serviceTimes,
                  style: AppTypography.caption(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Buttons: Call & WhatsApp
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _makePhoneCall(branch.phone),
                  icon: const Icon(Icons.phone_rounded, size: 16),
                  label: const Text('Piga Simu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
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
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: const Text('WhatsApp'),
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
    );
  }
}
