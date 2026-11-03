import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/services/church_audio_service.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../../media/presentation/now_playing_screen.dart';

class PersistentMiniPlayer extends StatelessWidget {
  const PersistentMiniPlayer({super.key});

  void _showFullPlayerSheet(BuildContext context, ChurchAudioService audio) {
    AppHaptics.mediumImpact();
    NowPlayingScreen.open(context);
  }

  @override
  Widget build(BuildContext context) {
    final audio = ChurchAudioService();
    final theme = ChurchThemeService();

    return ListenableBuilder(
      listenable: Listenable.merge([audio, theme]),
      builder: (context, _) {
        if (!audio.hasActiveTrack) return const SizedBox.shrink();

        final track = audio.currentTrack!;
        final isDark = theme.isDarkMode;
        final primary = theme.primaryColor;

        final Color titleColor =
            isDark ? Colors.white : const Color(0xFF0A2540);
        final Color subColor =
            isDark ? Colors.white.withOpacity(0.78) : const Color(0xFF475569);
        final Color iconColor = isDark ? Colors.white : const Color(0xFF0A2540);
        final Color disabledIconColor = isDark
            ? Colors.white.withOpacity(0.32)
            : const Color(0xFF94A3B8);

        return Padding(
          padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
          child: GestureDetector(
            onTap: () => _showFullPlayerSheet(context, audio),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF141E30), Color(0xFF0F172A)]
                          : const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? primary.withOpacity(0.42)
                          : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
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
                          color: primary.withOpacity(isDark ? 0.18 : 0.10),
                          border: Border.all(
                            color: primary.withOpacity(0.45),
                            width: 1.2,
                          ),
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
                                    color:
                                        isDark ? AppColors.primaryLight : primary,
                                    size: 20,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  track.isLiveRadio
                                      ? Icons.radio_rounded
                                      : Icons.music_note_rounded,
                                  color:
                                      isDark ? AppColors.primaryLight : primary,
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
                                        horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    track.title,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              track.subtitle,
                              style: TextStyle(
                                color: subColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Controls
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: audio.hasPrevious
                              ? iconColor
                              : disabledIconColor,
                          size: 22,
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
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                audio.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: isDark ? AppColors.gold : primary,
                                size: 32,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              onPressed: () {
                                AppHaptics.selectionClick();
                                audio.togglePlayPause();
                              },
                            ),
                            if (audio.isLoading)
                              IgnorePointer(
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark
                                        ? AppColors.goldLight
                                        : AppColors.gold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: audio.hasNext ? iconColor : disabledIconColor,
                          size: 22,
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
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: subColor,
                          size: 19,
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
