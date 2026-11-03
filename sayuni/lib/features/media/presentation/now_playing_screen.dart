import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/media/media_models.dart';
import '../../../core/media/media_repository.dart';
import '../../../core/services/church_audio_service.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';

const String _kLogoAsset = 'assets/images/zion_logo.png';
const String _kFavoritesKey = 'zion_media_favorites';
const String _kLoud = 'SAYUNI MEDIA PLAYER';

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
  final ChurchThemeService _theme = ChurchThemeService();
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
    final bool isDark = _theme.isDarkMode;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      builder: (BuildContext context) => _MediaLibrarySheet(
        audio: _audio,
        initialCategory: _audio.currentTrack?.category,
      ),
    );
  }

  void _openQueue() {
    AppHaptics.mediumImpact();
    final bool isDark = _theme.isDarkMode;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.68),
      builder: (BuildContext context) => _QueueSheet(audio: _audio),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[_audio, _theme]),
      builder: (BuildContext context, Widget? child) {
        final PlayerSnapshot snap = _audio.snapshot;
        final bool isDark = _theme.isDarkMode;
        final Color primary = _theme.primaryColor;

        final Color bgTop =
            isDark ? const Color(0xFF0B1425) : const Color(0xFFF1F5F9);
        final Color bgBottom =
            isDark ? const Color(0xFF050B16) : const Color(0xFFFFFFFF);

        return Scaffold(
          backgroundColor: bgBottom,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[bgTop, bgBottom],
              ),
            ),
            child: SafeArea(
              child: snap.hasTrack
                  ? _PlayerBody(
                      snap: snap,
                      audio: _audio,
                      isDark: isDark,
                      primary: primary,
                      isFavorite: _favorites.contains(snap.track!.id),
                      onFavorite: () => _toggleFavorite(snap.track!),
                      onShare: () => _share(snap.track!),
                      onQueue: _openQueue,
                      onLibrary: _openLibrary,
                    )
                  : _EmptyPlayer(
                      audio: _audio,
                      isDark: isDark,
                      primary: primary,
                      onQueue: _openQueue,
                      onLibrary: _openLibrary,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.snap,
    required this.audio,
    required this.isDark,
    required this.primary,
    required this.isFavorite,
    required this.onFavorite,
    required this.onShare,
    required this.onQueue,
    required this.onLibrary,
  });

  final PlayerSnapshot snap;
  final ChurchAudioService audio;
  final bool isDark;
  final Color primary;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onQueue;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    final AudioTrack track = snap.track!;
    final Color titleColor =
        isDark ? AppColors.textWhite : const Color(0xFF0A2540);
    final Color subtitleColor =
        isDark ? AppColors.primaryLight : primary;

    return Column(
      children: <Widget>[
        _TopBar(
          isDark: isDark,
          primary: primary,
          onQueue: onQueue,
          onLibrary: onLibrary,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Column(
              children: <Widget>[
                _Artwork(
                  track: track,
                  buffering: snap.buffering && !snap.failed,
                  isDark: isDark,
                  primary: primary,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _LiveBadge(isLive: snap.isLive, isDark: isDark),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: primary.withOpacity(isDark ? 0.4 : 0.25)),
                      ),
                      child: Text(
                        track.category.label,
                        style: TextStyle(
                          color: isDark ? AppColors.primaryLight : primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  track.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  track.richSubtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (snap.failed)
                  _ErrorPanel(
                    message: snap.errorMessage,
                    onRetry: audio.retry,
                    isDark: isDark,
                  )
                else
                  _ProgressBlock(
                    snap: snap,
                    audio: audio,
                    isDark: isDark,
                    primary: primary,
                  ),
                const SizedBox(height: 14),
                // Quick Library Switcher Banner
                InkWell(
                  onTap: onLibrary,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF111C33)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.library_music_rounded,
                          size: 18,
                          color: isDark ? AppColors.primaryLight : primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Badili Kituo, Kwaya, Tenzi au Mahubiri',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF1E293B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _TransportBar(
          snap: snap,
          audio: audio,
          isDark: isDark,
          primary: primary,
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
  const _TopBar({
    required this.isDark,
    required this.primary,
    required this.onQueue,
    required this.onLibrary,
  });

  final bool isDark;
  final Color primary;
  final VoidCallback onQueue;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        isDark ? AppColors.textWhite : const Color(0xFF0A2540);
    final Color accentColor = isDark ? AppColors.primaryLight : primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              AppHaptics.lightImpact();
              Navigator.of(context).maybePop();
            },
            tooltip: 'Funga (sauti inaendelea)',
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: iconColor, size: 30),
          ),
          Expanded(
            child: Text(
              _kLoud,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF9FB6D4)
                    : const Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          IconButton(
            onPressed: onLibrary,
            tooltip: 'Maktaba: Radio, Kwaya, Tenzi, Mahubiri',
            icon: Icon(Icons.library_music_rounded,
                color: accentColor, size: 22),
          ),
          IconButton(
            onPressed: onQueue,
            tooltip: 'Orodha ya uchezaji',
            icon: Icon(Icons.queue_music_rounded,
                color: accentColor, size: 22),
          ),
        ],
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.track,
    required this.buffering,
    required this.isDark,
    required this.primary,
  });

  final AudioTrack track;
  final bool buffering;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final String? asset = track.artworkAsset;
    final String? remote = track.artworkUrl;
    Widget image;
    if (remote != null && remote.isNotEmpty) {
      image = Image.network(
        remote,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stack) => _logo(),
      );
    } else if (asset != null && asset.isNotEmpty) {
      image = Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stack) => _logo(),
      );
    } else {
      image = _logo();
    }
    return SizedBox(
      width: 176,
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: primary.withOpacity(isDark ? 0.30 : 0.16),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withOpacity(isDark ? 0.6 : 0.75),
                width: 2.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: image,
          ),
          if (buffering)
            SizedBox(
              width: 174,
              height: 174,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: isDark ? AppColors.goldLight : primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _logo() => Padding(
        padding: const EdgeInsets.all(14),
        child: Image.asset(_kLogoAsset, fit: BoxFit.contain),
      );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.isLive, required this.isDark});

  final bool isLive;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (!isLive) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withOpacity(isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: const Color(0xFFDC2626).withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.circle_rounded, size: 8, color: Color(0xFFEF4444)),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              color: isDark
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFB91C1C),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  final String? message;
  final Future<void> Function() onRetry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF7F1D1D).withOpacity(0.38)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFFF87171).withOpacity(0.6)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.wifi_off_rounded,
            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              (message == null || message!.isEmpty)
                  ? 'Mtiririko umekwama. Angalia mtandao kisha ujaribu tena.'
                  : message!,
              style: TextStyle(
                color: isDark ? AppColors.textWhite : const Color(0xFF7F1D1D),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              AppHaptics.mediumImpact();
              onRetry();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Jaribu Tena'),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? const Color(0xFFFDE68A) : const Color(0xFFB91C1C),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBlock extends StatefulWidget {
  const _ProgressBlock({
    required this.snap,
    required this.audio,
    required this.isDark,
    required this.primary,
  });

  final PlayerSnapshot snap;
  final ChurchAudioService audio;
  final bool isDark;
  final Color primary;

  @override
  State<_ProgressBlock> createState() => _ProgressBlockState();
}

class _ProgressBlockState extends State<_ProgressBlock> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDark;
    final Color primary = widget.primary;

    if (widget.snap.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.cell_tower_rounded,
              color: isDark ? AppColors.primaryLight : primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Matangazo ya moja kwa moja (Live Stream)',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.82)
                      : const Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final int total = widget.snap.duration.inMilliseconds;
    final Color timeColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

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
                activeTrackColor: isDark ? AppColors.primaryLight : primary,
                inactiveTrackColor: isDark
                    ? Colors.white.withOpacity(0.18)
                    : const Color(0xFFCBD5E1),
                thumbColor: isDark ? AppColors.textWhite : primary,
                overlayColor: primary.withOpacity(0.16),
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    _clock(current),
                    style: TextStyle(
                      color: timeColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    total <= 0 ? '--:--' : _clock(widget.snap.duration),
                    style: TextStyle(
                      color: timeColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

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
    required this.isDark,
    required this.primary,
    required this.isFavorite,
    required this.onFavorite,
    required this.onShare,
    required this.onQueue,
  });

  final PlayerSnapshot snap;
  final ChurchAudioService audio;
  final bool isDark;
  final Color primary;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A1222).withOpacity(0.85)
            : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _RoundButton(
                  icon: Icons.skip_previous_rounded,
                  label: 'Iliyopita',
                  size: 50,
                  iconSize: 26,
                  isDark: isDark,
                  primaryColor: primary,
                  onTap: snap.hasPrevious ? audio.playPrevious : null,
                ),
              ),
              Expanded(
                child: _RoundButton(
                  icon: snap.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: snap.playing ? 'Sitisha' : 'Cheza',
                  size: 68,
                  iconSize: 36,
                  isDark: isDark,
                  primaryColor: primary,
                  primary: true,
                  busy: snap.buffering && !snap.failed,
                  onTap: audio.togglePlayPause,
                ),
              ),
              Expanded(
                child: _RoundButton(
                  icon: Icons.skip_next_rounded,
                  label: 'Inayofuata',
                  size: 50,
                  iconSize: 26,
                  isDark: isDark,
                  primaryColor: primary,
                  onTap: snap.hasNext ? audio.playNext : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _RoundButton(
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: 'Pendwa',
                  size: 44,
                  iconSize: 21,
                  isDark: isDark,
                  primaryColor: primary,
                  tint: isFavorite ? const Color(0xFFEF4444) : null,
                  onTap: onFavorite,
                ),
              ),
              Expanded(
                child: _RoundButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Shiriki',
                  size: 44,
                  iconSize: 20,
                  isDark: isDark,
                  primaryColor: primary,
                  onTap: onShare,
                ),
              ),
              Expanded(
                child: _RoundButton(
                  icon: Icons.stop_rounded,
                  label: 'Komesha',
                  size: 44,
                  iconSize: 22,
                  isDark: isDark,
                  primaryColor: primary,
                  onTap: audio.stop,
                ),
              ),
              Expanded(
                child: _RoundButton(
                  icon: Icons.queue_music_rounded,
                  label: 'Orodha (${snap.queueLength})',
                  size: 44,
                  iconSize: 21,
                  isDark: isDark,
                  primaryColor: primary,
                  onTap: onQueue,
                ),
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
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
    this.primary = false,
    this.busy = false,
    this.tint,
  });

  final IconData icon;
  final String label;
  final double size;
  final double iconSize;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback? onTap;
  final bool primary;
  final bool busy;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final Color defaultIconColor = primary
        ? Colors.white
        : (isDark ? AppColors.primaryLight : primaryColor);
    final Color resolvedIconColor = enabled
        ? (tint ?? defaultIconColor)
        : (isDark
            ? Colors.white.withOpacity(0.28)
            : const Color(0xFF94A3B8));

    final Color labelColor = enabled
        ? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B))
        : (isDark ? Colors.white.withOpacity(0.32) : const Color(0xFF94A3B8));

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: InkWell(
        onTap: enabled
            ? () {
                AppHaptics.selectionClick();
                onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(
                      width: size,
                      height: size,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: primary
                            ? LinearGradient(
                                colors: <Color>[
                                  AppColors.primaryLight,
                                  primaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: primary
                            ? null
                            : (isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white),
                        border: Border.all(
                          color: primary
                              ? Colors.white.withOpacity(0.22)
                              : (isDark
                                  ? Colors.white.withOpacity(0.16)
                                  : const Color(0xFFCBD5E1)),
                          width: 1.2,
                        ),
                        boxShadow: primary
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : <BoxShadow>[
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                      ),
                      child: Icon(
                        icon,
                        size: iconSize,
                        color: resolvedIconColor,
                      ),
                    ),
                    if (busy)
                      SizedBox(
                        width: size,
                        height: size,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.goldLight,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPlayer extends StatefulWidget {
  const _EmptyPlayer({
    required this.audio,
    required this.isDark,
    required this.primary,
    required this.onQueue,
    required this.onLibrary,
  });

  final ChurchAudioService audio;
  final bool isDark;
  final Color primary;
  final VoidCallback onQueue;
  final VoidCallback onLibrary;

  @override
  State<_EmptyPlayer> createState() => _EmptyPlayerState();
}

class _EmptyPlayerState extends State<_EmptyPlayer> {
  MediaCategory _category = MediaCategory.radio;
  List<AudioTrack> _tracks = const <AudioTrack>[];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  Future<void> _loadCategory() async {
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Kushindwa kupakia orodha. Angalia mtandao wako.';
        _loading = false;
      });
    }
  }

  Future<void> _quickStartRadio() async {
    AppHaptics.mediumImpact();
    try {
      final List<AudioTrack> stations =
          await SayuniMediaRepository.instance.radioStations();
      if (stations.isNotEmpty) {
        await widget.audio.playQueue(stations, startIndex: 0);
      } else {
        widget.onLibrary();
      }
    } catch (_) {
      widget.onLibrary();
    }
  }

  void _selectCategory(MediaCategory cat) {
    if (cat.id == _category.id) return;
    AppHaptics.selectionClick();
    setState(() => _category = cat);
    _loadCategory();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDark;
    final Color primary = widget.primary;
    final Color titleColor =
        isDark ? AppColors.textWhite : const Color(0xFF0A2540);
    final Color subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Column(
      children: <Widget>[
        _TopBar(
          isDark: isDark,
          primary: primary,
          onQueue: widget.onQueue,
          onLibrary: widget.onLibrary,
        ),
        // Compact Hero Card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111C33) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.gold.withOpacity(0.3)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.gold.withOpacity(0.65), width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(_kLogoAsset, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Hakuna kinachocheza sasa',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chagua kituo cha redio, wimbo wa kwaya, tenzi au mahubiri hapa chini ili sauti ianze.',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _quickStartRadio,
                        icon: const Icon(Icons.radio_rounded, size: 18),
                        label: const Text(
                          'Cheza Redio Sasa',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: widget.onLibrary,
                      icon: Icon(
                        Icons.library_music_rounded,
                        size: 18,
                        color: isDark ? AppColors.primaryLight : primary,
                      ),
                      label: Text(
                        'Maktaba',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: isDark ? AppColors.textWhite : primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.primaryLight.withOpacity(0.5)
                              : primary.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Inline Media Category Pills
        _CategoryFilterBar(
          selected: _category,
          isDark: isDark,
          primary: primary,
          onSelect: _selectCategory,
        ),
        const SizedBox(height: 8),
        Divider(
          height: 1,
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        // Inline Playable Track List
        Expanded(
          child: _TrackListSection(
            tracks: _tracks,
            loading: _loading,
            error: _error,
            isDark: isDark,
            primary: primary,
            onRetry: _loadCategory,
            onSelectTrack: (int index) {
              AppHaptics.mediumImpact();
              widget.audio.playQueue(_tracks, startIndex: index);
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onSelect,
  });

  final MediaCategory selected;
  final bool isDark;
  final Color primary;
  final ValueChanged<MediaCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: <Widget>[
          for (final MediaCategory category in MediaCategory.playerSections)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ThemedCategoryPill(
                label: category.label,
                isSelected: category.id == selected.id,
                isDark: isDark,
                primary: primary,
                onTap: () => onSelect(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemedCategoryPill extends StatelessWidget {
  const _ThemedCategoryPill({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isSelected
        ? primary
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final Color textColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A));
    final Color borderColor = isSelected
        ? primary
        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackListSection extends StatelessWidget {
  const _TrackListSection({
    required this.tracks,
    required this.loading,
    required this.error,
    required this.isDark,
    required this.primary,
    required this.onRetry,
    required this.onSelectTrack,
  });

  final List<AudioTrack> tracks;
  final bool loading;
  final String? error;
  final bool isDark;
  final Color primary;
  final VoidCallback onRetry;
  final ValueChanged<int> onSelectTrack;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? AppColors.primaryLight : primary,
        ),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFDC2626),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Jaribu Tena'),
              ),
            ],
          ),
        ),
      );
    }
    if (tracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.library_music_outlined,
                size: 48,
                color: isDark ? AppColors.goldLight : AppColors.gold,
              ),
              const SizedBox(height: 12),
              Text(
                'Hakuna sauti katika sehemu hii bado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : const Color(0xFF0A2540),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pakia faili ya sauti (mp3/m4a) kutoka ukurasa wa Usimamizi ili ionekane hapa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Color titleColor =
        isDark ? AppColors.textWhite : const Color(0xFF0A2540);
    final Color subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: tracks.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      ),
      itemBuilder: (BuildContext context, int index) {
        final AudioTrack track = tracks[index];
        return ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withOpacity(isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              track.isLive ? Icons.radio_rounded : Icons.audiotrack_rounded,
              color: isDark ? AppColors.primaryLight : primary,
              size: 20,
            ),
          ),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            track.richSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12,
            ),
          ),
          trailing: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: track.isLive
                  ? const Color(0xFFDC2626).withOpacity(0.12)
                  : primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              track.isLive
                  ? Icons.cell_tower_rounded
                  : Icons.play_arrow_rounded,
              color: track.isLive
                  ? const Color(0xFFEF4444)
                  : (isDark ? AppColors.primaryLight : primary),
              size: 19,
            ),
          ),
          onTap: () => onSelectTrack(index),
        );
      },
    );
  }
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet({required this.audio});

  final ChurchAudioService audio;

  @override
  Widget build(BuildContext context) {
    final ChurchThemeService theme = ChurchThemeService();
    final bool isDark = theme.isDarkMode;
    final Color primary = theme.primaryColor;
    final List<AudioTrack> queue = audio.queueTracks;

    final Color titleColor =
        isDark ? AppColors.textWhite : const Color(0xFF0A2540);
    final Color subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
          child: Text(
            'ORODHA YA UCHEZAJI (${queue.length})',
            style: TextStyle(
              color: isDark ? const Color(0xFF9FB6D4) : primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (queue.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Hakuna sauti kwenye orodha ya uchezaji bado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor, fontSize: 13.5),
            ),
          ),
        for (int i = 0; i < queue.length; i++)
          ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: i == audio.queueIndex
                  ? primary
                  : (isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9)),
              child: Text(
                (i + 1).toString(),
                style: TextStyle(
                  color: i == audio.queueIndex
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              queue[i].title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: i == audio.queueIndex
                    ? (isDark ? AppColors.primaryLight : primary)
                    : titleColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              queue[i].category.label + (queue[i].isLive ? ' • LIVE' : ''),
              style: TextStyle(color: subtitleColor, fontSize: 11.5),
            ),
            trailing: i == audio.queueIndex
                ? Icon(
                    Icons.equalizer_rounded,
                    color: isDark ? AppColors.primaryLight : primary,
                    size: 20,
                  )
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
  const _MediaLibrarySheet({
    required this.audio,
    required this.initialCategory,
  });

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
    } catch (_) {
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
    final ChurchThemeService theme = ChurchThemeService();
    final bool isDark = theme.isDarkMode;
    final Color primary = theme.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'MAKTABA YA SAUTI',
                style: TextStyle(
                  color: isDark ? const Color(0xFFE2E8F0) : primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
        _CategoryFilterBar(
          selected: _category,
          isDark: isDark,
          primary: primary,
          onSelect: _select,
        ),
        const SizedBox(height: 10),
        Divider(
          height: 1,
          color: isDark ? const Color(0xFF1E2E48) : const Color(0xFFE2E8F0),
        ),
        Expanded(
          child: _TrackListSection(
            tracks: _tracks,
            loading: _loading,
            error: _error,
            isDark: isDark,
            primary: primary,
            onRetry: _load,
            onSelectTrack: (int index) {
              Navigator.of(context).pop();
              AppHaptics.mediumImpact();
              widget.audio.playQueue(_tracks, startIndex: index);
            },
          ),
        ),
      ],
    );
  }
}
