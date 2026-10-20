import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/services/church_audio_service.dart';
import '../../../core/services/radio_browser_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';

class OnlineRadioScreen extends StatefulWidget {
  final String initialCategory;

  const OnlineRadioScreen({
    super.key,
    this.initialCategory = 'all',
  });

  @override
  State<OnlineRadioScreen> createState() => _OnlineRadioScreenState();
}

class _OnlineRadioScreenState extends State<OnlineRadioScreen> {
  final RadioBrowserService _radioService = RadioBrowserService();
  final ChurchAudioService _audioService = ChurchAudioService();

  late String _selectedTab;
  final TextEditingController _searchController = TextEditingController();

  List<RadioStation> _allStations = [];
  List<RadioStation> _afroGospelRadios = [];
  List<RadioStation> _tzGospelRadios = [];
  List<RadioStation> _globalGospelRadios = [];
  List<RadioStation> _newsRadios = [];
  List<RadioStation> _searchResults = [];

  bool _isLoadingAll = false;
  bool _isLoadingAfro = false;
  bool _isLoadingTz = false;
  bool _isLoadingGlobal = false;
  bool _isLoadingNews = false;
  bool _isSearching = false;
  String _selectedGenreTag = 'wote';

  final List<Map<String, String>> _tabs = [
    {'id': 'all', 'label': 'Vituo Vyote vya Injili 🌍', 'title': 'Vituo 1,000+ vya Injili Duniani'},
    {'id': 'afrogospel', 'label': 'Afro Gospel 🇳🇬', 'title': 'Afro Gospel (Afrika & Nigeria)'},
    {'id': 'tanzania', 'label': 'Tanzania 🇹🇿', 'title': 'Radio za Injili Tanzania'},
    {'id': 'global', 'label': 'Injili & Worship 🕊️', 'title': 'Global Christian & Worship'},
    {'id': 'news', 'label': 'Habari & Taarifa 📰', 'title': 'Habari & Taarifa za Kikanisa'},
    {'id': 'search', 'label': 'Tafuta 🔍', 'title': 'Tafuta Radio ya Injili'},
  ];

  final List<Map<String, String>> _genreChips = [
    {'id': 'wote', 'label': '🌟 Injili Zote 1,000+'},
    {'id': 'gospel', 'label': '🙏 Sifa & Kuabudu'},
    {'id': 'worship', 'label': '🕊️ Kuabudu (Worship)'},
    {'id': 'swahili', 'label': '🇹🇿 Injili Kiswahili'},
    {'id': 'african', 'label': '🇳🇬 Afro Gospel'},
    {'id': 'christian', 'label': '✝️ Mahubiri & Neno'},
    {'id': 'choir', 'label': '🎼 Kwaya & Tenzi'},
    {'id': 'hymns', 'label': '📖 Tenzi za Rohoni'},
    {'id': 'prayer', 'label': '🔥 Maombi & Sala'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialCategory;
    // Load pre-curated immediately for instantaneous UI feedback
    _afroGospelRadios = RadioBrowserService.curatedAfroGospelRadios;
    _tzGospelRadios = RadioBrowserService.curatedTanzaniaGospelRadios;
    _newsRadios = RadioBrowserService.curatedNewsRadios;
    _allStations = [
      ...RadioBrowserService.curatedAfroGospelRadios,
      ...RadioBrowserService.curatedTanzaniaGospelRadios,
      ...RadioBrowserService.curatedNewsRadios,
    ];

    // Fetch dynamic 1,000+ live stations from Radio Browser API
    _loadAllStations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllStations() async {
    _fetchAllStations();
    _fetchAfroGospel();
    _fetchTzGospel();
    _fetchNews();
    _fetchGlobal();
  }

  Future<void> _fetchAllStations() async {
    if (!mounted) return;
    setState(() => _isLoadingAll = true);
    final stations = await _radioService.fetchAllTopStations(limit: 1000);
    if (mounted) {
      setState(() {
        _allStations = stations;
        _isLoadingAll = false;
      });
    }
  }

  Future<void> _filterByGenre(String tagId) async {
    AppHaptics.selectionClick();
    setState(() {
      _selectedGenreTag = tagId;
    });

    if (tagId == 'wote') {
      await _fetchAllStations();
    } else {
      setState(() => _isLoadingAll = true);
      final stations = await _radioService.fetchStationsByGenre(tagId, limit: 300);
      if (mounted) {
        setState(() {
          _allStations = stations.isNotEmpty ? stations : _allStations;
          _isLoadingAll = false;
        });
      }
    }
  }

  Future<void> _fetchAfroGospel() async {
    if (!mounted) return;
    setState(() => _isLoadingAfro = true);
    final stations = await _radioService.fetchAfroGospelRadios();
    if (mounted) {
      setState(() {
        _afroGospelRadios = stations;
        _isLoadingAfro = false;
      });
    }
  }

  Future<void> _fetchTzGospel() async {
    if (!mounted) return;
    setState(() => _isLoadingTz = true);
    final stations = await _radioService.fetchTanzaniaGospelRadios();
    if (mounted) {
      setState(() {
        _tzGospelRadios = stations;
        _isLoadingTz = false;
      });
    }
  }

  Future<void> _fetchGlobal() async {
    if (!mounted) return;
    setState(() => _isLoadingGlobal = true);
    final stations = await _radioService.fetchGlobalGospelRadios();
    if (mounted) {
      setState(() {
        _globalGospelRadios = stations;
        _isLoadingGlobal = false;
      });
    }
  }

  Future<void> _fetchNews() async {
    if (!mounted) return;
    setState(() => _isLoadingNews = true);
    final stations = await _radioService.fetchNewsRadios();
    if (mounted) {
      setState(() {
        _newsRadios = stations;
        _isLoadingNews = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await _radioService.searchStations(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _handleStationTap(RadioStation station) {
    AppHaptics.selectionClick();
    _showStationDetailsSheet(context, station);
  }

  void _togglePlayStation(RadioStation station) {
    AppHaptics.mediumImpact();
    final isCurrent = _audioService.currentTrack?.id == station.stationuuid;
    final isPlaying = isCurrent && _audioService.isPlaying;

    if (isPlaying) {
      _audioService.togglePlayPause();
    } else {
      _audioService.playRadioBrowserStation(station);
      _radioService.registerStationClick(station.stationuuid);
    }
  }

  void _showStationDetailsSheet(BuildContext context, RadioStation station) {
    AppHaptics.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _audioService,
          builder: (context, _) {
            final isCurrent = _audioService.currentTrack?.id == station.stationuuid;
            final isPlaying = isCurrent && _audioService.isPlaying;
            final isLoading = isCurrent && _audioService.isLoading;

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A2540), Color(0xFF031B33)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 28,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Avatar Favicon or Flag
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceLow,
                        border: Border.all(color: AppColors.gold, width: 2.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.35),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: station.favicon.isNotEmpty
                            ? Image.network(
                                station.favicon,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(
                                    station.flagEmoji,
                                    style: const TextStyle(fontSize: 38),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  station.flagEmoji,
                                  style: const TextStyle(fontSize: 38),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Name
                    Text(
                      station.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Country & State
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.place_rounded, size: 14, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          station.displaySubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDetailChip(
                          icon: Icons.wifi_tethering_rounded,
                          label: 'Live 24/7',
                          color: const Color(0xFF4ADE80),
                        ),
                        const SizedBox(width: 8),
                        _buildDetailChip(
                          icon: Icons.speed_rounded,
                          label: station.bitrate > 0 ? '${station.bitrate} kbps' : '128 kbps',
                          color: AppColors.goldLight,
                        ),
                        const SizedBox(width: 8),
                        _buildDetailChip(
                          icon: Icons.audiotrack_rounded,
                          label: station.codec.isNotEmpty ? station.codec : 'MP3',
                          color: Colors.lightBlueAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tags
                    if (station.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Mada: ${station.tags.replaceAll(",", " • ")}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.65),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 22),

                    // Main Play/Pause Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AppHaptics.mediumImpact();
                          _togglePlayStation(station);
                        },
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E0A3C)),
                              )
                            : Icon(
                                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                size: 24,
                                color: const Color(0xFF1E0A3C),
                              ),
                        label: Text(
                          isPlaying
                              ? 'Sitisha Utangazaji'
                              : (isCurrent ? 'Endelea Kusikiliza' : 'Sikiliza Moja kwa Moja'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E0A3C),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: AppColors.gold.withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Secondary action buttons
                    Row(
                      children: [
                        if (isPlaying)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                AppHaptics.lightImpact();
                                _audioService.stop();
                              },
                              icon: const Icon(Icons.stop_rounded, color: Colors.redAccent, size: 18),
                              label: const Text('Funga Redio', style: TextStyle(color: Colors.redAccent)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        if (isPlaying) const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Funga Maelezo', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
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

  Widget _buildDetailChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<RadioStation> _getActiveStationList() {
    switch (_selectedTab) {
      case 'all':
        return _allStations;
      case 'afrogospel':
        return _afroGospelRadios;
      case 'tanzania':
        return _tzGospelRadios;
      case 'global':
        return _globalGospelRadios;
      case 'news':
        return _newsRadios;
      case 'search':
        return _searchResults;
      default:
        return _allStations;
    }
  }

  bool _isCurrentTabLoading() {
    switch (_selectedTab) {
      case 'all':
        return _isLoadingAll && _allStations.isEmpty;
      case 'afrogospel':
        return _isLoadingAfro && _afroGospelRadios.isEmpty;
      case 'tanzania':
        return _isLoadingTz && _tzGospelRadios.isEmpty;
      case 'global':
        return _isLoadingGlobal && _globalGospelRadios.isEmpty;
      case 'news':
        return _isLoadingNews && _newsRadios.isEmpty;
      case 'search':
        return _isSearching;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStations = _getActiveStationList();
    final isLoading = _isCurrentTabLoading();
    final currentTabInfo = _tabs.firstWhere(
      (t) => t['id'] == _selectedTab,
      orElse: () => _tabs[0],
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadAllStations,
          color: AppColors.gold,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Liturgical App Bar Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                        tooltip: 'Rudi',
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFB81D24)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.radio_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Radio za Mtandaoni Live',
                              style: AppTypography.titleMedium(color: AppColors.textPrimary),
                            ),
                            Text(
                              'Afro Gospel, Injili TZ & Habari za Ulimwengu',
                              style: AppTypography.caption(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Station counter chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${activeStations.length} Radio',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 1,000+ Stations All Directory Banner & Genre Chips
              if (_selectedTab == 'all')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A2540), Color(0xFF0F52BA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 16,
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
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.public_rounded, color: AppColors.goldLight, size: 24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Text(
                                          'MTANDAO WA REDIO ZA INJILI',
                                          style: TextStyle(
                                            color: AppColors.goldLight,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(Icons.bolt_rounded, color: AppColors.gold, size: 14),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Vituo 1000+ vya Injili Moja kwa Moja',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sikiliza nyimbo za sifa, kuabudu na neno la uzima saa 24/7:',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Quick genre tags with guaranteed dark high-contrast ink
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _genreChips.map((chip) {
                                final isSelected = _selectedGenreTag == chip['id'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    label: Text(chip['label']!),
                                    backgroundColor: isSelected ? AppColors.gold : Colors.white,
                                    labelStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0A2540),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isSelected ? AppColors.gold : const Color(0xFFD8E6F8),
                                        width: 1.2,
                                      ),
                                    ),
                                    onPressed: () => _filterByGenre(chip['id']!),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Afro Gospel Highlights Banner
              if (_selectedTab == 'afrogospel')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A2540), Color(0xFF0D52CD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withOpacity(0.45), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                            ),
                            child: const Center(
                              child: Text('🇳🇬', style: TextStyle(fontSize: 26)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'AFRO GOSPEL NIGERIA',
                                      style: TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.verified_rounded, color: AppColors.gold, size: 14),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Praiseworld, Nigerian Gospel & Gospotainment',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Nyimbo bora za kumsifu Mungu, Afrobeats za Injili 24/7',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Tabs Selector Bar
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 46,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _tabs.length,
                    itemBuilder: (context, idx) {
                      final tab = _tabs[idx];
                      final isSelected = _selectedTab == tab['id'];

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(tab['label']!),
                          selected: isSelected,
                          onSelected: (_) {
                            AppHaptics.selectionClick();
                            setState(() => _selectedTab = tab['id']!);
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Search Bar (Shown in search tab or available globally)
              if (_selectedTab == 'search')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _performSearch,
                            decoration: InputDecoration(
                              hintText: 'Tafuta kituo chochote (mf. Gospel, BBC, Nigeria)...',
                              hintStyle: AppTypography.bodySmall(color: AppColors.textMuted),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
                                onPressed: () => _performSearch(_searchController.text),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            'Afro Gospel',
                            'Nigeria Gospel',
                            'Radio Uhai',
                            'Radio Maria',
                            'BBC Swahili',
                            'DW News',
                            'Praise',
                            'Worship',
                          ].map((tag) {
                            return ActionChip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              backgroundColor: AppColors.surfaceLow,
                              side: BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onPressed: () {
                                _searchController.text = tag;
                                _performSearch(tag);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              // Category Title Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        currentTabInfo['title'] ?? 'Vituo vya Radio',
                        style: AppTypography.titleSmall(color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      if (isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                        ),
                    ],
                  ),
                ),
              ),

              // Station List or Empty State
              if (activeStations.isEmpty && !isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.radio_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            _selectedTab == 'search'
                                ? 'Andika jina la kituo na ubonyeze tafuta'
                                : 'Hakuna vituo vilivyopatikana kwa sasa',
                            style: AppTypography.bodySmall(color: AppColors.textSecondary),
                          ),
                          if (_selectedTab != 'search') ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _loadAllStations,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Jaribu Tena'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListenableBuilder(
                  listenable: _audioService,
                  builder: (context, _) {
                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 180 + MediaQuery.of(context).padding.bottom),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) {
                            final station = activeStations[idx];
                            final isCurrentTrack = _audioService.currentTrack?.id == station.stationuuid;
                            final isPlayingThis = isCurrentTrack && _audioService.isPlaying;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppCard(
                                backgroundColor: isCurrentTrack
                                    ? const Color(0xFF0F2644)
                                    : AppColors.surface,
                                borderColor: isCurrentTrack
                                    ? AppColors.gold
                                    : AppColors.border,
                                onTap: () => _handleStationTap(station),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Station Logo or Flag Avatar
                                    _buildStationAvatar(station, isCurrentTrack),
                                    const SizedBox(width: 14),

                                    // Station Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              if (station.category == 'afrogospel' || station.countryCode == 'NG')
                                                Container(
                                                  margin: const EdgeInsets.only(right: 6),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withOpacity(0.18),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                                                  ),
                                                  child: const Text(
                                                    'AFRO GOSPEL',
                                                    style: TextStyle(
                                                      color: AppColors.primaryLight,
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              if (station.category == 'news')
                                                Container(
                                                  margin: const EdgeInsets.only(right: 6),
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueAccent.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'HABARI',
                                                    style: TextStyle(
                                                      color: Colors.lightBlueAccent,
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              Expanded(
                                                child: Text(
                                                  station.name,
                                                  style: TextStyle(
                                                    color: isCurrentTrack ? Colors.white : AppColors.textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            station.displaySubtitle,
                                            style: TextStyle(
                                              color: isCurrentTrack ? Colors.white70 : AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (station.tags.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              station.tags.replaceAll(',', ' • '),
                                              style: TextStyle(
                                                color: isCurrentTrack ? AppColors.gold : AppColors.textSecondary,
                                                fontSize: 10,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Play / Pause Icon Button
                                    GestureDetector(
                                      onTap: () => _togglePlayStation(station),
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          gradient: isCurrentTrack
                                              ? const LinearGradient(
                                                  colors: [AppColors.gold, Color(0xFFFFA500)],
                                                )
                                              : null,
                                          color: isCurrentTrack ? null : AppColors.surfaceLow,
                                          shape: BoxShape.circle,
                                          boxShadow: isPlayingThis
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.gold.withOpacity(0.4),
                                                    blurRadius: 10,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          isPlayingThis
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: isCurrentTrack ? const Color(0xFF1E0A3C) : AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: activeStations.length,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationAvatar(RadioStation station, bool isCurrent) {
    if (station.favicon.isNotEmpty && station.favicon.startsWith('http')) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.gold.withOpacity(0.15) : AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? AppColors.gold : AppColors.border,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.network(
            station.favicon,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(station, isCurrent),
          ),
        ),
      );
    }
    return _buildFallbackAvatar(station, isCurrent);
  }

  Widget _buildFallbackAvatar(RadioStation station, bool isCurrent) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrent
              ? [const Color(0xFF0D52CD), const Color(0xFF0A2540)]
              : [AppColors.surfaceLow, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppColors.gold : AppColors.border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: Text(
          station.flagEmoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
