import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/media/media_models.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/services/church_audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';

const String _kLogoAsset = 'assets/images/zion_logo.png';
const String _kFavoritesKey = 'zion_media_favorites';
const String _kLoud = 'SAYUNI MEDIA PLAYER';

const Color _ink = Color(0xFF050B16);
const Color _inkSoft = Color(0xFF0B1425);

/// Full-screen Now Playing route.
///
/// Owns no player: every control delegates to [ChurchAudioService], which talks
/// to the single background-capable `ZionAudioHandler`. Popping this route
/// therefore never interrupts audio.
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const NowPlayingScreen(),
        ),
      );

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final ChurchAudioService _audio = ChurchAudioService();
  Set<String> _favorites = <String>{};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Set<String> ids = <String>{...?prefs.getStringList(_kFavoritesKey)};
      if (mounted) setState(() => _favorites = ids);
    } catch (_) {
      // Favourites are a convenience; a storage failure must not break playback.
    }
  }

  Future<void> _toggleFavorite(AudioTrack track) async {
    AppHaptics.lightImpact();
    final Set<String> next = Set<String>.from(_favorites);
    if (!next.remove(track.id)) next.add(track.id);
    setState(() => _favorites = next);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFavoritesKey, next.toList());
    } catch (_) {
      // Ignored on purpose, see [_loadFavorites].
    }
  }

  void _share(AudioTrack track) {
    AppHaptics.selectionClick();
    final StringBuffer sb = StringBuffer(track.title);
    if (track.artist.isNotEmpty) sb.write(' - ${track.artist}');
    sb.write('\n${track.category.label}');
    if (track.url.trim().isNotEmpty) sb.write('\n${track.url.trim()}');
    try {
      Share.share(sb.toString(), subject: track.title);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kushiriki hakuwezekana kwenye kifaa hiki.')),
        );
      }
    }
  }

  void _openLibrary() {
    AppHaptics.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _inkSoft,
      showDragHandle: true,
      isScrollControlled: true,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.84),
      builder: (BuildContext context) => _MediaLibrarySheet(
        audio: _audio,
        initialCategory: _audio.currentTrack?.category,
      ),
    );
  }

  void _openQueue() {
    AppHaptics.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _inkSoft,
      showDragHandle: true,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.66),
      builder: (BuildContext context) => _QueueSheet(audio: _audio),
    );
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: AnimatedBuilder(
        animation: _audio,
        builder: (BuildContext context, Widget? child) {
          final PlayerSnapshot snap = _audio.snapshot;
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[_inkSoft, _ink],
              ),
            ),
            child: SafeArea(
              child: snap.hasTrack
                  ? _PlayerBody(
                      snap: snap,
                      audio: _audio,
                      isFavorite: _favorites.contains(snap.track!.id),
                      onFavorite: () => _toggleFavorite(snap.track!),
                      onShare: () => _share(snap.track!),
                      onQueue: _openQueue,
                      onLibrary: _openLibrary,
                    )
                  : _EmptyPlayer(onLibrary: _openLibrary),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.snap,
    required this.audio,
    required this.isFavorite,
    required this.onFavorite,
    required this.onShare,
    required this.onQueue,
    required this.onLibrary,
  });

  final PlayerSnapshot snap;
  final ChurchAudioService audio;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onQueue;
  final VoidCallback onLibrary;

  @override
  build(BuildContext context) {
    final AudioTrack track = snap.track!;
    return Column(
      children: <Widget>[
        _TopBar(onQueue: onQueue, onLibrary: onLibrary),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 2, 22, 10),
            child: Column(
              children: <Widget>[
                _Artwork(
                    track: track, buffering: snap.buffering && !snap.failed),
                const SizedBox(height: 20),
                _LiveBadge(isLive: snap.isLive),
                const SizedBox(height: 10),
                Text(
                  track.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  track.richSubtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (snap.failed)
                  _ErrorPanel(message: snap.errorMessage, onRetry: audio.retry)
                else
                  _ProgressBlock(snap: snap, audio: audio),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
        _TransportBar(
          snap: snap,
          audio: audio,
          isFavorite: isFavorite,
          onFavorite: onFavorite,
          onShare: onShare,
          onQueue: onQueue,
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onQueue, required this.onLibrary});

  final VoidCallback onQueue;
  final VoidCallback onLibrary;

  @override
  build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          onPressed: () {
            AppHaptics.lightImpact();
            Navigator.of(context).maybePop();
          },
          tooltip: 'Funga (sauti inaendelea)',
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textWhite, size: 30),
        ),
        const Expanded(
          child: Text(
            _kLoud,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9FB6D4),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        IconButton(
          onPressed: onLibrary,
          tooltip: 'Radio, Kwaya, Tenzi, Mahubiri',
          icon: const Icon(Icons.library_music_rounded,
              color: AppColors.primaryLight, size: 24),
        ),
        IconButton(
          onPressed: onQueue,
          tooltip: 'Orodha ya uchezaji',
          icon: const Icon(Icons.queue_music_rounded,
              color: AppColors.primaryLight, size: 24),
        ),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.track, required this.buffering});

  final AudioTrack track;
  final bool buffering;

  @override
  build(BuildContext context) {
    final String? asset = track.artworkAsset;
    final String? remote = track.artworkUrl;
    Widget image;
    if (remote != null && remote.isNotEmpty) {
      image = Image.network(
        remote,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            _logo(),
      );
    } else if (asset != null && asset.isNotEmpty) {
      image = Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            _logo(),
      );
    } else {
      image = _logo();
    }
    return SizedBox(
      width: 228,
      height: 228,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.32),
                    blurRadius: 44,
                    spreadRadius: 4),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.goldLight.withOpacity(0.5), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: image,
          ),
          if (buffering)
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: AppColors.primaryLight),
            ),
        ],
      ),
    );
  }

  Widget _logo() => Transform.scale(
        scale: 1.32,
        child: Image.asset(_kLogoAsset, fit: BoxFit.cover),
      );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.isLive});

  final bool isLive;

  @override
  build(BuildContext context) {
    if (!isLive) return const SizedBox(height: 2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF87171), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.circle_rounded, size: 8, color: Color(0xFFF87171)),
          SizedBox(width: 6),
          Text('LIVE',
              style: TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4)),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String? message;
  final Future<void> Function() onRetry;

  @override
  build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withOpacity(0.38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF87171).withOpacity(0.6)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.wifi_off_rounded,
              color: Color(0xFFFCA5A5), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              (message == null || message!.isEmpty)
                  ? 'Mtiririko umekwama. Angalia mtandao kisha ujaribu tena.'
                  : message!,
              style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              AppHaptics.mediumImpact();
              onRetry();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Jaribu Tena'),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFFDE68A)),
          ),
        ],
      ),
    );
  }
}

class _ProgressBlock extends StatefulWidget {
  const _ProgressBlock({required this.snap, required this.audio});

  final PlayerSnapshot snap;
  final ChurchAudioService audio;

  @override
  State<_ProgressBlock> createState() => _ProgressBlockState();
}

class _ProgressBlockState extends State<_ProgressBlock> {
  double? _dragging;

  @override
  build(BuildContext context) {
    if (widget.snap.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.cell_tower_rounded,
                color: AppColors.primaryLight, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Redio ya moja kwa moja - hakuna kuruka nyuma',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    final int total = widget.snap.duration.inMilliseconds;
    return StreamBuilder<Duration>(
      stream: widget.audio.positionStream,
      initialData: widget.snap.position,
      builder: (BuildContext context, AsyncSnapshot<Duration> position) {
        final Duration current = _dragging == null
            ? (position.data ?? widget.snap.position)
            : Duration(milliseconds: _dragging!.toInt());
        final double max = total <= 0 ? 1 : total.toDouble();
        final double value = current.inMilliseconds.clamp(0, max).toDouble();
        return Column(
          children: <Widget>[
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primaryLight,
                inactiveTrackColor: Colors.white.withOpacity(0.18),
                thumbColor: AppColors.textWhite,
                overlayColor: AppColors.primaryLight.withOpacity(0.16),
              ),
              child: Slider(
                value: value,
                max: max,
                onChanged: total <= 0
                    ? null
                    : (double next) => setState(() => _dragging = next),
                onChangeEnd: total <= 0
                    ? null
                    : (double next) {
                        final Duration target =
                            Duration(milliseconds: next.toInt());
                        setState(() => _dragging = null);
                        widget.audio.seek(target);
                      },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(_clock(current), style: _timeStyle),
                  Text(total <= 0 ? '--:--' : _clock(widget.snap.duration),
                      style: _timeStyle),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static const TextStyle _timeStyle = TextStyle(
    color: Color(0xFFCBD5E1),
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
  );

  static String _clock(Duration value) {
    final String m = value.inMinutes.toString().padLeft(2, '0');
    final String s = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _TransportBar extends StatelessWidget {
  const _TransportBar({
    required this.snap,
    required this.audio,
    required this.isFavorite,
    required this.onFavorite,
    required this.onShare,
    required this.onQueue,
  });

  final PlayerSnapshot snap;
  final ChurchAudioService audio;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onQueue;

  @override
  build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _RoundButton(
                icon: Icons.skip_previous_rounded,
                label: 'Iliyotangulia',
                size: 52,
                iconSize: 28,
                onTap: snap.hasPrevious ? audio.playPrevious : null,
              ),
              _RoundButton(
                icon: snap.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                label: snap.playing ? 'Simamisha muda' : 'Endelea',
                size: 78,
                iconSize: 42,
                primary: true,
                busy: snap.buffering && !snap.failed,
                onTap: audio.togglePlayPause,
              ),
              _RoundButton(
                icon: Icons.skip_next_rounded,
                label: 'Inayofuata',
                size: 52,
                iconSize: 28,
                onTap: snap.hasNext ? audio.playNext : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _RoundButton(
                icon: isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: 'Upendavo',
                size: 42,
                iconSize: 21,
                tint: isFavorite ? const Color(0xFFF87171) : null,
                onTap: onFavorite,
              ),
              _RoundButton(
                icon: Icons.ios_share_rounded,
                label: 'Shiriki',
                size: 42,
                iconSize: 21,
                onTap: onShare,
              ),
              _RoundButton(
                icon: Icons.stop_rounded,
                label: 'Simamisha',
                size: 42,
                iconSize: 21,
                onTap: audio.stop,
              ),
              _RoundButton(
                icon: Icons.queue_music_rounded,
                label: 'Orodha (${snap.queueLength})',
                size: 42,
                iconSize: 21,
                onTap: onQueue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.iconSize,
    required this.onTap,
    this.primary = false,
    this.busy = false,
    this.tint,
  });

  final IconData icon;
  final String label;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;
  final bool primary;
  final bool busy;
  final Color? tint;

  @override
  build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                AppHaptics.selectionClick();
                onTap!();
              },
        borderRadius: BorderRadius.circular(size),
        child: SizedBox(
          width: size,
          height: size + 18,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: primary
                      ? const LinearGradient(
                          colors: <Color>[
                            AppColors.primaryLight,
                            AppColors.primary
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: primary ? null : Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: primary
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.16),
                    width: 1,
                  ),
                ),
                child: busy
                    ? SizedBox(
                        width: iconSize * 0.7,
                        height: iconSize * 0.7,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2.6, color: Colors.white),
                      )
                    : Icon(icon,
                        size: iconSize,
                        color: tint ??
                            (primary ? Colors.white : AppColors.primaryLight)),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: onTap == null
                      ? Colors.white.withOpacity(0.28)
                      : Colors.white.withOpacity(0.62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPlayer extends StatelessWidget {
  const _EmptyPlayer({required this.onLibrary});

  final VoidCallback onLibrary;

  @override
  build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Transform.scale(
              scale: 1.3,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.goldLight.withOpacity(0.45), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(_kLogoAsset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 34),
            const Text(
              'Hakuna kinachochezada sasa',
              style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 19,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Chagua kituo cha redio, wimbo wa kwaya, tenzi au hubsiri ili sauti ianze. Itacheza hata ukifunga app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.66),
                  fontSize: 13,
                  height: 1.45),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onLibrary,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Fungua maktaba ya sauti'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet({required this.audio});

  final ChurchAudioService audio;

  @override
  Widget build(BuildContext context) {
    final List<AudioTrack> queue = audio.queueTracks;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 4, 8, 10),
          child: Text(
            'ORODHA YA UCHEZAJI',
            style: TextStyle(
                color: Color(0xFF9FB6D4),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4),
          ),
        ),
        if (queue.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Hakuna kwenye orodha bado.',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        for (int i = 0; i < queue.length; i++)
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              child: Text((i + 1).toString(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            title: Text(
              queue[i].title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: i == audio.queueIndex
                    ? AppColors.primaryLight
                    : AppColors.textWhite,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              queue[i].category.label + (queue[i].isLive ? ' - LIVE' : ''),
              style: const TextStyle(color: Color(0xFF8FA6C4), fontSize: 11.5),
            ),
            trailing: i == audio.queueIndex
                ? const Icon(Icons.equalizer_rounded,
                    color: AppColors.primaryLight, size: 20)
                : null,
            onTap: () {
              Navigator.of(context).pop();
              AppHaptics.mediumImpact();
              audio.playQueue(queue, startIndex: i);
            },
          ),
      ],
    );
  }
}

class _MediaLibrarySheet extends StatefulWidget {
  const _MediaLibrarySheet(
      {required this.audio, required this.initialCategory});

  final ChurchAudioService audio;
  final MediaCategory? initialCategory;

  @override
  State<_MediaLibrarySheet> createState() => _MediaLibrarySheetState();
}

class _MediaLibrarySheetState extends State<_MediaLibrarySheet> {
  late MediaCategory _category = widget.initialCategory ?? MediaCategory.radio;
  List<AudioTrack> _tracks = const <AudioTrack>[];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final SayuniMediaRepository repo = SayuniMediaRepository.instance;
      final List<AudioTrack> result = _category == MediaCategory.radio
          ? await repo.radioStations()
          : await repo.tracksIn(_category);
      if (!mounted) return;
      setState(() {
        _tracks = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Kushindwa kupakia. Angalia mtandao wako.';
        _loading = false;
      });
    }
  }

  void _select(MediaCategory category) {
    if (category.id == _category.id) return;
    AppHaptics.selectionClick();
    setState(() => _category = category);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'MAKTABA YA SAUTI',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: <Widget>[
              for (final MediaCategory category in MediaCategory.playerSections)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category.label),
                    selected: category.id == _category.id,
                    onSelected: (bool _) => _select(category),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: category.id == _category.id
                          ? Colors.white
                          : const Color(0xFFCBD5E1),
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white.withOpacity(0.07),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF1E2E48)),
        Expanded(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryLight))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(_error!,
                              style: const TextStyle(
                                  color: Color(0xFFFCA5A5), fontSize: 13)),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Jaribu Tena'),
                          ),
                        ],
                      ),
                    )
                  : _tracks.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Hakuna sauti zilizopakiwa katika sehemu hii bado. Pakia faili ya sauti (mp3/m4a) kutoka ukurasa wa Usimamizi ili ionekane hapa.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFF9FB6D4),
                                  fontSize: 13,
                                  height: 1.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _tracks.length,
                          itemBuilder: (BuildContext context, int index) {
                            final AudioTrack track = _tracks[index];
                            return ListTile(
                              leading: const Icon(Icons.audiotrack_rounded,
                                  color: AppColors.primaryLight, size: 20),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                track.richSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Color(0xFF8FA6C4), fontSize: 11.5),
                              ),
                              trailing: track.isLive
                                  ? const Icon(Icons.cell_tower_rounded,
                                      color: Color(0xFFF87171), size: 18)
                                  : const Icon(Icons.play_arrow_rounded,
                                      color: AppColors.primaryLight),
                              onTap: () {
                                Navigator.of(context).pop();
                                AppHaptics.mediumImpact();
                                widget.audio
                                    .playQueue(_tracks, startIndex: index);
                              },
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
