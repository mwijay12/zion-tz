import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/services/church_audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';

class PersistentMiniPlayer extends StatelessWidget {
  const PersistentMiniPlayer({super.key});

  void _showFullPlayerSheet(BuildContext context, ChurchAudioService audio) {
    AppHaptics.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FullAudioPlayerSheet(audio: audio),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = ChurchAudioService();

    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        if (!audio.hasActiveTrack) return const SizedBox.shrink();

        final track = audio.currentTrack!;

        return Padding(
          padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
          child: GestureDetector(
            onTap: () => _showFullPlayerSheet(context, audio),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF181C23), Color(0xFF1E232A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 14,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Station Logo / Disc Artwork
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.18),
                          border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (track.imageUrl != null && track.imageUrl!.isNotEmpty && track.imageUrl!.startsWith('http'))
                            ? Image.network(
                                track.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(
                                    track.isLiveRadio ? Icons.radio_rounded : Icons.music_note_rounded,
                                    color: AppColors.primaryLight,
                                    size: 20,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  track.isLiveRadio ? Icons.radio_rounded : Icons.music_note_rounded,
                                  color: AppColors.primaryLight,
                                  size: 20,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),

                      // Track Metadata
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (track.isLiveRadio)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    track.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              track.subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Controls
                      if (audio.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gold,
                            ),
                          ),
                        )
                      else ...[
                        IconButton(
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            color: audio.hasPrevious ? Colors.white : Colors.white38,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: audio.hasPrevious
                              ? () {
                                  AppHaptics.selectionClick();
                                  audio.playPrevious();
                                }
                              : null,
                        ),
                        IconButton(
                          icon: Icon(
                            audio.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                            color: AppColors.gold,
                            size: 34,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: () {
                            AppHaptics.selectionClick();
                            audio.togglePlayPause();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: audio.hasNext ? Colors.white : Colors.white38,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: audio.hasNext
                              ? () {
                                  AppHaptics.selectionClick();
                                  audio.playNext();
                                }
                              : null,
                        ),
                      ],

                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () {
                          AppHaptics.lightImpact();
                          audio.stop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FullAudioPlayerSheet extends StatelessWidget {
  final ChurchAudioService audio;

  const _FullAudioPlayerSheet({required this.audio});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        final track = audio.currentTrack;
        if (track == null) return const SizedBox.shrink();

        final maxDuration = audio.duration.inSeconds > 0 ? audio.duration.inSeconds.toDouble() : 1.0;
        final currentPosition = audio.position.inSeconds.toDouble().clamp(0.0, maxDuration);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1D33), Color(0xFF071526)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag Handle
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),

                // Disc Artwork with Profile Pic / Logo support
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF1E6BFF), Color(0xFF0A2540)],
                    ),
                    border: Border.all(color: AppColors.primaryLight, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (track.imageUrl != null && track.imageUrl!.isNotEmpty && track.imageUrl!.startsWith('http'))
                      ? Image.network(
                          track.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              track.isLiveRadio ? Icons.radio_rounded : Icons.graphic_eq_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            track.isLiveRadio ? Icons.radio_rounded : Icons.graphic_eq_rounded,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Live Radio Badge / Audio Type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: Text(
                    track.isLiveRadio ? 'LIVE GOSPEL RADIO • SAYUNI' : 'MAHUBIRI & NYIMBO',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  track.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  track.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Seekbar (if not live radio)
                if (!track.isLiveRadio) ...[
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.gold,
                      inactiveTrackColor: Colors.white.withOpacity(0.15),
                      thumbColor: AppColors.gold,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: currentPosition,
                      max: maxDuration,
                      onChanged: (val) {
                        audio.seek(Duration(seconds: val.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(audio.position),
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                        ),
                        Text(
                          _formatDuration(audio.duration),
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tangazo la Moja kwa Moja (Live Audio Broadcast)',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Main Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: audio.hasPrevious
                          ? () {
                              AppHaptics.mediumImpact();
                              audio.playPrevious();
                            }
                          : null,
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        color: audio.hasPrevious ? Colors.white : Colors.white24,
                        size: 34,
                      ),
                      tooltip: 'Wimbo / Redio Iliyopita',
                    ),
                    const SizedBox(width: 6),
                    if (!track.isLiveRadio)
                      IconButton(
                        onPressed: () {
                          AppHaptics.lightImpact();
                          audio.seek(audio.position - const Duration(seconds: 10));
                        },
                        icon: const Icon(Icons.replay_10_rounded, color: Colors.white70, size: 26),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFDF70), Color(0xFFD4AF37)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.4),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: const Color(0xFF0A2540),
                          size: 38,
                        ),
                        onPressed: () {
                          AppHaptics.selectionClick();
                          audio.togglePlayPause();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!track.isLiveRadio)
                      IconButton(
                        onPressed: () {
                          AppHaptics.lightImpact();
                          audio.seek(audio.position + const Duration(seconds: 10));
                        },
                        icon: const Icon(Icons.forward_10_rounded, color: Colors.white70, size: 26),
                      ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: audio.hasNext
                          ? () {
                              AppHaptics.mediumImpact();
                              audio.playNext();
                            }
                          : null,
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: audio.hasNext ? Colors.white : Colors.white24,
                        size: 34,
                      ),
                      tooltip: 'Wimbo / Redio Inayofuata',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
