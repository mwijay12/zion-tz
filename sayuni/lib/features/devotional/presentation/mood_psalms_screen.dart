import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/services/spiritual_wisdom_service.dart';

class MoodPsalmsScreen extends StatefulWidget {
  final String? initialQuery;

  const MoodPsalmsScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<MoodPsalmsScreen> createState() => _MoodPsalmsScreenState();
}

class _MoodPsalmsScreenState extends State<MoodPsalmsScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _customNeedController = TextEditingController();
  final SpiritualWisdomService _wisdomService = SpiritualWisdomService();

  bool _isPlayingAudio = false;
  bool _isLoadingGuidance = false;
  SpiritualGuidanceResult? _currentGuidance;

  final List<Map<String, dynamic>> _moodCategories = [
    {
      'id': 'peace',
      'title': 'Amani & Utulivu',
      'query': 'Nahitaji amani ya moyo na kuondokana na hofu au msukosuko',
      'icon': Icons.spa_rounded,
      'color': Color(0xFF0284C7),
    },
    {
      'id': 'comfort',
      'title': 'Faraja & Huzuni',
      'query':
          'Ninapitia huzuni, upweke na maumivu ya moyo nahitaji faraja ya Mungu',
      'icon': Icons.healing_rounded,
      'color': Color(0xFF0F52BA),
    },
    {
      'id': 'strength',
      'title': 'Vita & Ushindi',
      'query':
          'Niko kwenye mapambano ya kiroho, majaribu na vita nahitaji ushindi wa Bwana',
      'icon': Icons.shield_rounded,
      'color': Color(0xFFDC2626),
    },
    {
      'id': 'healing',
      'title': 'Uponyaji wa Afya',
      'query': 'Nahitaji uponyaji wa ugonjwa mwilini mwangu na afya njema',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFF16A34A),
    },
    {
      'id': 'finances',
      'title': 'Kodi & Ada za Shule',
      'query':
          'Nina wasiwasi kuhusu fedha, madeni, kodi ya nyumba na ada za shule',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFFD97706),
    },
    {
      'id': 'job',
      'title': 'Kazi & Biashara',
      'query':
          'Natafuta kazi, mtaji wa biashara na mwongozo wa maamuzi ya kimaisha',
      'icon': Icons.work_rounded,
      'color': Color(0xFF0D9488),
    },
    {
      'id': 'gratitude',
      'title': 'Shukrani & Sifa',
      'query':
          'Ninamshukuru Mungu kwa wema wake na matendo makuu maishani mwangu',
      'icon': Icons.celebration_rounded,
      'color': Color(0xFFC59B27),
    },
    {
      'id': 'rest',
      'title': 'Pumziko & Nguvu Mpya',
      'query':
          'Nimechoka kiakili na kimwili, nahitaji kuburudishwa na kupata nguvu mpya',
      'icon': Icons.nightlight_round,
      'color': AppColors.primary,
    },
  ];

  Map<String, dynamic>? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _initTts();
    _selectedCategory = _moodCategories.first;
    _fetchGuidance(
        widget.initialQuery ?? _selectedCategory!['query'] as String);
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setLanguage('sw');
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isPlayingAudio = false);
      });
      _flutterTts.setErrorHandler((_) {
        if (mounted) setState(() => _isPlayingAudio = false);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _customNeedController.dispose();
    super.dispose();
  }

  Future<void> _fetchGuidance(String need) async {
    _stopAudio();
    setState(() => _isLoadingGuidance = true);

    try {
      final result = await _wisdomService.getGuidanceForNeed(need);
      if (mounted) {
        setState(() {
          _currentGuidance = result;
          _isLoadingGuidance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGuidance = false);
      }
    }
  }

  void _onCategorySelected(Map<String, dynamic> category) {
    AppHaptics.selectionClick();
    setState(() => _selectedCategory = category);
    _customNeedController.clear();
    _fetchGuidance(category['query'] as String);
  }

  void _submitCustomNeed() {
    final text = _customNeedController.text.trim();
    if (text.isEmpty) return;
    AppHaptics.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() => _selectedCategory = null);
    _fetchGuidance(text);
  }

  Future<void> _toggleAudio() async {
    AppHaptics.lightImpact();
    if (_isPlayingAudio) {
      _stopAudio();
    } else {
      if (_currentGuidance == null) return;
      setState(() => _isPlayingAudio = true);
      final textToSpeak =
          '${_currentGuidance!.scriptureReference}. ${_currentGuidance!.scriptureText}. Ujumbe wa kiroho: ${_currentGuidance!.pastoralWord}. Sala ya leo: ${_currentGuidance!.prayer}';
      await _flutterTts.speak(textToSpeak);
    }
  }

  void _stopAudio() {
    setState(() => _isPlayingAudio = false);
    _flutterTts.stop();
  }

  void _shareGuidance() {
    AppHaptics.lightImpact();
    if (_currentGuidance == null) return;
    final shareText = '''
*DAWA YA NAFSI & MWONGOZO WA KIROHO*
Kanisa la Zion Jerusalem • Mbagala Kwa Matope

📖 *${_currentGuidance!.scriptureReference}*
"${_currentGuidance!.scriptureText}"

💡 *Tafakari:*
${_currentGuidance!.pastoralWord}

🙏 *Sala ya Ushindi:*
${_currentGuidance!.prayer}

🎵 *Wimbo wa Tenzi:* Tenzi #${_currentGuidance!.recommendedHymnNumber}: ${_currentGuidance!.recommendedHymnTitle}

Ubarikiwe na Mungu wa Sayuni!
''';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = 180.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Dawa ya Nafsi & Sala',
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            tooltip: 'Shiriki Ujumbe',
            onPressed: _currentGuidance != null ? _shareGuidance : null,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Gentle Header Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    Color(0xFF0F3E7A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.spa_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Unajisikiaje Leo?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chagua au andika haja ya moyo wako hapa chini ili kupata neno la Mungu, faraja ya kichungaji, na sala ya ushindi kwa ajili yako.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12.5, height: 1.35),
                  ),
                  const SizedBox(height: 14),

                  // Custom need input field with dark container & explicit fill to prevent white-on-white
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF071933),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customNeedController,
                            cursorColor: AppColors.primaryLight,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500),
                            onSubmitted: (_) => _submitCustomNeed(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF071933),
                              hintText:
                                  'Andika haja yako (mf. Ada za watoto, Kazi, Ugonjwa)...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded,
                                color: AppColors.primaryLight, size: 20),
                            onPressed: _submitCustomNeed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Horizontal Mood Categories Carousel
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _moodCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = _moodCategories[idx];
                  final isSelected = _selectedCategory?['id'] == cat['id'];
                  final Color catColor = cat['color'] as Color;

                  return InkWell(
                    onTap: () => _onCategorySelected(cat),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? catColor : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: catColor.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 16,
                            color: isSelected ? Colors.white : catColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['title'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Main Result Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _isLoadingGuidance
                  ? AppCard(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: AppColors.primary),
                            const SizedBox(height: 16),
                            Text(
                              'Inatafuta Neno la Faraja & Sala...',
                              style: AppTypography.bodyMedium(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _currentGuidance != null
                      ? _buildGuidanceCard(_currentGuidance!)
                      : const SizedBox.shrink(),
            ),
          ),

          // Bottom inset clearance
          SliverToBoxAdapter(
            child: SizedBox(height: bottomInset),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceCard(SpiritualGuidanceResult guidance) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A2540),
            Color(0xFF0F3E7A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Pill & Audio button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppColors.goldLight, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'NENO LA UZIMA • SAYUNI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isPlayingAudio
                      ? Icons.stop_circle_rounded
                      : Icons.volume_up_rounded,
                  color:
                      _isPlayingAudio ? Colors.redAccent : AppColors.goldLight,
                  size: 26,
                ),
                tooltip:
                    _isPlayingAudio ? 'Simamisha Sauti' : 'Sikiliza kwa Sauti',
                onPressed: _toggleAudio,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Scripture Reference Header
          Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                guidance.scriptureReference,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Scripture Text Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Text(
              '"${guidance.scriptureText}"',
              style: AppTypography.scriptureVerse(
                color: Colors.white,
                fontSize: 15.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pastoral Word
          Row(
            children: [
              const Icon(Icons.volunteer_activism_rounded,
                  color: AppColors.goldLight, size: 16),
              const SizedBox(width: 6),
              const Text(
                'TAFAKARI YA KICHUNGAJI:',
                style: TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            guidance.pastoralWord,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),

          // Prayer Section
          Row(
            children: [
              const Icon(Icons.church_rounded, color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              const Text(
                'SALA YA USHINDI:',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            guidance.prayer,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Recommended Tenzi Hymn Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.music_note_rounded,
                      color: AppColors.primaryDark, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WIMBO WA TENZI WA KUIMBA LEO:',
                        style: TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Tenzi #${guidance.recommendedHymnNumber}: ${guidance.recommendedHymnTitle}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Share & Listen
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareGuidance,
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: const Text('Shiriki'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleAudio,
                  icon: Icon(
                      _isPlayingAudio
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      size: 18),
                  label: Text(_isPlayingAudio ? 'Simamisha' : 'Sikiliza Sauti'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
