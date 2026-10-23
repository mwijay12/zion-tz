import 'package:flutter/material.dart';
import 'package:sayuni/core/theme/app_colors.dart';
import 'package:sayuni/core/theme/app_typography.dart';
import 'package:sayuni/core/constants/tenzi_za_rohoni.dart';
import 'package:sayuni/core/utils/haptics.dart';

class TenziScreen extends StatefulWidget {
  const TenziScreen({super.key});

  @override
  State<TenziScreen> createState() => _TenziScreenState();
}

class _TenziScreenState extends State<TenziScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredSongs = TenziZaRohoniData.songs
        .where((s) =>
            s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.lyrics.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.number.toString().contains(_searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Tenzi za Rohoni'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tafuta wimbo au namba...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredSongs.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final song = filteredSongs[idx];
                return ListTile(
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      song.number.toString(),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(song.title, style: AppTypography.titleSmall()),
                  subtitle: Text('Key: ${song.key} | Tempo: ${song.tempo}'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    AppHaptics.lightImpact();
                    _showSongDetails(song);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSongDetails(TenziSong song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wimbo Na. ${song.number}',
                        style: TextStyle(
                            color: AppColors.gold, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        song.title,
                        style: AppTypography.titleMedium(),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Key: ${song.key}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  song.lyrics,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    fontFamily: 'Serif',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
