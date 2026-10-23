import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/church_audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_card.dart';
import '../../media/presentation/now_playing_screen.dart';

class ChoirSongItem {
  final String id;
  final String title;
  final String choir;
  final String album;
  final String key;
  final String tempo;
  final String duration;
  final String lyrics;
  final String audioUrl;
  final String imagePath;
  final bool isPortalUpload;

  const ChoirSongItem({
    required this.id,
    required this.title,
    required this.choir,
    required this.album,
    required this.key,
    required this.tempo,
    required this.duration,
    required this.lyrics,
    required this.audioUrl,
    this.imagePath = 'assets/images/zion_worship_choir_1788577423671.jpg',
    this.isPortalUpload = false,
  });
}

class ChoirScreen extends StatefulWidget {
  const ChoirScreen({super.key});

  @override
  State<ChoirScreen> createState() => _ChoirScreenState();
}

class _ChoirScreenState extends State<ChoirScreen> {
  final ChurchAudioService _audioService = ChurchAudioService();
  late List<ChoirSongItem> _songs;
  Timer? _syncTimer;

  static const List<ChoirSongItem> _defaultSongs = [
    ChoirSongItem(
      id: 'choir-song-1',
      title: 'Mungu Wetu Yu Mwaminifu',
      choir: 'Kwaya ya Galilaya',
      album: 'Sayuni Inang\'aa Vol. 1',
      key: 'Key ya G',
      tempo: '92 BPM',
      duration: '05:12',
      audioUrl: 'https://stream.zeno.fm/4v4e91y9sm8uv',
      imagePath: 'assets/images/zion_worship_choir_1788577423671.jpg',
      lyrics: '''(Ubeti wa 1)
Katika mapito na dhoruba za dunia,
Mungu wetu yu mwaminifu daima.
Hatuachi, hatupungukii,
Mkono wake unatushika kwa amani.

(Kiitikio)
Sayuni inashangilia, Sayuni inaimba,
Mfalme wetu ametamalaki hekaluni!
Aleluya, Aleluya,
Sifa na adhama ni zake milele!

(Ubeti wa 2)
Mataifa yataona mwangaza wa Sayuni,
Wafalme watasujudu mbele za jina lake.
Hakuna giza litakaloshinda,
Nuru ya Kristo inawaka milele yote!''',
    ),
    ChoirSongItem(
      id: 'choir-song-2',
      title: 'Nitalisifu Jina Lako Bwana',
      choir: 'Sayuni Praise & Worship Team',
      album: 'Ibada ya Uamsho Live',
      key: 'Key ya D',
      tempo: '115 BPM',
      duration: '06:40',
      audioUrl: 'https://stream.zeno.fm/h2f9g3m19t8uv',
      imagePath: 'assets/images/church_youth_fellowship.jpg',
      lyrics: '''(Ubeti wa 1)
Kutoka mawio ya jua hata machweo yake,
Jina la Bwana linastahili kusifiwa.
Yeye ni mwema, fadhili zake ni za milele,
Wenye haki wanamwabudu kwa furaha.

(Kiitikio)
Wewe ni Mkuu, Wewe ni Mwema,
Hakuna mwingine kama Wewe Sayuni!
Umetenda makuu mioyoni mwetu,
Tunainua mikono yetu kukutukuza!

(Ubeti wa 2)
Milima na mabonde vishangilie,
Miti ya msituni ipige makofi mbele zako.
Wewe ndiye mwamba wetu na ngao yetu!''',
    ),
    ChoirSongItem(
      id: 'choir-song-3',
      title: 'Upendo wa Kristo Ni Mkuu',
      choir: 'Kwaya ya Wanawake (Wamama)',
      album: 'Matendo ya Imani',
      key: 'Key ya C',
      tempo: '85 BPM',
      duration: '04:45',
      audioUrl: 'https://stream.zeno.fm/3g28669e4ehvv',
      imagePath: 'assets/images/church_women_fellowship.jpg',
      lyrics: '''(Ubeti wa 1)
Upendo wake Mungu hauna kifani,
Alimtuma Mwanae wa pekee msalabani.
Akatukomboa kutoka dhambini,
Tukafanyika wana wa Sayuni.

(Kiitikio)
Upendo wa ajabu, pendo lisilo na mwisho,
Tutaishi ndani yake daima.
Hata mawimbi yakipiga sana,
Pendo lake halitapoa kamwe!

(Ubeti wa 2)
Wamama wanainuka kuombea vizazi,
Familia zinasimama katika amani ya Kristo.''',
    ),
    ChoirSongItem(
      id: 'choir-song-4',
      title: 'Ondoka Uangaze Sayuni',
      choir: 'Kwaya Kuu ya Sayuni',
      album: 'Sayuni Inang\'aa Vol. 1',
      key: 'Key ya F',
      tempo: '100 BPM',
      duration: '05:30',
      audioUrl: 'https://stream.zeno.fm/w74w7e91sm8uv',
      imagePath: 'assets/images/zion_worship_choir_1788577423671.jpg',
      lyrics: '''(Ubeti wa 1)
Ondoka uangaze, kwa kuwa nuru yako imekuja,
Na utukufu wa Bwana umekuzukia.
Tazama, giza litaifunika dunia,
Na giza nene litazifunika kabila za watu;
Bali Bwana atakuzukia wewe!

(Kiitikio)
Sayuni inuke! Sayuni ing'ae!
Nuru ya Mungu iko juu yako!
Mataifa watatembea kwa mwangaza wako,
Na wafalme kwa mwangaza wa mapambazuko yako!''',
    ),
    ChoirSongItem(
      id: 'choir-song-5',
      title: 'Vijana wa Sayuni Msimame',
      choir: 'Kwaya ya Vijana (Youth Fellowship)',
      album: 'Kizazi cha Ushindi',
      key: 'Key ya E',
      tempo: '120 BPM',
      duration: '04:18',
      audioUrl: 'https://stream.zeno.fm/4d4z49m9sm8uv',
      imagePath: 'assets/images/church_youth_fellowship.jpg',
      lyrics: '''(Ubeti wa 1)
Huu ni wakati wa vijana kusimama,
Kutangaza neno na utakatifu wa Bwana.
Hatutakubali kutekwa na ulimwengu,
Tumechaguliwa kuwa nuru na chumvi ya dunia!

(Kiitikio)
Vijana wa Sayuni, simameni imara!
Neno la Mungu liwe nguvu yetu!
Aleluya, Ushindi ni wetu katika jina la Yesu!''',
    ),
    ChoirSongItem(
      id: 'choir-song-6',
      title: 'Wazee na Wababa Katika Sala',
      choir: 'Umoja wa Wanaume wa Sayuni',
      album: 'Misingi ya Imani',
      key: 'Key ya A',
      tempo: '88 BPM',
      duration: '04:55',
      audioUrl: 'https://stream.zeno.fm/4v4e91y9sm8uv',
      imagePath: 'assets/images/church_men_fellowship.jpg',
      lyrics: '''(Ubeti wa 1)
Wababa wanasimama kama makuhani wa nyumba,
Wakiinua mikono mitakatifu bila hasira wala mashaka.
Ulinzi wa Bwana uzingire vizazi vyetu,
Baraka za Ibrahimu zitembee ndani ya nyumba zetu!

(Kiitikio)
Mungu wa Sayuni atulinde,
Mungu wa Baba zetu atubariki,
Kutoka kizazi hata kizazi!''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _songs = List.from(_defaultSongs);
    _loadCustomAndSyncedSongs();
    _syncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _loadCustomAndSyncedSongs();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCustomAndSyncedSongs() async {
    try {
      final List<ChoirSongItem> portalSongs = [];

      // 1. Read from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final rawStorage = prefs.getString('zion_portal_choir_songs') ??
          prefs.getString('flutter.zion_portal_choir_songs');
      if (rawStorage != null && rawStorage.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawStorage);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map) {
                portalSongs.add(_parseSongMap(Map<String, dynamic>.from(item)));
              }
            }
          }
        } catch (_) {}
      }

      // 2. Fetch from Web Portal Vite Sync API
      final urls = [
        'http://localhost:5173/api/sync/choir-songs',
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          'http://10.0.2.2:5173/api/sync/choir-songs',
      ];

      for (final u in urls) {
        try {
          final res = await http
              .get(Uri.parse(u))
              .timeout(const Duration(milliseconds: 1500));
          if (res.statusCode == 200) {
            final decoded = jsonDecode(res.body);
            if (decoded is List) {
              for (final item in decoded) {
                if (item is Map) {
                  final parsed = _parseSongMap(Map<String, dynamic>.from(item));
                  if (!portalSongs.any((s) => s.id == parsed.id)) {
                    portalSongs.add(parsed);
                  }
                }
              }
            }
            break;
          }
        } catch (_) {}
      }

      if (portalSongs.isNotEmpty && mounted) {
        final existingIds = portalSongs.map((s) => s.id).toSet();
        final combined = [
          ...portalSongs,
          ..._defaultSongs.where((s) => !existingIds.contains(s.id)),
        ];
        setState(() {
          _songs = combined;
        });
      }
    } catch (e) {
      debugPrint('Error syncing choir songs: $e');
    }
  }

  ChoirSongItem _parseSongMap(Map<String, dynamic> item) {
    return ChoirSongItem(
      id: item['id']?.toString() ??
          'song-${DateTime.now().millisecondsSinceEpoch}',
      title: item['title']?.toString() ?? 'Wimbo Mpya wa Kwaya',
      choir: item['choirName']?.toString() ??
          item['choir']?.toString() ??
          'Kwaya ya Sayuni',
      album: 'Sayuni Worship Live',
      key: item['key']?.toString() ?? 'Key G',
      tempo: item['tempo']?.toString() ?? '100 BPM',
      duration: item['duration']?.toString() ?? '04:30',
      lyrics: item['lyrics']?.toString() ?? '',
      audioUrl: item['audioDemoUrl']?.toString() ??
          item['audioUrl']?.toString() ??
          'https://stream.zeno.fm/4v4e91y9sm8uv',
      imagePath: 'assets/images/zion_worship_choir_1788577423671.jpg',
      isPortalUpload: true,
    );
  }

  void _playSong(ChoirSongItem song) {
    AppHaptics.mediumImpact();
    if (_audioService.currentTrack?.id == song.id) {
      _audioService.togglePlayPause();
    } else {
      NowPlayingScreen.open(context);
      _audioService.playTrack(
        id: song.id,
        title: song.title,
        subtitle: '${song.choir} • ${song.album}',
        audioUrl: song.audioUrl,
        imageUrl: song.imagePath,
      );
    }
  }

  void _openSongDetails(ChoirSongItem song) {
    AppHaptics.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(song.choir,
                              style: AppTypography.caption(
                                  color: AppColors.primary)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(song.title,
                        style: AppTypography.headlineMedium(
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.goldContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(song.key,
                              style: AppTypography.caption(
                                  color: AppColors.onGoldContainer)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(song.tempo,
                              style: AppTypography.caption(
                                  color: AppColors.primary)),
                        ),
                        const SizedBox(width: 8),
                        Text(song.duration,
                            style: AppTypography.caption(
                                color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Audio Play Action Button
                    ListenableBuilder(
                      listenable: _audioService,
                      builder: (context, _) {
                        final isPlayingThis =
                            _audioService.currentTrack?.id == song.id &&
                                _audioService.isPlaying;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _playSong(song);
                            },
                            icon: Icon(isPlayingThis
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded),
                            label: Text(
                              isPlayingThis
                                  ? 'Sitisha Wimbo (Inacheza...)'
                                  : 'Sikiliza Wimbo Huu',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Maneno ya Wimbo (Lyrics)',
                          style: AppTypography.titleMedium(
                              color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded,
                              size: 18, color: AppColors.primary),
                          tooltip: 'Shiriki Maneno',
                          onPressed: () {
                            Share.share(
                                '${song.title} - ${song.choir}\n\n${song.lyrics}\n\nKutoka App ya Sayuni Church.');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        song.lyrics,
                        style: AppTypography.bodyLarge(
                                color: AppColors.textPrimary)
                            .copyWith(height: 1.8),
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
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = 180.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Kwaya & Nyimbo za Sayuni',
          style: AppTypography.titleMedium(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sasisha Nyimbo',
            onPressed: () {
              AppHaptics.lightImpact();
              _loadCustomAndSyncedSongs();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _audioService,
        builder: (context, _) {
          return ListView(
            padding: EdgeInsets.only(
                left: 16, right: 16, top: 12, bottom: bottomInset),
            physics: const BouncingScrollPhysics(),
            children: [
              // Choir Ministry Photo Banner
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.asset(
                        'assets/images/zion_worship_choir_1788577423671.jpg',
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 140,
                          color: AppColors.surfaceContainer,
                          child: const Center(
                            child: Icon(Icons.music_note_rounded,
                                size: 48, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Huduma ya Sifa na Nyimbo',
                                style: AppTypography.titleMedium(
                                    color: AppColors.textPrimary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.goldContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Nyimbo ${_songs.length}',
                                  style: AppTypography.caption(
                                      color: AppColors.onGoldContainer),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kwaya Kuu ya Sayuni, Kwaya ya Galilaya, Praise Team, Wamama na Vijana. Sikiliza nyimbo zote hapa na udhibiti sauti moja kwa moja kwenye lock screen.',
                            style: AppTypography.bodyMedium(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nyimbo za Kwaya za Sayuni',
                    style:
                        AppTypography.titleMedium(color: AppColors.textPrimary),
                  ),
                  Text(
                    'Bofya kusikiliza',
                    style: AppTypography.caption(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ..._songs.map((song) {
                final isCurrent = _audioService.currentTrack?.id == song.id;
                final isPlaying = isCurrent && _audioService.isPlaying;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => _openSongDetails(song),
                    padding: const EdgeInsets.all(14),
                    borderColor:
                        isCurrent ? AppColors.primary : AppColors.border,
                    child: Row(
                      children: [
                        // Group/Choir Thumbnail with Play/Pause Overlay
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                song.imagePath,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 54,
                                  height: 54,
                                  color: AppColors.surfaceContainer,
                                  child: const Icon(Icons.music_note_rounded,
                                      color: AppColors.primary),
                                ),
                              ),
                            ),
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => _playSong(song),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      song.title,
                                      style: AppTypography.labelLarge(
                                        color: isCurrent
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isPlaying)
                                    const Icon(Icons.graphic_eq_rounded,
                                        color: AppColors.primary, size: 18),
                                ],
                              ),
                              if (song.isPortalUpload) ...[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Wimbo Mpya • Kwaya Portal',
                                    style: AppTypography.caption(
                                            color: AppColors.primary)
                                        .copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 3),
                              Text(
                                '${song.choir} • ${song.key}',
                                style: AppTypography.caption(
                                    color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.duration,
                                style: AppTypography.caption(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.lyrics_rounded,
                              color: AppColors.textMuted, size: 20),
                          tooltip: 'Angalia Maneno',
                          onPressed: () => _openSongDetails(song),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
