import 'package:flutter/material.dart';
import '../../../core/services/church_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';

class ConnectCardScreen extends StatefulWidget {
  const ConnectCardScreen({super.key});

  @override
  State<ConnectCardScreen> createState() => _ConnectCardScreenState();
}

class _ConnectCardScreenState extends State<ConnectCardScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _prayerController = TextEditingController();

  String _visitorType = 'Mgeni wa Mara ya Kwanza';
  final List<String> _interests = [];

  final List<String> _visitorTypes = [
    'Mgeni wa Mara ya Kwanza',
    'Natafuta Kanisa la Kudumu',
    'Muumini ninayetaka Kujiunga na Jumuiya',
    'Natarajia Kutoa Ushuhuda',
  ];

  final List<String> _availableInterests = [
    'Kwaya Kuu',
    'Ukaribisho (Ushers)',
    'Sunday School',
    'Media & Mawasiliano',
    'Maombi & Uombezi',
    'Idara ya Vijana',
    'Idara ya Wanawake',
    'Idara ya Wanaume',
  ];

  bool _isSubmitted = false;

  void _toggleInterest(String interest) {
    AppHaptics.selectionClick();
    setState(() {
      if (_interests.contains(interest)) {
        _interests.remove(interest);
      } else {
        _interests.add(interest);
      }
    });
  }

  void _submitCard() {
    AppHaptics.mediumImpact();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tafadhali jaza Jina na Namba ya Simu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ChurchSyncService().syncNewVisitor(
      fullName: name,
      phone: phone,
      residence: _locationController.text.trim(),
      visitorType: _visitorType,
      assignedJumuiya: 'Mbagala Kuu',
      prayerRequest: _prayerController.text.trim(),
      interests: _interests.join(', '),
    );

    setState(() => _isSubmitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Kadi ya Mgeni & Ushirika',
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isSubmitted
          ? _buildSuccessView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Welcome Hero Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A2540), Color(0xFF031B4E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.church_rounded, color: AppColors.goldLight, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'KARIBU SAYUNI',
                            style: AppTypography.caption(color: AppColors.goldLight).copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tunafurahi Kuwa Nawe Leo!',
                        style: AppTypography.titleMedium(color: Colors.white).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hapa Sayuni wewe si mgeni, bali ni sehemu ya familia ya Mungu. Jaza kadi hii fupi ili uongozi wa kichungaji uweze kuwasiliana nawe na kukuombea.',
                        style: AppTypography.bodySmall(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taarifa Zako',
                        style: AppTypography.titleMedium(color: AppColors.textPrimary).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Jina Kamili',
                          prefixIcon: const Icon(Icons.person_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Namba ya Simu / WhatsApp',
                          prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Mtaa / Eneo Unaloishi',
                          prefixIcon: const Icon(Icons.location_on_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text('Aina ya Ugeni', style: AppTypography.caption(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: _visitorType,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: _visitorTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _visitorType = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Idara Zinazokuvutia (Chagua):',
                        style: AppTypography.bodySmall(color: AppColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _availableInterests.map((interest) {
                          final isSelected = _interests.contains(interest);
                          return FilterChip(
                            label: Text(interest),
                            selected: isSelected,
                            onSelected: (_) => _toggleInterest(interest),
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: _prayerController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Ombi Maalumu la Maombi (Hiari)',
                          prefixIcon: const Icon(Icons.favorite_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitCard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Wasilisha Kadi ya Mgeni', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Karibu Sana Nyumbani!',
              style: AppTypography.titleMedium(color: AppColors.textPrimary).copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Taarifa zako zimepokelewa kwa upendo na Idara ya Ukaribisho na Askofu Mercy Mgalla. Tutaendelea kuwasiliana nawe kwa maombi na ushirika.',
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Rudi Mwanzo'),
            ),
          ],
        ),
      ),
    );
  }
}
