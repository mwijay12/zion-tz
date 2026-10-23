import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/services/church_audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../media/presentation/now_playing_screen.dart';

class PersistentMiniPlayer extends StatelessWidget {
  const PersistentMiniPlayer({super.key});

  void _showFullPlayerSheet(BuildContext context, ChurchAudioService audio) {
    AppHaptics.mediumImpact();
    // Full-screen route (not a sheet): popping it keeps audio running.
    NowPlayingScreen.open(context);
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.4),
                              width: 1.2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (track.imageUrl != null &&
                                track.imageUrl!.isNotEmpty &&
                                track.imageUrl!.startsWith('http'))
                            ? Image.network(
                                track.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                  child: Icon(
                                    track.isLiveRadio
                                        ? Icons.radio_rounded
                                        : Icons.music_note_rounded,
                                    color: AppColors.primaryLight,
                                    size: 20,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  track.isLiveRadio
                                      ? Icons.radio_rounded
                                      : Icons.music_note_rounded,
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
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
                            color: audio.hasPrevious
                                ? Colors.white
                                : Colors.white38,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: audio.hasPrevious
                              ? () {
                                  AppHaptics.selectionClick();
                                  audio.playPrevious();
                                }
                              : null,
                        ),
                        IconButton(
                          icon: Icon(
                            audio.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: AppColors.gold,
                            size: 34,
                          ),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 36, minHeight: 36),
                          onPressed: () {
                            AppHaptics.selectionClick();
                            audio.togglePlayPause();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color:
                                audio.hasNext ? Colors.white : Colors.white38,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
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
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
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
