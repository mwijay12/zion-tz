import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/church_profile.dart';
import '../../../core/services/church_auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../notes/models/sermon_note.dart';
import '../../notes/services/notes_service.dart';
import '../data/default_teachings_data.dart';
import '../models/sermon_media_item.dart';

class TeachingArticleReaderScreen extends StatefulWidget {
  final SermonMediaItem article;

  const TeachingArticleReaderScreen({
    super.key,
    required this.article,
  });

  @override
  State<TeachingArticleReaderScreen> createState() =>
      _TeachingArticleReaderScreenState();
}

class _TeachingArticleReaderScreenState
    extends State<TeachingArticleReaderScreen> {
  late SermonMediaItem _currentArticle;
  double _fontSize = 15.5;
  bool _isSavedToNotes = false;
  final ScrollController _scrollController = ScrollController();

  // TTS
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isTtsAvailable = true;

  @override
  void initState() {
    super.initState();
    _currentArticle = widget.article;
    _initTts();
    _checkSavedStatus();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('sw-TZ');
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setErrorHandler((msg) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      _isTtsAvailable = false;
    }
  }

  Future<void> _checkSavedStatus() async {
    try {
      final notes = await NotesService().getNotes();
      final exists = notes.any((n) =>
          n.id == 'note-${_currentArticle.id}' ||
          n.title == _currentArticle.title);
      if (mounted) setState(() => _isSavedToNotes = exists);
    } catch (_) {}
  }

  Future<void> _toggleTts() async {
    AppHaptics.lightImpact();
    if (_isSpeaking) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } else {
      final buffer = StringBuffer();
      buffer.writeln(_currentArticle.title);
      buffer.writeln('Mhubiri: ${_currentArticle.preacher}.');
      if (_currentArticle.keyVerse.isNotEmpty) {
        buffer.writeln('Mstari wa msingi: ${_currentArticle.keyVerse}.');
      }
      buffer.writeln(_currentArticle.fullArticle.replaceAll(RegExp(r'#|\*|•|-'), ' '));
      if (_currentArticle.pastoralPrayer.isNotEmpty) {
        buffer.writeln('Sala ya Kichungaji: ${_currentArticle.pastoralPrayer}');
      }
      await _flutterTts.speak(buffer.toString());
      if (mounted) setState(() => _isSpeaking = true);
    }
  }

  Future<void> _saveToNotes() async {
    AppHaptics.mediumImpact();
    final note = SermonNote(
      id: 'note-${_currentArticle.id}',
      title: _currentArticle.title,
      preacher: _currentArticle.preacher,
      scripture: _currentArticle.scripture,
      content: _currentArticle.fullArticle.isNotEmpty
          ? _currentArticle.fullArticle
          : _currentArticle.description,
      date: DateTime.now(),
    );

    await NotesService().updateNote(note);
    if (!mounted) return;

    setState(() => _isSavedToNotes = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Somo limehifadhiwa kwenye Madokezo yako ya Sayuni!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareArticle() async {
    AppHaptics.lightImpact();
    final buffer = StringBuffer();
    buffer.writeln('📖 *${_currentArticle.title.toUpperCase()}*');
    buffer.writeln('👤 *Mhubiri:* ${_currentArticle.preacher}');
    buffer.writeln('📜 *Maandiko:* ${_currentArticle.scripture}');
    buffer.writeln('');
    if (_currentArticle.keyVerse.isNotEmpty) {
      buffer.writeln('✨ *Mstari wa Kukumbuka:*');
      buffer.writeln(_currentArticle.keyVerse);
      buffer.writeln('');
    }
    buffer.writeln('💡 *Masomo ya Vitendo:*');
    for (final t in _currentArticle.takeaways) {
      buffer.writeln('• $t');
    }
    buffer.writeln('');
    buffer.writeln('🏛️ *${ChurchProfile.name}* • ${ChurchProfile.location}');
    buffer.writeln('Soma zaidi kwenye App ya Sayuni Jerusalem.');

    await Share.share(buffer.toString(), subject: _currentArticle.title);
  }

  void _showScriptureModal(String scripture) {
    AppHaptics.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.auto_stories_rounded,
                    color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  scripture,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
              ),
              child: Text(
                'Mstari huu ni sehemu ya somo la "${_currentArticle.title}". Fungua Biblia ya Sayuni ili kusoma sura nzima na maelezo ya kina ya kitheolojia.',
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Nimeelewa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark
        ? const Color(0xFFD4A847).withOpacity(0.12)
        : const Color(0xFFE2E8F0);

    final auth = ChurchAuthService();
    final canEdit = auth.isAdmin ||
        auth.churchRole == ChurchRole.pastor ||
        auth.churchRole == ChurchRole.superAdmin ||
        auth.can(ChurchPermission.uploadSermonMedia) ||
        auth.demoAccessAllowed;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fundisho la Neno',
          style: AppTypography.cinzel(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Pastor / Admin Article Editor
          if (canEdit)
            IconButton(
              icon: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.gold,
                size: 26,
              ),
              tooltip: 'Hariri Somo (Mchungaji / Admin)',
              onPressed: () => _showEditArticleSheet(context, isDark),
            ),

          // Text Size Controller Menu
          PopupMenuButton<double>(
            icon: Icon(Icons.format_size_rounded, color: textColor),
            tooltip: 'Ukubwa wa Maandishi',
            onSelected: (val) {
              setState(() => _fontSize = val);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 14.0, child: Text('Ndogo (14pt)')),
              const PopupMenuItem(value: 16.0, child: Text('Kawaida (16pt)')),
              const PopupMenuItem(value: 18.0, child: Text('Kubwa (18pt)')),
              const PopupMenuItem(value: 20.0, child: Text('Kubwa Zaidi (20pt)')),
            ],
          ),

          // Voice Reader (TTS)
          if (_isTtsAvailable)
            IconButton(
              icon: Icon(
                _isSpeaking
                    ? Icons.record_voice_over_rounded
                    : Icons.voice_over_off_rounded,
                color: _isSpeaking ? AppColors.gold : textMuted,
              ),
              tooltip: _isSpeaking ? 'Sitisha Sauti' : 'Sikiliza kwa Sauti',
              onPressed: _toggleTts,
            ),

          // Bookmark to Notes
          IconButton(
            icon: Icon(
              _isSavedToNotes
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _isSavedToNotes ? AppColors.gold : textColor,
            ),
            tooltip: 'Hifadhi kwenye Madokezo',
            onPressed: _saveToNotes,
          ),

          // Share
          IconButton(
            icon: Icon(Icons.share_rounded, color: textColor),
            tooltip: 'Shiriki Ujumbe',
            onPressed: _shareArticle,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice Reader Floating Indicator Bar
            if (_isSpeaking)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up_rounded,
                        color: AppColors.gold, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Usomaji wa sauti unaendelea kwa Kiswahili...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleTts,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Sitisha',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Hero Image Card
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Image(
                    image: (_currentArticle.imageUrl.startsWith('http') ||
                            _currentArticle.imageUrl.startsWith('assets/'))
                        ? (_currentArticle.imageUrl.startsWith('assets/')
                            ? AssetImage(_currentArticle.imageUrl) as ImageProvider
                            : NetworkImage(_currentArticle.imageUrl))
                        : const AssetImage('assets/images/church_front.jpg'),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, _, __) => Container(
                      height: 220,
                      color: const Color(0xFF0F172A),
                      child: const Center(
                        child: Icon(Icons.auto_stories_rounded,
                            size: 48, color: AppColors.gold),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentArticle.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            _currentArticle.readTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentArticle.date,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_rounded,
                                color: AppColors.gold, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _currentArticle.preacher,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Article Main Headline
            Text(
              _currentArticle.title,
              style: AppTypography.cinzel(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ).copyWith(height: 1.25),
            ),
            const SizedBox(height: 12),

            // Scripture Reference Chips
            if (_currentArticle.scriptureList.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentArticle.scriptureList.map((sc) {
                  return InkWell(
                    onTap: () => _showScriptureModal(sc),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.gold.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bookmark_outline_rounded,
                              size: 13, color: AppColors.gold),
                          const SizedBox(width: 5),
                          Text(
                            sc,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
            ],

            // Golden Key Memory Verse Callout Card
            if (_currentArticle.keyVerse.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161F30)
                      : const Color(0xFFFFFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2, right: 12),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.format_quote_rounded,
                          color: AppColors.gold, size: 20),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MSTARI WA KUKUMBUKA',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currentArticle.keyVerse,
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: _fontSize,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: textColor,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Article Body Content (Divided into Rich Paragraphs & Sections)
            _buildArticleContent(
              content: _currentArticle.fullArticle.isNotEmpty
                  ? _currentArticle.fullArticle
                  : _currentArticle.description,
              textColor: textColor,
              textMuted: textMuted,
              cardBg: cardBg,
              borderColor: borderColor,
            ),
            const SizedBox(height: 24),

            // Takeaways & Practical Action Items Card
            if (_currentArticle.takeaways.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.task_alt_rounded,
                              color: Color(0xFF16A34A), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'HATUA ZA KUCHUKUA WIKI HII',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ..._currentArticle.takeaways.map((point) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4, right: 10),
                              child: Icon(Icons.check_circle_rounded,
                                  size: 15, color: Color(0xFF16A34A)),
                            ),
                            Expanded(
                              child: Text(
                                point,
                                style: TextStyle(
                                  fontSize: _fontSize - 1,
                                  color: textColor,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],

            // Pastoral Blessing & Prayer Card
            if (_currentArticle.pastoralPrayer.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.volunteer_activism_rounded,
                            color: AppColors.gold, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'SALA YA KICHUNGAJI NA BARAKA',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentArticle.pastoralPrayer,
                      style: TextStyle(
                        color: const Color(0xFFF1F5F9),
                        fontSize: _fontSize,
                        height: 1.55,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AppHaptics.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.gold,
                              content: Text(
                                'Amen! Baraka ya Bwana iwe juu yako.',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.favorite_rounded, size: 16),
                        label: const Text('Naitikia Amen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: const Color(0xFF0F172A),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Action Buttons Row: Save & Share
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveToNotes,
                    icon: Icon(
                      _isSavedToNotes
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_add_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _isSavedToNotes ? 'Imehifadhiwa' : 'Weka Madokezo',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareArticle,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'Shiriki Neno',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Next Suggested Teachings from Church Diary
            _buildNextTeachingsSection(textColor, textMuted, cardBg, borderColor),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildInlineSpans(
    String text,
    TextStyle baseStyle, {
    Color? boldColor,
    Color? italicColor,
  }) {
    if (text.isEmpty) return const [];
    final spans = <InlineSpan>[];
    final regex =
        RegExp(r'(\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|\*(.+?)\*|_(.+?)_)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final raw = match.group(0)!;
      if (raw.startsWith('***') && raw.endsWith('***') && raw.length > 6) {
        final inner = raw.substring(3, raw.length - 3);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            color: boldColor ?? baseStyle.color,
          ),
        ));
      } else if (raw.startsWith('**') && raw.endsWith('**') && raw.length > 4) {
        final inner = raw.substring(2, raw.length - 2);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w800,
            color: boldColor ?? baseStyle.color,
          ),
        ));
      } else if (raw.startsWith('*') && raw.endsWith('*') && raw.length > 2) {
        final inner = raw.substring(1, raw.length - 1);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
            color: italicColor ?? baseStyle.color,
          ),
        ));
      } else if (raw.startsWith('_') && raw.endsWith('_') && raw.length > 2) {
        final inner = raw.substring(1, raw.length - 1);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
            color: italicColor ?? baseStyle.color,
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }

  Widget _buildArticleContent({
    required String content,
    required Color textColor,
    required Color textMuted,
    required Color cardBg,
    required Color borderColor,
  }) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 10));
      } else if (line.startsWith('# ')) {
        final clean = line.replaceFirst(RegExp(r'^#\s*'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 8),
          child: Text.rich(
            TextSpan(
              children: _buildInlineSpans(
                clean,
                AppTypography.cinzel(
                  color: textColor,
                  fontSize: _fontSize + 4.5,
                  fontWeight: FontWeight.w900,
                ),
                boldColor: AppColors.gold,
              ),
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        final clean = line.replaceFirst(RegExp(r'^##\s*'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: _buildInlineSpans(
                    clean,
                    AppTypography.cinzel(
                      color: AppColors.gold,
                      fontSize: _fontSize + 2.5,
                      fontWeight: FontWeight.w800,
                    ),
                    boldColor: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 38,
                height: 2.5,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('### ')) {
        final clean = line.replaceFirst(RegExp(r'^###\s*'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text.rich(
            TextSpan(
              children: _buildInlineSpans(
                clean,
                AppTypography.cinzel(
                  color: textColor,
                  fontSize: _fontSize + 1.8,
                  fontWeight: FontWeight.w800,
                ),
                boldColor: AppColors.gold,
              ),
            ),
          ),
        ));
      } else if (line.startsWith('#### ')) {
        final clean = line.replaceFirst(RegExp(r'^####\s*'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text.rich(
            TextSpan(
              children: _buildInlineSpans(
                clean,
                TextStyle(
                  color: AppColors.gold,
                  fontSize: _fontSize + 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ));
      } else if (line == '---') {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Divider(color: borderColor, height: 1),
        ));
      } else if (line.startsWith('• ') || line.startsWith('- ')) {
        final clean = line.replaceFirst(RegExp(r'^(• |- )\s*'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 7, right: 9),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: _buildInlineSpans(
                      clean,
                      TextStyle(
                        fontSize: _fontSize,
                        color: textColor,
                        height: 1.55,
                      ),
                      boldColor: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
      } else if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
        final numStr = match?.group(1) ?? '1';
        final clean = match?.group(2) ?? line;
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                ),
                child: Text(
                  numStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: _buildInlineSpans(
                      clean,
                      TextStyle(
                        fontSize: _fontSize,
                        color: textColor,
                        height: 1.55,
                      ),
                      boldColor: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('> ')) {
        final clean = line.replaceFirst(RegExp(r'^>\s*'), '');
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: AppColors.gold, width: 3.5),
            ),
          ),
          child: Text.rich(
            TextSpan(
              children: _buildInlineSpans(
                clean,
                TextStyle(
                  fontSize: _fontSize,
                  color: textColor,
                  fontStyle: FontStyle.italic,
                  height: 1.55,
                ),
                boldColor: AppColors.gold,
              ),
            ),
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text.rich(
            TextSpan(
              children: _buildInlineSpans(
                line,
                TextStyle(
                  fontSize: _fontSize,
                  color: textColor,
                  height: 1.62,
                ),
                boldColor: textColor,
              ),
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  void _showEditArticleSheet(BuildContext context, bool isDark) {
    AppHaptics.selectionClick();
    final titleCtrl = TextEditingController(text: _currentArticle.title);
    final preacherCtrl = TextEditingController(text: _currentArticle.preacher);
    final scriptureCtrl = TextEditingController(text: _currentArticle.scripture);
    final keyVerseCtrl = TextEditingController(text: _currentArticle.keyVerse);
    final readTimeCtrl = TextEditingController(text: _currentArticle.readTime);
    final fullArticleCtrl =
        TextEditingController(text: _currentArticle.fullArticle);
    final takeawaysCtrl =
        TextEditingController(text: _currentArticle.takeaways.join('\n'));
    final prayerCtrl =
        TextEditingController(text: _currentArticle.pastoralPrayer);

    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inputBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final borderColor = isDark
        ? const Color(0xFFD4A847).withOpacity(0.2)
        : const Color(0xFFCBD5E1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 16,
              left: 18,
              right: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_note_rounded,
                                color: AppColors.gold, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hariri Somo / Makala',
                                style: AppTypography.cinzel(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              const Text(
                                'Mchungaji & Wasimamizi wa Sayuni',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textColor),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 12),

                  // Form inputs
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildInputField(
                          label: 'Kichwa cha Somo *',
                          controller: titleCtrl,
                          textColor: textColor,
                          inputBg: inputBg,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: 'Mhubiri / Mwalimu *',
                                controller: preacherCtrl,
                                textColor: textColor,
                                inputBg: inputBg,
                                borderColor: borderColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildInputField(
                                label: 'Muda wa Kusoma',
                                controller: readTimeCtrl,
                                textColor: textColor,
                                inputBg: inputBg,
                                borderColor: borderColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          label:
                              'Mistari ya Kusoma (e.g. Yoh 13:34-35 • 1 Kor 13:1-6)',
                          controller: scriptureCtrl,
                          textColor: textColor,
                          inputBg: inputBg,
                          borderColor: borderColor,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          label: 'Mstari wa Kukumbuka (Key Verse)',
                          controller: keyVerseCtrl,
                          textColor: textColor,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          label:
                              'Maudhui Kamili ya Makala (Inakubali Markdown: ##, ###, **, •)',
                          controller: fullArticleCtrl,
                          textColor: textColor,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          maxLines: 10,
                          hint: 'Andika mafundisho hapa...',
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          label:
                              'Hatua za Vitendo (Takeaways - Andika kila nukta kwenye mstari wake)',
                          controller: takeawaysCtrl,
                          textColor: textColor,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          maxLines: 4,
                          hint: 'Nukta ya 1\nNukta ya 2\nNukta ya 3',
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          label: 'Sala ya Kichungaji na Baraka',
                          controller: prayerCtrl,
                          textColor: textColor,
                          inputBg: inputBg,
                          borderColor: borderColor,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Bottom action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Ghairi'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.redAccent,
                                  content:
                                      Text('Tafadhali weka kichwa cha somo'),
                                ),
                              );
                              return;
                            }

                            final scriptureText = scriptureCtrl.text.trim();
                            final scriptureList = scriptureText
                                .split(RegExp(r'[•,]'))
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty)
                                .toList();

                            final takeaways = takeawaysCtrl.text
                                .split('\n')
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty)
                                .toList();

                            final updated = _currentArticle.copyWith(
                              title: title,
                              preacher: preacherCtrl.text.trim(),
                              scripture: scriptureText,
                              scriptureList: scriptureList.isNotEmpty
                                  ? scriptureList
                                  : _currentArticle.scriptureList,
                              readTime: readTimeCtrl.text.trim().isNotEmpty
                                  ? readTimeCtrl.text.trim()
                                  : _currentArticle.readTime,
                              keyVerse: keyVerseCtrl.text.trim(),
                              fullArticle: fullArticleCtrl.text.trim(),
                              takeaways: takeaways,
                              pastoralPrayer: prayerCtrl.text.trim(),
                            );

                            await DefaultTeachingsData.saveTeachingUpdate(
                                updated);
                            if (!mounted) return;
                            setState(() {
                              _currentArticle = updated;
                            });
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF16A34A),
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Makala imesasishwa na kuhifadhiwa kikamilifu!',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Hifadhi Mabadiliko'),
                            style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
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
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required Color textColor,
    required Color inputBg,
    required Color borderColor,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(fontSize: 13, color: textColor.withOpacity(0.4)),
            filled: true,
            fillColor: inputBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextTeachingsSection(
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
  ) {
    final others = DefaultTeachingsData.items
        .where((t) => t.id != _currentArticle.id && t.type == 'text')
        .take(3)
        .toList();

    if (others.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 20),
            const SizedBox(width: 8),
            Text(
              'MASOMO MENGINE YA NENO',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...others.map((nextItem) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              title: Text(
                nextItem.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${nextItem.preacher} • ${nextItem.readTime}',
                style: TextStyle(color: textMuted, fontSize: 11),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.gold),
              onTap: () {
                AppHaptics.lightImpact();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TeachingArticleReaderScreen(article: nextItem),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
