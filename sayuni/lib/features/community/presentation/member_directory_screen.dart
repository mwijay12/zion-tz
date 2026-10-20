import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/church_auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../models/member_directory_model.dart';
import '../services/member_directory_service.dart';

class MemberDirectoryScreen extends StatefulWidget {
  final bool isEmbedded;
  const MemberDirectoryScreen({super.key, this.isEmbedded = false});

  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> {
  final MemberDirectoryService _service = MemberDirectoryService();
  String _searchQuery = '';
  String _selectedCategory = 'Yote';

  final List<String> _categories = [
    'Yote',
    'Kilimo & Mifugo',
    'Tehama & Apps',
    'Ufundi & Ujenzi',
    'Mavazi & Urembo',
    'Afya & Ustawi',
    'Elimu & Mafunzo',
    'Biashara',
  ];

  void _callMember(String phone) async {
    AppHaptics.lightImpact();
    final cleanPhone = phone.replaceAll(' ', '').replaceAll('-', '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Namba ya simu: $phone')),
        );
      }
    }
  }

  void _openWhatsApp(String phone, String name) async {
    AppHaptics.lightImpact();
    final cleanPhone = phone.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '');
    final msg = Uri.encodeComponent('Bwana Yesu Asifiwe $name, nimepata mawasiliano yako kwenye App ya Sayuni Jerusalem Church.');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _callMember(phone);
    }
  }

  void _showAddSkillDialog() {
    AppHaptics.lightImpact();
    final auth = ChurchAuthService();
    final nameCtrl = TextEditingController(text: auth.name.isNotEmpty ? auth.name : '');
    final professionCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: auth.phone.isNotEmpty ? auth.phone : '');
    final locationCtrl = TextEditingController(text: 'Mbagala');
    final expCtrl = TextEditingController(text: 'Miaka 3');
    String selectedCat = 'Kilimo & Mifugo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              top: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.90,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                    top: 14,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tangaza Ujuzi / Biashara Yako',
                              style: AppTypography.headlineMedium(color: AppColors.textPrimary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Jina Lako Kamili *',
                            hintText: 'Mf. David Mwita',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: professionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Taaluma / Kazi / Biashara Yako *',
                            hintText: 'Mf. Mkulima wa Mboga, Fundi Umeme, Daktari',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedCat,
                          decoration: const InputDecoration(labelText: 'Kundi la Ujuzi'),
                          items: _categories.where((c) => c != 'Yote').map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCat = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Maelezo ya Huduma / Bidhaa Zako *',
                            hintText: 'Eleza unachoweza kuwasaidia waumini wenzako...',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Namba ya Simu *',
                                  hintText: '+255...',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: locationCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Eneo Unaloishi',
                                  hintText: 'Mf. Charambe',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameCtrl.text.trim().isEmpty ||
                                  professionCtrl.text.trim().isEmpty ||
                                  phoneCtrl.text.trim().isEmpty) {
                                return;
                              }
                              AppHaptics.mediumImpact();
                              final newProfile = MemberSkillProfile(
                                id: 'skill-${DateTime.now().millisecondsSinceEpoch}',
                                fullName: nameCtrl.text.trim(),
                                profession: professionCtrl.text.trim(),
                                category: selectedCat,
                                description: descCtrl.text.trim().isNotEmpty
                                    ? descCtrl.text.trim()
                                    : 'Natoa huduma kwa uaminifu na viwango vya kikanisa.',
                                phone: phoneCtrl.text.trim(),
                                location: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : 'Mbagala',
                                jumuiya: auth.jumuiya.isNotEmpty ? auth.jumuiya : 'Sayuni Fellowship',
                                experienceYears: expCtrl.text.trim(),
                                avatarEmoji: selectedCat.contains('Kilimo')
                                    ? '🥬'
                                    : (selectedCat.contains('Tehama')
                                        ? '💻'
                                        : (selectedCat.contains('Ufundi')
                                            ? '⚡'
                                            : (selectedCat.contains('Mavazi') ? '🧵' : '💼'))),
                              );

                              await _service.registerMemberSkill(newProfile);
                              if (ctx.mounted) Navigator.pop(ctx);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ujuzi wako umeongezwa kwenye Saraka ya Waumini!'),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: const Text('Wasilisha Kwenye Saraka'),
                          ),
                        ),
                      ],
                    ),
                  ),
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
    final bottomInset = 36.0 + MediaQuery.of(context).padding.bottom;

    final content = ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final profiles = _service.allProfiles.where((p) {
          final matchesCategory = _selectedCategory == 'Yote' || p.category == _selectedCategory;
          final matchesQuery = _searchQuery.isEmpty ||
              p.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.profession.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.location.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesCategory && matchesQuery;
        }).toList();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Motivational Banner (scrolls smoothly with content)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handshake_rounded, color: AppColors.gold, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kusaidiana Kiuchumi & Biashara',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Fursa na huduma za waumini Sayuni',
                              style: AppTypography.caption(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddSkillDialog,
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: const Text('Jiunge'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search Box (scrolls smoothly with content)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Tafuta fundi, mkulima, biashara...',
                      hintStyle: AppTypography.bodySmall(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
            ),

            // Category Chips (scrolls with content)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, idx) {
                    final cat = _categories[idx];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) {
                          AppHaptics.selectionClick();
                          setState(() => _selectedCategory = cat);
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 6)),

            // Profiles List with maximum viewport space
            if (profiles.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      const Text('Hakuna Ujuzi Uliopatikana', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Jaribu neno jingine au weka ujuzi wako.'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _showAddSkillDialog,
                        child: const Text('Weka Ujuzi Wako'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = profiles[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primary.withOpacity(0.12),
                                    child: Text(p.avatarEmoji, style: const TextStyle(fontSize: 22)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                p.fullName,
                                                style: AppTypography.titleMedium(color: AppColors.textPrimary),
                                              ),
                                            ),
                                            if (p.isVerifiedMember)
                                              const Tooltip(
                                                message: 'Muumini Aliyehakikiwa Sayuni',
                                                child: Icon(Icons.verified_rounded, size: 16, color: Color(0xFF16A34A)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          p.profession,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${p.location} • ${p.jumuiya}',
                                          style: AppTypography.caption(color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                p.description,
                                style: AppTypography.bodyMedium(color: AppColors.textSecondary).copyWith(height: 1.5),
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 10),

                              // Actions: Call & WhatsApp
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _callMember(p.phone),
                                      icon: const Icon(Icons.call_rounded, size: 16),
                                      label: const Text('Piga Simu'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.surfaceContainer,
                                        foregroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openWhatsApp(p.phone, p.fullName),
                                      icon: const Icon(Icons.chat_rounded, size: 16),
                                      label: const Text('WhatsApp'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF25D366).withOpacity(0.15),
                                        foregroundColor: const Color(0xFF0F5132),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: profiles.length,
                  ),
                ),
              ),
          ],
        );
      },
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Saraka ya Ujuzi & Biashara',
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSkillDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Weka Ujuzi Wangu'),
      ),
      body: SafeArea(
        bottom: false,
        child: content,
      ),
    );
  }
}
