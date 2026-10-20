import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/church_theme_service.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/top_notification.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../models/bible_model.dart';
import '../models/tenzi_model.dart';
import '../services/bible_service.dart';
import '../../notes/models/sermon_note.dart';
import '../../notes/services/notes_service.dart';

class BibleScreen extends StatefulWidget {
  final int initialModuleIndex;
  final String? initialBookName;
  final String? initialChapterNumber;
  final String? initialVerseNumber;
  final int? initialTenziNumber;

  const BibleScreen({
    super.key,
    this.initialModuleIndex = 0,
    this.initialBookName,
    this.initialChapterNumber,
    this.initialVerseNumber,
    this.initialTenziNumber,
  });

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final BibleService _bibleService = BibleService();
  final FlutterTts _flutterTts = FlutterTts();

  // Active module: 0 = Bible, 1 = Tenzi za Rohoni
  late int _activeModuleIndex;

  // Bible State
  List<BibleBook> _swBooks = [];
  List<BibleBook> _kjvBooks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedTestamentIndex = 1; // 0 = Old (39), 1 = New (27)
  String _currentTranslation = 'sw'; // 'sw', 'kjv', 'parallel'

  BibleBook? _currentBook;
  BibleChapter? _currentChapter;
  double _fontSize = 16.0;

  // Bookmarks & Scripture Highlighting (Tap-to-action pattern)
  final Set<String> _bookmarkedVerses = {};
  int? _selectedVerseIndex;
  bool _showHighlightPicker = false;
  final Map<String, int> _verseHighlights = {}; // 0: Gold, 1: Emerald, 2: Sky Blue, 3: Rose

  // Offline Chapter Download State
  final Set<String> _downloadedOfflineChapters = {};
  bool _isDownloadingChapter = false;
  double _speechRate = 0.5;

  // Tenzi State
  List<TenziHymn> _tenziList = [];
  TenziHymn? _selectedTenzi;
  String _tenziSearchQuery = '';

  // Audio / TTS State
  bool _isPlayingAudio = false;
  bool _isAudioPaused = false;
  int? _activeSpeakingVerseIndex;
  int _playbackSessionId = 0;
  bool _isExplicitlyStopped = true;

  @override
  void initState() {
    super.initState();
    _activeModuleIndex = widget.initialModuleIndex;
    _initTts();
    _loadAllData();
    _loadDownloadedChapters();
    _loadHighlights();
  }

  @override
  void didUpdateWidget(covariant BibleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialModuleIndex != widget.initialModuleIndex) {
      setState(() {
        _activeModuleIndex = widget.initialModuleIndex;
      });
    }
  }

  Future<void> _loadDownloadedChapters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('offline_audio_chapters') ?? [];
      if (mounted) {
        setState(() {
          _downloadedOfflineChapters.addAll(list);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('bible_hl_'));
      for (final k in keys) {
        final val = prefs.getInt(k);
        if (val != null) {
          _verseHighlights[k.replaceFirst('bible_hl_', '')] = val;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _setHighlight(String refKey, int colorIdx) async {
    AppHaptics.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    if (colorIdx < 0) {
      _verseHighlights.remove(refKey);
      await prefs.remove('bible_hl_$refKey');
    } else {
      _verseHighlights[refKey] = colorIdx;
      await prefs.setInt('bible_hl_$refKey', colorIdx);
    }
    setState(() {
      _showHighlightPicker = false;
    });
  }

  void _openNoteDialogForVerse(BibleVerse verse) {
    AppHaptics.lightImpact();
    final ref = '${_currentBook?.bookName} ${_currentChapter?.chapterNumber}:${verse.verseNumber}';
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Hifadhi Dokezo la Somo',
                        style: AppTypography.titleMedium(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Text(
                  '📖 $ref\n"${verse.verseText}"',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Andika tafakari, somo au maombi yako hapa...',
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    AppHaptics.lightImpact();
                    final newNote = SermonNote(
                      id: 'note-${DateTime.now().millisecondsSinceEpoch}',
                      title: 'Tafakari: $ref',
                      preacher: 'Neno la Biblia',
                      scripture: ref,
                      content: '$text\n\n[Mstari: "${verse.verseText}"]',
                      date: DateTime.now(),
                    );
                    Navigator.pop(ctx);
                    await NotesService().addNote(newNote);
                    if (mounted) {
                      AppTopAlert.show(
                        context,
                        title: 'Kidokezo Kimehifadhiwa',
                        message: 'Dokezo limehifadhiwa kwenye Daftari la Mahubiri!',
                        type: TopAlertType.success,
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Hifadhi Dokezo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _currentChapterKey =>
      '${_currentBook?.bookName ?? ""}_${_currentChapter?.chapterNumber ?? 0}';

  bool get _isCurrentChapterDownloaded =>
      _downloadedOfflineChapters.contains(_currentChapterKey);

  Future<void> _toggleDownloadChapter() async {
    if (_currentChapter == null) return;
    AppHaptics.lightImpact();

    final key = _currentChapterKey;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    if (_isCurrentChapterDownloaded) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Futa Sura ya Offline?',
            style: AppTypography.titleMedium(color: AppColors.textPrimary),
          ),
          content: Text(
            'Je, ungependa kufuta ${_currentBook?.bookName} ${_currentChapter?.chapterNumber} kutoka kwenye hifadhi ya offline?',
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ghairi'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() {
                  _downloadedOfflineChapters.remove(key);
                });
                await prefs.setStringList('offline_audio_chapters', _downloadedOfflineChapters.toList());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sura imeondolewa kwenye kumbukumbu ya offline.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Futa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      setState(() => _isDownloadingChapter = true);
      await Future.delayed(const Duration(milliseconds: 650));
      setState(() {
        _downloadedOfflineChapters.add(key);
        _isDownloadingChapter = false;
      });
      await prefs.setStringList('offline_audio_chapters', _downloadedOfflineChapters.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Sura ya ${_currentBook?.bookName} ${_currentChapter?.chapterNumber} imepakuliwa kwa ajili ya offline audio!'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _initTts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rateSetting = prefs.getDouble('setting_speech_rate') ?? 1.0;
      _speechRate = 0.5 * rateSetting;
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        if (_isExplicitlyStopped || !_isPlayingAudio || _isAudioPaused) return;
        final currentSession = _playbackSessionId;
        if (_currentChapter != null) {
          final nextIndex = (_activeSpeakingVerseIndex ?? 0) + 1;
          if (nextIndex < _currentChapter!.verses.length && 
              currentSession == _playbackSessionId && 
              !_isExplicitlyStopped && 
              !_isAudioPaused) {
            _playVerseAudio(nextIndex);
          } else {
            _stopAudio();
          }
        }
      });

      _flutterTts.setErrorHandler((_) {
        _stopAudio();
      });
    } catch (_) {
      // Graceful fallback if platform TTS initialization is unsupported in current environment
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final prefBible = prefs.getString('setting_bible');
    if (prefBible != null && prefBible.contains('KJV')) {
      _currentTranslation = 'kjv';
    }

    final sw = await _bibleService.loadBible(translation: 'sw');
    final kjv = await _bibleService.loadBible(translation: 'kjv');
    final tenzi = await _bibleService.loadTenzi();

    setState(() {
      _swBooks = sw;
      _kjvBooks = kjv;
      _tenziList = tenzi;
      if (_tenziList.isNotEmpty) {
        if (widget.initialTenziNumber != null) {
          _selectedTenzi = _tenziList.firstWhere(
            (t) => t.number == widget.initialTenziNumber,
            orElse: () => _tenziList.first,
          );
        } else {
          _selectedTenzi = _tenziList.firstWhere(
            (t) => t.number == 8, // Chakutumaini Sina default
            orElse: () => _tenziList.first,
          );
        }
      }

      if (_swBooks.isNotEmpty) {
        BibleBook targetBook;
        if (widget.initialBookName != null && widget.initialBookName!.isNotEmpty) {
          final queryBook = widget.initialBookName!.toLowerCase().trim();
          targetBook = _swBooks.firstWhere(
            (b) => b.bookName.toLowerCase() == queryBook ||
                   b.bookName.toLowerCase().contains(queryBook),
            orElse: () => _swBooks.firstWhere(
              (b) => b.bookName.toLowerCase() == 'mathayo',
              orElse: () => _swBooks.first,
            ),
          );
        } else {
          targetBook = _swBooks.firstWhere(
            (b) => b.bookName.toLowerCase() == 'mathayo',
            orElse: () => _swBooks.first,
          );
        }
        _currentBook = targetBook;
        _selectedTestamentIndex = targetBook.isNewTestament ? 1 : 0;

        if (widget.initialChapterNumber != null && widget.initialChapterNumber!.isNotEmpty) {
          final matches = targetBook.chapters.where(
            (c) => c.chapterNumber.toString() == widget.initialChapterNumber.toString(),
          );
          _currentChapter = matches.isNotEmpty ? matches.first : (targetBook.chapters.isNotEmpty ? targetBook.chapters.first : null);
        } else {
          _currentChapter = targetBook.chapters.isNotEmpty ? targetBook.chapters.first : null;
        }

        if (widget.initialVerseNumber != null && _currentChapter != null) {
          final vIndex = _currentChapter!.verses.indexWhere(
            (v) => v.verseNumber.toString() == widget.initialVerseNumber.toString(),
          );
          if (vIndex != -1) {
            _selectedVerseIndex = vIndex;
          }
        }
      }
      _isLoading = false;
    });
  }

  void _stopAudio() {
    _isExplicitlyStopped = true;
    _playbackSessionId++;
    if (mounted) {
      setState(() {
        _isPlayingAudio = false;
        _isAudioPaused = false;
        _activeSpeakingVerseIndex = null;
      });
    }
    _flutterTts.stop();
  }

  Future<void> _playVerseAudio(int verseIndex) async {
    if (_currentChapter == null || verseIndex >= _currentChapter!.verses.length) {
      _stopAudio();
      return;
    }

    AppHaptics.lightImpact();
    final verse = _currentChapter!.verses[verseIndex];
    final isEnglish = _currentTranslation == 'kjv';

    _isExplicitlyStopped = false;
    final sessionId = ++_playbackSessionId;

    try {
      final prefs = await SharedPreferences.getInstance();
      final rateSetting = prefs.getDouble('setting_speech_rate') ?? 1.0;
      _speechRate = 0.5 * rateSetting;
      await _flutterTts.setSpeechRate(_speechRate);

      await _flutterTts.stop();
      if (_isExplicitlyStopped || sessionId != _playbackSessionId) return;

      await _flutterTts.setLanguage(isEnglish ? 'en-US' : 'sw');
      if (_isExplicitlyStopped || sessionId != _playbackSessionId) return;

      if (mounted) {
        setState(() {
          _isPlayingAudio = true;
          _isAudioPaused = false;
          _activeSpeakingVerseIndex = verseIndex;
        });
      }

      await _flutterTts.speak(verse.verseText);
    } catch (_) {
      _stopAudio();
    }
  }

  void _togglePlayPause() {
    AppHaptics.lightImpact();
    if (_isPlayingAudio) {
      if (_isAudioPaused) {
        _isExplicitlyStopped = false;
        _isAudioPaused = false;
        final current = _activeSpeakingVerseIndex ?? 0;
        _playVerseAudio(current);
      } else {
        _isAudioPaused = true;
        _isExplicitlyStopped = true;
        _playbackSessionId++;
        if (mounted) {
          setState(() {});
        }
        _flutterTts.stop();
      }
    } else {
      _playVerseAudio(0);
    }
  }

  void _showBookSelector() {
    AppHaptics.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeList = _currentTranslation == 'kjv' ? _kjvBooks : _swBooks;
            final filtered = activeList.where((book) {
              final matchesQuery = book.bookName.toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesTestament = _selectedTestamentIndex == 0
                  ? !book.isNewTestament
                  : book.isNewTestament;
              return matchesQuery && matchesTestament;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chagua Kitabu cha Biblia (66)',
                        style: AppTypography.titleMedium(color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Testament Switcher: Agano la Kale (39) vs Agano Jipya (27)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Agano la Kale (39)')),
                          selected: _selectedTestamentIndex == 0,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceLow,
                          labelStyle: TextStyle(
                            color: _selectedTestamentIndex == 0 ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => _selectedTestamentIndex = 0);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Agano Jipya (27)')),
                          selected: _selectedTestamentIndex == 1,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceLow,
                          labelStyle: TextStyle(
                            color: _selectedTestamentIndex == 1 ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => _selectedTestamentIndex = 1);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search input
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tafuta kitabu...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) {
                      setModalState(() => _searchQuery = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Books Grid
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Hakuna kitabu kilichopatikana'))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.8,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, idx) {
                              final book = filtered[idx];
                              final isSelected = _currentBook?.bookNumber == book.bookNumber;

                              return InkWell(
                                onTap: () {
                                  AppHaptics.lightImpact();
                                  _stopAudio();
                                  setState(() {
                                    _currentBook = book;
                                    _currentChapter = book.chapters.isNotEmpty ? book.chapters.first : null;
                                  });
                                  Navigator.pop(ctx);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryContainer : AppColors.surfaceLow,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          book.bookName,
                                          style: AppTypography.bodyMedium(
                                            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                          ).copyWith(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${book.chapters.length}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChapterSelector() {
    if (_currentBook == null) return;
    AppHaptics.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_currentBook!.bookName} — Chagua Sura',
                style: AppTypography.titleMedium(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _currentBook!.chapters.length,
                  itemBuilder: (context, idx) {
                    final chap = _currentBook!.chapters[idx];
                    final isSelected = _currentChapter?.chapterNumber == chap.chapterNumber;

                    return InkWell(
                      onTap: () {
                        AppHaptics.lightImpact();
                        _stopAudio();
                        setState(() => _currentChapter = chap);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          chap.chapterNumber,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTenziSelector() {
    AppHaptics.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _tenziList.where((h) {
              final matchNum = h.number.toString().contains(_tenziSearchQuery.trim());
              final matchTitle = h.title.toLowerCase().contains(_tenziSearchQuery.toLowerCase());
              return matchNum || matchTitle;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kitabu cha Tenzi za Rohoni',
                        style: AppTypography.titleMedium(color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tafuta kwa namba (k.m. 8, 24) au jina...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) {
                      setModalState(() => _tenziSearchQuery = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final hymn = filtered[idx];
                        final isSel = _selectedTenzi?.number == hymn.number;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSel ? AppColors.primary : AppColors.surfaceLow,
                            foregroundColor: isSel ? AppColors.textWhite : AppColors.textPrimary,
                            child: Text('${hymn.number}'),
                          ),
                          title: Text(
                            hymn.title,
                            style: TextStyle(
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text('${hymn.category} • ${hymn.key}'),
                          onTap: () {
                            AppHaptics.lightImpact();
                            _stopAudio();
                            setState(() => _selectedTenzi = hymn);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChurchThemeService(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _activeModuleIndex == 0 ? 'Biblia' : 'Tenzi',
              style: AppTypography.titleMedium(color: AppColors.textPrimary),
            ),
            Text(
              _activeModuleIndex == 0
                  ? '${_currentBook?.bookName ?? ''} ${_currentChapter?.chapterNumber ?? ''}'
                  : '${_selectedTenzi?.number ?? ''}. ${_selectedTenzi?.title ?? ''}',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Module Switcher Toggle (Bible vs Tenzi)
          IconButton(
            icon: Icon(
              _activeModuleIndex == 0 ? Icons.music_note_rounded : Icons.menu_book_rounded,
              color: AppColors.primary,
            ),
            tooltip: _activeModuleIndex == 0 ? 'Fungua Tenzi' : 'Fungua Biblia',
            onPressed: () {
              AppHaptics.lightImpact();
              _stopAudio();
              setState(() {
                _activeModuleIndex = _activeModuleIndex == 0 ? 1 : 0;
              });
            },
          ),
          // Font size controls
          IconButton(
            icon: const Icon(Icons.text_fields_rounded),
            tooltip: 'Ukubwa wa Maandishi',
            onPressed: () {
              setState(() {
                _fontSize = _fontSize == 16.0 ? 19.0 : _fontSize == 19.0 ? 22.0 : 16.0;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _activeModuleIndex == 0 ? _buildBibleView() : _buildTenziView(),
                if (_activeModuleIndex == 0 && _selectedVerseIndex != null)
                  _buildScriptureActionDock(),
                if (_isPlayingAudio) _buildFloatingAudioDock(),
              ],
            ),
        );
      },
    );
  }

  // =========================================================================
  // MODULE 1: BIBLIA VIEW
  // =========================================================================
  Widget _buildBibleView() {
    if (_swBooks.isEmpty) {
      return EmptyStateView(
        icon: Icons.menu_book_rounded,
        title: 'Biblia Haikupatikana',
        description: 'Hakikisha faili za Biblia zimepakiwa kwa usahihi.',
        actionLabel: 'Jaribu Tena',
        onAction: _loadAllData,
      );
    }

    return Column(
      children: [
        // Navigation bar: Book Picker + Chapter Picker + Translation Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Row(
            children: [
              // Book button (High contrast guaranteed)
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _showBookSelector,
                  icon: const Icon(Icons.auto_stories_rounded, size: 16, color: AppColors.primary),
                  label: Text(
                    _currentBook?.bookName ?? 'Chagua Kitabu',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLow,
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.border, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Chapter button
              OutlinedButton(
                onPressed: _showChapterSelector,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLow,
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.border, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'Sura ${_currentChapter?.chapterNumber ?? "1"}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Translation Toggle
              PopupMenuButton<String>(
                icon: const Icon(Icons.translate_rounded, color: AppColors.primary),
                tooltip: 'Badili Tafsiri',
                onSelected: (val) {
                  _stopAudio();
                  setState(() => _currentTranslation = val);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'sw', child: Text('Kiswahili (SUV)')),
                  const PopupMenuItem(value: 'kjv', child: Text('English (KJV)')),
                  const PopupMenuItem(value: 'parallel', child: Text('Bilingual (Sambamba)')),
                ],
              ),
              const SizedBox(width: 4),

              // Chapter Audio Toggle
              IconButton(
                icon: Icon(
                  _isPlayingAudio ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                  color: _isPlayingAudio ? Colors.redAccent : AppColors.primary,
                ),
                tooltip: _isPlayingAudio ? 'Simamisha Sauti' : 'Sikiliza Sura Hii',
                onPressed: () {
                  if (_isPlayingAudio) {
                    _stopAudio();
                  } else {
                    _playVerseAudio(0);
                  }
                },
              ),

              // Offline Download / Status Badge
              _isDownloadingChapter
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : InkWell(
                      onTap: _toggleDownloadChapter,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isCurrentChapterDownloaded
                              ? const Color(0xFF16A34A).withOpacity(0.12)
                              : AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isCurrentChapterDownloaded
                                ? const Color(0xFF16A34A).withOpacity(0.3)
                                : AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isCurrentChapterDownloaded ? Icons.cloud_done_rounded : Icons.download_rounded,
                              size: 13,
                              color: _isCurrentChapterDownloaded ? const Color(0xFF16A34A) : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isCurrentChapterDownloaded ? '✓ Offline' : 'Pakua',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isCurrentChapterDownloaded ? const Color(0xFF16A34A) : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),

        // Verses List
        Expanded(
          child: _currentChapter == null
              ? const Center(child: Text('Chagua sura kusoma'))
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 190.0 + MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: _currentChapter!.verses.length,
                  itemBuilder: (context, idx) {
                    final swVerse = _currentChapter!.verses[idx];
                    final isSpeaking = _isPlayingAudio && _activeSpeakingVerseIndex == idx;
                    final refKey = '${_currentBook?.bookNumber}:${_currentChapter?.chapterNumber}:${swVerse.verseNumber}';
                    final isBookmarked = _bookmarkedVerses.contains(refKey);

                    // English counterpart for parallel mode
                    final kjvBook = _kjvBooks.firstWhere(
                      (b) => b.bookNumber == _currentBook?.bookNumber,
                      orElse: () => _currentBook!,
                    );
                    final kjvChapter = kjvBook.chapters.firstWhere(
                      (c) => c.chapterNumber == _currentChapter?.chapterNumber,
                      orElse: () => _currentChapter!,
                    );
                    final kjvVerse = idx < kjvChapter.verses.length ? kjvChapter.verses[idx] : null;

                    final isSelected = _selectedVerseIndex == idx;
                    final hlIndex = _verseHighlights[refKey];
                    final isDark = ChurchThemeService().isDarkMode;
                    Color? verseBg;
                    if (isSpeaking) {
                      verseBg = AppColors.primaryContainer.withOpacity(isDark ? 0.4 : 0.2);
                    } else if (isSelected) {
                      verseBg = AppColors.primary.withOpacity(isDark ? 0.25 : 0.12);
                    } else if (hlIndex != null) {
                      switch (hlIndex) {
                        case 0:
                          verseBg = isDark ? const Color(0xFF78350F).withOpacity(0.45) : const Color(0xFFFEF3C7);
                          break;
                        case 1:
                          verseBg = isDark ? const Color(0xFF064E3B).withOpacity(0.45) : const Color(0xFFD1FAE5);
                          break;
                        case 2:
                          verseBg = isDark ? const Color(0xFF1E3A8A).withOpacity(0.45) : const Color(0xFFDBEAFE);
                          break;
                        case 3:
                          verseBg = isDark ? const Color(0xFF881337).withOpacity(0.45) : const Color(0xFFFFE4E6);
                          break;
                      }
                    }

                    return InkWell(
                      onTap: () {
                        AppHaptics.selectionClick();
                        setState(() {
                          if (_selectedVerseIndex == idx) {
                            _selectedVerseIndex = null;
                            _showHighlightPicker = false;
                          } else {
                            _selectedVerseIndex = idx;
                            _showHighlightPicker = false;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: verseBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSpeaking
                                ? AppColors.primary
                                : isSelected
                                    ? AppColors.primary
                                    : (hlIndex != null
                                        ? AppColors.gold.withOpacity(0.3)
                                        : Colors.transparent),
                            width: isSpeaking ? 2 : (isSelected ? 1.5 : (hlIndex != null ? 1 : 0)),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Compact Verse Number Pill
                            Container(
                              margin: const EdgeInsets.only(top: 2, right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isSpeaking || isSelected)
                                    ? AppColors.primary
                                    : isBookmarked
                                        ? AppColors.gold
                                        : AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                swVerse.verseNumber.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: (isSpeaking || isSelected || isBookmarked)
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),

                            // Pure Scripture Typography (Free of icon clutter)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_currentTranslation == 'parallel') ...[
                                    Text(
                                      swVerse.verseText,
                                      style: AppTypography.scriptureVerse(
                                        fontSize: _fontSize,
                                        fontStyle: FontStyle.normal,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (kjvVerse != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        kjvVerse.verseText,
                                        style: AppTypography.scriptureVerse(
                                          fontSize: _fontSize - 1,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ] else if (_currentTranslation == 'kjv') ...[
                                    Text(
                                      kjvVerse?.verseText ?? swVerse.verseText,
                                      style: AppTypography.scriptureVerse(
                                        fontSize: _fontSize,
                                        fontStyle: FontStyle.normal,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      swVerse.verseText,
                                      style: AppTypography.scriptureVerse(
                                        fontSize: _fontSize,
                                        fontStyle: FontStyle.normal,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // =========================================================================
  // SCRIPTURE CONTEXTUAL ACTION DOCK (YouVersion Tap-to-Action Pattern)
  // =========================================================================
  Widget _buildScriptureActionDock() {
    if (_currentChapter == null ||
        _selectedVerseIndex == null ||
        _selectedVerseIndex! >= _currentChapter!.verses.length) {
      return const SizedBox.shrink();
    }

    final verse = _currentChapter!.verses[_selectedVerseIndex!];
    final refKey = '${_currentBook?.bookNumber}:${_currentChapter?.chapterNumber}:${verse.verseNumber}';
    final isBookmarked = _bookmarkedVerses.contains(refKey);
    final ref = '${_currentBook?.bookName} ${_currentChapter?.chapterNumber}:${verse.verseNumber}';

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24.0 + MediaQuery.of(context).padding.bottom,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
        shadowColor: Colors.black.withOpacity(0.35),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Reference chip + dismiss button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📖 $ref',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      AppHaptics.selectionClick();
                      setState(() {
                        _selectedVerseIndex = null;
                        _showHighlightPicker = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),

              // Highlight palette row (shown on toggle)
              if (_showHighlightPicker) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColorDot(refKey, 0, const Color(0xFFF59E0B), 'Dhahabu'),
                    _buildColorDot(refKey, 1, const Color(0xFF10B981), 'Kijani'),
                    _buildColorDot(refKey, 2, const Color(0xFF0D52CD), 'Bluu'),
                    _buildColorDot(refKey, 3, const Color(0xFFE11D48), 'Waridi'),
                    TextButton(
                      onPressed: () => _setHighlight(refKey, -1),
                      child: const Text('Futa', style: TextStyle(fontSize: 11, color: Colors.red)),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Contextual Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.palette_rounded,
                    label: 'Rangi',
                    color: AppColors.goldDark,
                    onTap: () {
                      AppHaptics.lightImpact();
                      setState(() => _showHighlightPicker = !_showHighlightPicker);
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.edit_note_rounded,
                    label: 'Dokezo',
                    color: AppColors.primary,
                    onTap: () => _openNoteDialogForVerse(verse),
                  ),
                  _buildActionButton(
                    icon: Icons.copy_rounded,
                    label: 'Nakili',
                    color: AppColors.textPrimary,
                    onTap: () {
                      AppHaptics.lightImpact();
                      final text = '"${verse.verseText}" - $ref (Zion Jerusalem)';
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mstari umenakiliwa!')),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    label: 'Shiriki',
                    color: const Color(0xFF16A34A),
                    onTap: () {
                      AppHaptics.lightImpact();
                      final text = '*Biblia Takatifu — $ref*\n\n"${verse.verseText}"\n\n_Sayuni Jerusalem Church_';
                      Share.share(text);
                    },
                  ),
                  _buildActionButton(
                    icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    label: 'Alamisho',
                    color: isBookmarked ? AppColors.gold : AppColors.textSecondary,
                    onTap: () {
                      AppHaptics.lightImpact();
                      setState(() {
                        if (isBookmarked) {
                          _bookmarkedVerses.remove(refKey);
                        } else {
                          _bookmarkedVerses.add(refKey);
                        }
                      });
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.volume_up_rounded,
                    label: 'Sikiliza',
                    color: AppColors.primary,
                    onTap: () => _playVerseAudio(_selectedVerseIndex!),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(String refKey, int colorIdx, Color color, String tooltip) {
    final isSelected = _verseHighlights[refKey] == colorIdx;
    return InkWell(
      onTap: () => _setHighlight(refKey, colorIdx),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.white,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // MODULE 2: TENZI ZA ROHONI VIEW
  // =========================================================================
  Widget _buildTenziView() {
    if (_tenziList.isEmpty) {
      return EmptyStateView(
        icon: Icons.music_note_rounded,
        title: 'Tenzi Hazikupatikana',
        description: 'Faili za Tenzi za Rohoni zinapakiwa...',
        actionLabel: 'Pakia Tena',
        onAction: _loadAllData,
      );
    }

    final hymn = _selectedTenzi ?? _tenziList.first;

    return Column(
      children: [
        // Top selector bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showTenziSelector,
                  icon: const Icon(Icons.music_note_rounded, size: 16),
                  label: Text(
                    'Tenzi #${hymn.number} — ${hymn.title}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {
                  AppHaptics.lightImpact();
                  final text = '*Tenzi #${hymn.number} — ${hymn.title}* (${hymn.key})\n\n${hymn.stanzas.first.text}\n\n_Sayuni Jerusalem Church_';
                  Share.share(text);
                },
              ),
            ],
          ),
        ),

        // Hymn details & lyrics
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 190.0 + MediaQuery.of(context).padding.bottom),
            children: [
              // Header Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tenzi #${hymn.number}',
                            style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(hymn.key, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                        const SizedBox(width: 8),
                        Text(hymn.timeSignature, style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hymn.title,
                      style: AppTypography.headlineMedium(color: AppColors.textPrimary),
                    ),
                    Text(
                      hymn.category,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stanzas
              ...hymn.stanzas.map((stanza) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.primary,
                        child: Text('${stanza.verseNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          stanza.text,
                          style: AppTypography.scriptureVerse(
                            fontSize: _fontSize,
                            fontStyle: FontStyle.normal,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Chorus
              if (hymn.chorus != null && hymn.chorus!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 8, bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(color: AppColors.primary, width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KIKWAGIZO (CHORUS)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hymn.chorus!,
                        style: AppTypography.scriptureVerse(
                          fontSize: _fontSize,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // FLOATING AUDIO TTS DOCK
  // =========================================================================
  Widget _buildFloatingAudioDock() {
    return Positioned(
      bottom: (_selectedVerseIndex != null ? 96.0 : 16.0) + MediaQuery.of(context).padding.bottom,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B24),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.volume_up_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentBook?.bookName} ${_currentChapter?.chapterNumber} : Mstari ${(_activeSpeakingVerseIndex ?? 0) + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isCurrentChapterDownloaded ? '✓ Sura ya Offline • Inasoma kwa sauti' : 'Inasoma kwa sauti...',
                    style: TextStyle(
                      color: _isCurrentChapterDownloaded ? const Color(0xFF4ADE80) : Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                AppHaptics.selectionClick();
                setState(() {
                  _speechRate = _speechRate == 0.5 ? 0.6 : _speechRate == 0.6 ? 0.4 : 0.5;
                });
                await _flutterTts.setSpeechRate(_speechRate);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _speechRate == 0.5 ? '1.0x' : _speechRate == 0.6 ? '1.2x' : '0.8x',
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _isAudioPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: Colors.white,
              ),
              onPressed: _togglePlayPause,
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: _stopAudio,
            ),
          ],
        ),
      ),
    );
  }
}
