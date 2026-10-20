import React, { useState, useEffect, useRef } from 'react';
import { 
  Search, 
  Volume2, 
  VolumeX, 
  Bookmark, 
  Copy, 
  Check, 
  ChevronLeft, 
  ChevronRight, 
  Loader2,
  BookOpen,
  Music,
  Share2,
  Play,
  Pause,
  SkipForward,
  SkipBack,
  Columns,
  Sparkles,
  Square,
  Download,
  Trash2,
  CheckCircle2
} from 'lucide-react';
import type { Language, UserRole, BibleBook, TenziHymn } from '../types';
import { 
  synthesizeGeminiVoice, 
  prefetchGeminiVoice, 
  downloadChapterAudio,
  type GeminiVoiceName,
  type VerseLocation
} from '../services/geminiAudioService';
import { 
  getChapterDownloadStats, 
  deleteChapterAudio 
} from '../services/offlineAudioStorage';
import { synthesizePuterSpeech } from '../services/puterTtsService';

interface BibleIndexItem {
  number: number;
  swahili_name: string;
  english_name: string;
  testament: 'Old' | 'New';
  chapters: number;
  kjv_chapters: number;
}

interface BibleReaderProps {
  language: Language;
  userRole: UserRole;
}

type TranslationMode = 'sw' | 'kjv' | 'web' | 'parallel';

export const BibleReader: React.FC<BibleReaderProps> = ({
  language
}) => {
  const isSw = language === 'sw';

  // Navigation Tabs: Bible vs Tenzi za Rohoni
  const [activeModule, setActiveModule] = useState<'bible' | 'tenzi'>('bible');

  // Bible Index & State
  const [bibleIndex, setBibleIndex] = useState<BibleIndexItem[]>([]);
  const [selectedBookNumber, setSelectedBookNumber] = useState<number>(40); // Default: Mathayo (40)
  const [selectedChapterNumber, setSelectedChapterNumber] = useState<string>('1');
  const [testamentFilter, setTestamentFilter] = useState<'All' | 'Old' | 'New'>('New');
  const [translation, setTranslation] = useState<TranslationMode>('sw');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [fontSize, setFontSize] = useState<number>(16);

  // Active book data
  const [swBook, setSwBook] = useState<BibleBook | null>(null);
  const [enBook, setEnBook] = useState<BibleBook | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  // Bookmarks & Copy
  const [bookmarkedVerses, setBookmarkedVerses] = useState<string[]>([]);
  const [copiedVerse, setCopiedVerse] = useState<string | null>(null);

  // Tenzi za Rohoni State
  const [tenziList, setTenziList] = useState<TenziHymn[]>([]);
  const [selectedTenziNumber, setSelectedTenziNumber] = useState<number>(8); // Default: Chakutumaini Sina (8)
  const [tenziSearch, setTenziSearch] = useState<string>('');
  const [tenziCategory, setTenziCategory] = useState<string>('All');
  const [copiedHymn, setCopiedHymn] = useState<boolean>(false);

  // Audio / TTS Engine State (Multi-tier: Gemini 2.5 Flash, Puter AI, Native)
  type VoiceEngine = 'gemini-charon' | 'gemini-aoede' | 'gemini-kore' | 'puter' | 'native';
  const [voiceEngine, setVoiceEngine] = useState<VoiceEngine>('gemini-charon');
  const [isPlayingAudio, setIsPlayingAudio] = useState<boolean>(false);
  const [isAudioPaused, setIsAudioPaused] = useState<boolean>(false);
  const [isGeneratingSpeech, setIsGeneratingSpeech] = useState<boolean>(false);
  const [engineNotice, setEngineNotice] = useState<string | null>(null);
  const [activeSpeakingVerse, setActiveSpeakingVerse] = useState<number | null>(null);
  const [audioSpeed, setAudioSpeed] = useState<number>(1.0);
  const [autoAdvance, setAutoAdvance] = useState<boolean>(true);

  const activeVerseRef = useRef<HTMLDivElement | null>(null);
  const currentAudioRef = useRef<HTMLAudioElement | null>(null);
  const playbackSessionRef = useRef<number>(0);
  const isPlayingRef = useRef<boolean>(false);
  const isPausedRef = useRef<boolean>(false);

  // Offline Chapter Audio Download States
  const [isDownloadingChapter, setIsDownloadingChapter] = useState<boolean>(false);
  const [downloadProgress, setDownloadProgress] = useState<{ downloaded: number; total: number; percent: number } | null>(null);
  const [isChapterDownloaded, setIsChapterDownloaded] = useState<boolean>(false);
  const [chapterStorageSize, setChapterStorageSize] = useState<string | null>(null);
  const downloadAbortRef = useRef<boolean>(false);

  // Load Bible Index & Tenzi on mount
  useEffect(() => {
    fetch('/data/bible_index.json')
      .then(res => res.json())
      .then(data => {
        setBibleIndex(data);
      })
      .catch(err => console.error('Error loading bible_index.json', err));

    fetch('/data/tenzi_za_rohoni.json')
      .then(res => res.json())
      .then(data => {
        setTenziList(data);
      })
      .catch(err => console.error('Error loading tenzi_za_rohoni.json', err));
  }, []);

  // Cleanup audio on unmount
  useEffect(() => {
    return () => {
      stopAudio();
    };
  }, []);

  // Load Book JSON whenever selectedBookNumber or translation changes
  useEffect(() => {
    setIsLoading(true);
    stopAudio();

    const promises: Promise<void>[] = [];

    // Load Swahili version
    promises.push(
      fetch(`/data/books/sw/${selectedBookNumber}.json`)
        .then(res => res.json())
        .then(data => setSwBook(data))
        .catch(err => console.error('Error loading swahili book', err))
    );

    // If English or Parallel, load KJV
    const englishSource = translation === 'web' ? 'web' : 'kjv';
    promises.push(
      fetch(`/data/books/${englishSource}/${selectedBookNumber}.json`)
        .then(res => res.json())
        .then(data => setEnBook(data))
        .catch(err => console.error('Error loading english book', err))
    );

    Promise.all(promises).then(() => {
      setIsLoading(false);
    });
  }, [selectedBookNumber, translation]);

  // Current Chapter Verses
  const currentSwChapter = swBook?.CHAPTER.find(c => c.chapter_number === selectedChapterNumber) || swBook?.CHAPTER[0];
  const currentEnChapter = enBook?.CHAPTER.find(c => c.chapter_number === selectedChapterNumber) || enBook?.CHAPTER[0];
  const activeBookMeta = bibleIndex.find(b => b.number === selectedBookNumber);

  // Refresh offline audio status for current chapter
  const refreshChapterOfflineStatus = () => {
    const verses = currentSwChapter?.VERSES || [];
    if (verses.length > 0 && voiceEngine.startsWith('gemini-')) {
      const vName: GeminiVoiceName = voiceEngine === 'gemini-aoede'
        ? 'Aoede'
        : voiceEngine === 'gemini-kore'
          ? 'Kore'
          : 'Charon';
      const cNum = parseInt(selectedChapterNumber, 10) || 1;
      getChapterDownloadStats(selectedBookNumber, cNum, verses.length, vName).then(stats => {
        setIsChapterDownloaded(stats.isComplete);
        if (stats.downloadedCount > 0) {
          const mb = (stats.totalBytes / (1024 * 1024)).toFixed(1);
          setChapterStorageSize(`${mb} MB`);
        } else {
          setChapterStorageSize(null);
        }
      });
    } else {
      setIsChapterDownloaded(false);
      setChapterStorageSize(null);
    }
  };

  useEffect(() => {
    refreshChapterOfflineStatus();
  }, [selectedBookNumber, selectedChapterNumber, currentSwChapter, voiceEngine]);

  // Handler to batch download entire chapter for 100% offline playback
  const handleDownloadChapter = async () => {
    const verses = currentSwChapter?.VERSES || [];
    if (verses.length === 0 || !voiceEngine.startsWith('gemini-')) return;

    const vName: GeminiVoiceName = voiceEngine === 'gemini-aoede'
      ? 'Aoede'
      : voiceEngine === 'gemini-kore'
        ? 'Kore'
        : 'Charon';

    const cNum = parseInt(selectedChapterNumber, 10) || 1;
    downloadAbortRef.current = false;
    setIsDownloadingChapter(true);
    setDownloadProgress({ downloaded: 0, total: verses.length, percent: 0 });

    try {
      const result = await downloadChapterAudio(
        selectedBookNumber,
        cNum,
        verses.map(v => ({ verse_number: parseInt(v.verse_number, 10) || 1, verse_text: v.verse_text })),
        vName,
        (prog) => {
          setDownloadProgress({
            downloaded: prog.downloaded,
            total: prog.total,
            percent: prog.percent
          });
        },
        () => downloadAbortRef.current
      );

      if (result.success) {
        refreshChapterOfflineStatus();
      }
    } catch (err) {
      console.warn('Chapter offline download error:', err);
    } finally {
      setIsDownloadingChapter(false);
      setDownloadProgress(null);
    }
  };

  const handleCancelDownload = () => {
    downloadAbortRef.current = true;
    setIsDownloadingChapter(false);
    setDownloadProgress(null);
  };

  const handleDeleteDownloadedChapter = async () => {
    const vName: GeminiVoiceName = voiceEngine === 'gemini-aoede'
      ? 'Aoede'
      : voiceEngine === 'gemini-kore'
        ? 'Kore'
        : 'Charon';
    const cNum = parseInt(selectedChapterNumber, 10) || 1;
    await deleteChapterAudio(selectedBookNumber, cNum, vName);
    refreshChapterOfflineStatus();
  };

  // Handle Chapter change
  const handleChapterChange = (newChapNum: string) => {
    stopAudio();
    setSelectedChapterNumber(newChapNum);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleNextChapter = () => {
    if (!activeBookMeta) return;
    const currentNum = parseInt(selectedChapterNumber, 10);
    if (currentNum < activeBookMeta.chapters) {
      handleChapterChange(String(currentNum + 1));
    } else if (selectedBookNumber < 66) {
      setSelectedBookNumber(selectedBookNumber + 1);
      handleChapterChange('1');
    }
  };

  const handlePrevChapter = () => {
    const currentNum = parseInt(selectedChapterNumber, 10);
    if (currentNum > 1) {
      handleChapterChange(String(currentNum - 1));
    } else if (selectedBookNumber > 1) {
      const prevMeta = bibleIndex.find(b => b.number === selectedBookNumber - 1);
      setSelectedBookNumber(selectedBookNumber - 1);
      handleChapterChange(String(prevMeta ? prevMeta.chapters : 1));
    }
  };

  // Toggle Bookmark
  const toggleBookmark = (verseNum: string) => {
    const ref = `${selectedBookNumber}:${selectedChapterNumber}:${verseNum}`;
    setBookmarkedVerses(prev => 
      prev.includes(ref) ? prev.filter(v => v !== ref) : [...prev, ref]
    );
  };

  // Copy Verse
  const copyVerse = (verseNum: string, swText: string, enText?: string) => {
    const bookTitle = isSw ? (activeBookMeta?.swahili_name || swBook?.book_name) : (activeBookMeta?.english_name || enBook?.book_name);
    let full = `"${swText.trim()}" - ${bookTitle} ${selectedChapterNumber}:${verseNum} (Sayuni Jerusalem Church)`;
    if (translation === 'parallel' && enText) {
      full += `\nKJV: "${enText.trim()}"`;
    }
    navigator.clipboard.writeText(full);
    setCopiedVerse(verseNum);
    setTimeout(() => setCopiedVerse(null), 2000);
  };

  // Share to WhatsApp
  const shareVerseWhatsApp = (verseNum: string, swText: string, enText?: string) => {
    const bookTitle = activeBookMeta?.swahili_name || swBook?.book_name;
    let msg = `*Biblia Takatifu — ${bookTitle} ${selectedChapterNumber}:${verseNum}*\n\n"${swText.trim()}"`;
    if (enText) {
      msg += `\n\n_English (KJV):_\n"${enText.trim()}"`;
    }
    msg += `\n\n_Sayuni Jerusalem Church — Mbagala Kwa Matope_`;
    const url = `https://wa.me/?text=${encodeURIComponent(msg)}`;
    window.open(url, '_blank');
  };

  // =========================================================================
  // MULTI-TIER AUDIO / TTS ENGINE (Gemini 2.5 Studio, Puter AI & Native)
  // =========================================================================
  const stopAudio = () => {
    // 1. Invalidate all running promises, sessions, and async callbacks immediately
    playbackSessionRef.current++;
    isPlayingRef.current = false;
    isPausedRef.current = false;

    // 2. Kill current HTML5 Audio cleanly without firing onended or continuing
    if (currentAudioRef.current) {
      const audio = currentAudioRef.current;
      audio.onplay = null;
      audio.onended = null;
      audio.onerror = null;
      audio.onpause = null;
      audio.pause();
      audio.currentTime = 0;
      audio.src = '';
      currentAudioRef.current = null;
    }

    // 3. Cancel browser native speech synthesis
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
    }

    // 4. Update UI states synchronously
    setIsPlayingAudio(false);
    setIsAudioPaused(false);
    setIsGeneratingSpeech(false);
    setActiveSpeakingVerse(null);
  };

  const fallbackToNative = (verseIndex: number, textToSpeak: string, sessionId: number) => {
    if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) return;

    if (!('speechSynthesis' in window)) {
      stopAudio();
      return;
    }

    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(textToSpeak);
    utterance.lang = (translation === 'kjv' || translation === 'web') ? 'en-US' : 'sw-TZ';
    utterance.rate = audioSpeed;
    utterance.pitch = 1.0;

    utterance.onstart = () => {
      if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
        window.speechSynthesis.cancel();
        return;
      }
      setIsGeneratingSpeech(false);
      setIsPlayingAudio(true);
      setIsAudioPaused(false);
      setActiveSpeakingVerse(verseIndex + 1);
      setTimeout(() => {
        if (activeVerseRef.current) {
          activeVerseRef.current.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      }, 50);
    };

    utterance.onend = () => {
      // ONLY advance if this session is still active and stop/pause was NOT requested
      if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
        return;
      }
      const verses = currentSwChapter?.VERSES || [];
      if (autoAdvance && verseIndex + 1 < verses.length) {
        playVerseAudio(verseIndex + 1);
      } else {
        stopAudio();
      }
    };

    utterance.onerror = () => {
      if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) return;
      stopAudio();
    };

    window.speechSynthesis.speak(utterance);
  };

  const playVerseAudio = async (verseIndex: number) => {
    const verses = currentSwChapter?.VERSES || [];
    if (verseIndex < 0 || verseIndex >= verses.length) {
      stopAudio();
      return;
    }

    // New unique playback session
    const sessionId = ++playbackSessionRef.current;
    isPlayingRef.current = true;
    isPausedRef.current = false;

    // Stop any existing playback
    if (currentAudioRef.current) {
      const a = currentAudioRef.current;
      a.onplay = null;
      a.onended = null;
      a.onerror = null;
      a.onpause = null;
      a.pause();
      a.currentTime = 0;
      a.src = '';
      currentAudioRef.current = null;
    }
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
    }

    const verseObj = verses[verseIndex];
    const enVerseObj = currentEnChapter?.VERSES[verseIndex];

    const textToSpeak = translation === 'kjv' || translation === 'web'
      ? (enVerseObj?.verse_text || verseObj.verse_text)
      : verseObj.verse_text;

    const loc: VerseLocation = {
      bookNumber: selectedBookNumber,
      chapterNumber: parseInt(selectedChapterNumber, 10) || 1,
      verseNumber: parseInt(verseObj.verse_number, 10) || (verseIndex + 1)
    };

    // Tier 1: Gemini Studio Voices with 15-Key Load-Balanced Pool
    if (voiceEngine.startsWith('gemini-')) {
      const vName: GeminiVoiceName = voiceEngine === 'gemini-aoede'
        ? 'Aoede'
        : voiceEngine === 'gemini-kore'
          ? 'Kore'
          : 'Charon';

      setIsGeneratingSpeech(true);
      setActiveSpeakingVerse(verseIndex + 1);

      try {
        const wavUrl = await synthesizeGeminiVoice(textToSpeak, vName, loc);

        // ABORT if user pressed stop or pause while fetching from Gemini!
        if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
          return;
        }

        const audio = new Audio(wavUrl);
        currentAudioRef.current = audio;
        audio.playbackRate = audioSpeed;

        audio.onplay = () => {
          if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
            audio.pause();
            audio.currentTime = 0;
            return;
          }
          setIsGeneratingSpeech(false);
          setIsPlayingAudio(true);
          setIsAudioPaused(false);
          setActiveSpeakingVerse(verseIndex + 1);
          setTimeout(() => {
            if (activeVerseRef.current) {
              activeVerseRef.current.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
          }, 50);

          // =========================================================================
          // LOOKAHEAD AHEAD-BUFFERING (PREFETCH NEXT VERSES IN BACKGROUND)
          // =========================================================================
          if (autoAdvance && verseIndex + 1 < verses.length) {
            const nextV = verses[verseIndex + 1];
            const nextEnV = currentEnChapter?.VERSES[verseIndex + 1];
            const nextText = translation === 'kjv' || translation === 'web'
              ? (nextEnV?.verse_text || nextV.verse_text)
              : nextV.verse_text;
            const nextLoc: VerseLocation = {
              bookNumber: selectedBookNumber,
              chapterNumber: parseInt(selectedChapterNumber, 10) || 1,
              verseNumber: parseInt(nextV.verse_number, 10) || (verseIndex + 2)
            };
            prefetchGeminiVoice(nextText, vName, nextLoc);

            // Also prefetch verse + 2
            if (verseIndex + 2 < verses.length) {
              const nextV2 = verses[verseIndex + 2];
              const nextEnV2 = currentEnChapter?.VERSES[verseIndex + 2];
              const nextText2 = translation === 'kjv' || translation === 'web'
                ? (nextEnV2?.verse_text || nextV2.verse_text)
                : nextV2.verse_text;
              const nextLoc2: VerseLocation = {
                bookNumber: selectedBookNumber,
                chapterNumber: parseInt(selectedChapterNumber, 10) || 1,
                verseNumber: parseInt(nextV2.verse_number, 10) || (verseIndex + 3)
              };
              prefetchGeminiVoice(nextText2, vName, nextLoc2);
            }
          }
        };

        audio.onended = () => {
          if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
            return;
          }
          if (autoAdvance && verseIndex + 1 < verses.length) {
            playVerseAudio(verseIndex + 1);
          } else {
            stopAudio();
          }
        };

        audio.onerror = () => {
          if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) return;
          console.warn('Gemini audio element playback failed, executing native fallback.');
          fallbackToNative(verseIndex, textToSpeak, sessionId);
        };

        if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
          audio.pause();
          return;
        }

        await audio.play();
        setEngineNotice(null);
      } catch (err: any) {
        if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
          return;
        }
        console.warn('Gemini TTS failed, executing native fallback:', err);
        setEngineNotice(isSw ? 'Inatumia sauti ya dharura ya kifaa' : 'Falling back to device voice');
        setTimeout(() => setEngineNotice(null), 4000);
        fallbackToNative(verseIndex, textToSpeak, sessionId);
      }
      return;
    }

    // Tier 2: Puter Cloud AI
    if (voiceEngine === 'puter') {
      setIsGeneratingSpeech(true);
      setActiveSpeakingVerse(verseIndex + 1);
      try {
        const audio = await synthesizePuterSpeech(textToSpeak, { provider: 'gemini' });

        if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
          return;
        }

        currentAudioRef.current = audio;
        audio.playbackRate = audioSpeed;

        audio.onplay = () => {
          if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
            audio.pause();
            audio.currentTime = 0;
            return;
          }
          setIsGeneratingSpeech(false);
          setIsPlayingAudio(true);
          setIsAudioPaused(false);
          setActiveSpeakingVerse(verseIndex + 1);
          setTimeout(() => {
            if (activeVerseRef.current) {
              activeVerseRef.current.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
          }, 50);
        };

        audio.onended = () => {
          if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) return;
          if (autoAdvance && verseIndex + 1 < verses.length) {
            playVerseAudio(verseIndex + 1);
          } else {
            stopAudio();
          }
        };

        audio.onerror = () => {
          if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) return;
          fallbackToNative(verseIndex, textToSpeak, sessionId);
        };

        if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
          audio.pause();
          return;
        }

        await audio.play();
        setEngineNotice(null);
      } catch (err: any) {
        if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) return;
        console.warn('Puter TTS failed, executing native fallback:', err);
        setEngineNotice(isSw ? 'Inatumia sauti ya kifaa (Puter haijaunganishwa)' : 'Using device voice');
        setTimeout(() => setEngineNotice(null), 4000);
        fallbackToNative(verseIndex, textToSpeak, sessionId);
      }
      return;
    }

    // Tier 3: Native Web Speech
    fallbackToNative(verseIndex, textToSpeak, sessionId);
  };

  const togglePlayPauseChapter = () => {
    // If speech is still being generated by AI, stopping/canceling it is the immediate expected action
    if (isGeneratingSpeech) {
      stopAudio();
      return;
    }

    // If currently playing, pause it immediately
    if (isPlayingAudio && !isAudioPaused) {
      isPausedRef.current = true;
      if (currentAudioRef.current) {
        currentAudioRef.current.pause();
      }
      if ('speechSynthesis' in window) {
        // Cancel native speech to avoid Chrome bug where pause triggers onend
        window.speechSynthesis.cancel();
      }
      setIsAudioPaused(true);
      return;
    }

    // If currently paused, resume it
    if (isPlayingAudio && isAudioPaused) {
      isPausedRef.current = false;
      setIsAudioPaused(false);
      if (voiceEngine === 'native') {
        const startIndex = activeSpeakingVerse ? activeSpeakingVerse - 1 : 0;
        playVerseAudio(startIndex);
        return;
      }
      if (currentAudioRef.current) {
        currentAudioRef.current.play().catch(() => {
          const startIndex = activeSpeakingVerse ? activeSpeakingVerse - 1 : 0;
          playVerseAudio(startIndex);
        });
      } else {
        const startIndex = activeSpeakingVerse ? activeSpeakingVerse - 1 : 0;
        playVerseAudio(startIndex);
      }
      return;
    }

    // Otherwise start fresh
    const startIndex = activeSpeakingVerse ? activeSpeakingVerse - 1 : 0;
    playVerseAudio(startIndex);
  };

  const skipNextAudioVerse = () => {
    const current = activeSpeakingVerse ? activeSpeakingVerse - 1 : 0;
    playVerseAudio(current + 1);
  };

  const skipPrevAudioVerse = () => {
    const current = activeSpeakingVerse ? activeSpeakingVerse - 1 : 0;
    playVerseAudio(Math.max(0, current - 1));
  };

  // Tenzi Filtering
  const filteredTenzi = tenziList.filter(h => {
    const matchNum = String(h.number).includes(tenziSearch.trim());
    const matchTitle = h.title.toLowerCase().includes(tenziSearch.toLowerCase());
    const matchCategory = tenziCategory === 'All' || h.category === tenziCategory;
    return (matchNum || matchTitle) && matchCategory;
  });

  const selectedHymn = tenziList.find(h => h.number === selectedTenziNumber) || tenziList[0];

  const copyTenziLyrics = (hymn: TenziHymn) => {
    let text = `*Tenzi ya Rohoni #${hymn.number} — ${hymn.title}* (${hymn.key})\n\n`;
    hymn.stanzas.forEach(s => {
      text += `_Ubeti wa ${s.verse_number}:_\n${s.text}\n\n`;
      if (hymn.chorus) {
        text += `_Kikwagizo:_\n${hymn.chorus}\n\n`;
      }
    });
    text += `— Sayuni Jerusalem Church Hymnal`;
    navigator.clipboard.writeText(text);
    setCopiedHymn(true);
    setTimeout(() => setCopiedHymn(false), 2000);
  };

  const reciteTenziAloud = async (hymn: TenziHymn) => {
    stopAudio();
    const sessionId = ++playbackSessionRef.current;
    isPlayingRef.current = true;
    isPausedRef.current = false;
    const fullText = `Tenzi namba ${hymn.number}. ${hymn.title}. ${hymn.stanzas[0].text}. ${hymn.chorus ? `Kikwagizo: ${hymn.chorus}` : ''}`;
    
    setIsGeneratingSpeech(true);
    if (voiceEngine.startsWith('gemini-')) {
      const vName: GeminiVoiceName = voiceEngine === 'gemini-aoede' ? 'Aoede' : voiceEngine === 'gemini-kore' ? 'Kore' : 'Charon';
      try {
        const wavUrl = await synthesizeGeminiVoice(fullText, vName);
        if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) return;

        const audio = new Audio(wavUrl);
        currentAudioRef.current = audio;
        audio.playbackRate = audioSpeed;
        audio.onplay = () => {
          if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
            audio.pause();
            audio.currentTime = 0;
            return;
          }
          setIsGeneratingSpeech(false);
          setIsPlayingAudio(true);
          setIsAudioPaused(false);
        };
        audio.onended = () => stopAudio();
        audio.onerror = () => stopAudio();

        if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) {
          audio.pause();
          return;
        }

        await audio.play();
      } catch (_) {
        if (playbackSessionRef.current !== sessionId || !isPlayingRef.current || isPausedRef.current) return;
        fallbackToNative(0, fullText, sessionId);
      }
    } else {
      fallbackToNative(0, fullText, sessionId);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', paddingBottom: isPlayingAudio ? '5rem' : '1rem' }}>
      {/* Top Banner Navigation */}
      <div className="church-card" style={{ padding: '1.25rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.35rem' }}>
            <span className="badge badge-purple">
              <BookOpen size={13} />
              <span>{isSw ? 'Maktaba ya Kiroho & Ibada' : 'Scripture & Worship'}</span>
            </span>
            <span className="badge badge-emerald">
              <Sparkles size={12} />
              <span>{isSw ? 'Vitabu 66 Kamili + Tenzi 161' : 'Complete 66 Books + Hymns'}</span>
            </span>
          </div>
          <h2 style={{ fontSize: '1.6rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
            {activeModule === 'bible' ? (isSw ? 'Biblia Takatifu (SUV & KJV)' : 'Holy Scriptures (SUV & KJV)') : (isSw ? 'Tenzi za Rohoni (Kitabu cha Nyimbo)' : 'Swahili Hymnal')}
          </h2>
        </div>

        {/* Module Segmented Control: Biblia vs Tenzi */}
        <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
          <div className="role-switcher-segmented">
            <button
              onClick={() => {
                stopAudio();
                setActiveModule('bible');
              }}
              className={`role-btn-pill ${activeModule === 'bible' ? 'active' : ''}`}
            >
              <BookOpen size={14} style={{ display: 'inline', marginRight: '4px' }} />
              {isSw ? 'Biblia Takatifu' : 'Holy Bible'}
            </button>
            <button
              onClick={() => {
                stopAudio();
                setActiveModule('tenzi');
              }}
              className={`role-btn-pill ${activeModule === 'tenzi' ? 'active' : ''}`}
            >
              <Music size={14} style={{ display: 'inline', marginRight: '4px' }} />
              {isSw ? 'Tenzi za Rohoni' : 'Hymnal Songs'}
            </button>
          </div>

          {/* Font Resizer */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', backgroundColor: 'var(--surface-container-low)', padding: '0.2rem', borderRadius: 'var(--radius-sm)' }}>
            <button
              onClick={() => setFontSize(Math.max(13, fontSize - 1))}
              className="icon-btn"
              title="Punguza herufi"
              style={{ padding: '0.25rem 0.5rem', fontSize: '0.75rem', fontWeight: 700 }}
            >
              A-
            </button>
            <span style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--on-surface-variant)', padding: '0 0.2rem' }}>{fontSize}px</span>
            <button
              onClick={() => setFontSize(Math.min(26, fontSize + 1))}
              className="icon-btn"
              title="Ongeza herufi"
              style={{ padding: '0.25rem 0.5rem', fontSize: '0.85rem', fontWeight: 700 }}
            >
              A+
            </button>
          </div>
        </div>
      </div>

      {/* =========================================================================
          MODULE 1: BIBLIA TAKATIFU (HOLY BIBLE READER)
          ========================================================================= */}
      {activeModule === 'bible' && (
        <>
          {/* Controls Bar: Translation Switcher + Audio Player Button */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flexWrap: 'wrap' }}>
              {/* Translation Pills */}
              <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--on-surface-variant)' }}>
                {isSw ? 'Tafsiri:' : 'Version:'}
              </span>
              <div className="role-switcher-segmented">
                <button
                  onClick={() => setTranslation('sw')}
                  className={`role-btn-pill ${translation === 'sw' ? 'active' : ''}`}
                  title="Swahili Union Version (Biblia Takatifu ya Kiswahili)"
                >
                  Kiswahili (SUV)
                </button>
                <button
                  onClick={() => setTranslation('kjv')}
                  className={`role-btn-pill ${translation === 'kjv' ? 'active' : ''}`}
                  title="King James Version (English)"
                >
                  English (KJV)
                </button>
                <button
                  onClick={() => setTranslation('web')}
                  className={`role-btn-pill ${translation === 'web' ? 'active' : ''}`}
                  title="World English Bible (Modern English)"
                >
                  English (WEB)
                </button>
                <button
                  onClick={() => setTranslation('parallel')}
                  className={`role-btn-pill ${translation === 'parallel' ? 'active' : ''}`}
                  title="Soma Kiswahili na Kiingereza sambamba mstari kwa mstari"
                >
                  <Columns size={13} style={{ display: 'inline', marginRight: '4px' }} />
                  {isSw ? 'Sambamba (Bilingual)' : 'Parallel'}
                </button>
              </div>
            </div>

            {/* Listen Audio Buttons */}
            <div style={{ display: 'flex', gap: '0.45rem', alignItems: 'center' }}>
              <button
                onClick={togglePlayPauseChapter}
                className={isPlayingAudio ? 'btn-primary' : 'btn-secondary'}
                style={{ display: 'inline-flex', alignItems: 'center', gap: '0.45rem', fontSize: '0.82rem' }}
                title={isPlayingAudio ? (isAudioPaused ? 'Endelea' : 'Pumzisha') : 'Soma Sura Hii'}
              >
                {isGeneratingSpeech ? (
                  <Loader2 size={15} className="animate-spin" />
                ) : isPlayingAudio && !isAudioPaused ? (
                  <Pause size={15} />
                ) : isPlayingAudio && isAudioPaused ? (
                  <Play size={15} />
                ) : (
                  <Volume2 size={15} />
                )}
                <span>
                  {isGeneratingSpeech
                    ? (isSw ? 'Inaandaa Sauti...' : 'Generating Audio...')
                    : isPlayingAudio
                      ? (isAudioPaused ? (isSw ? 'Endelea Kusikiliza' : 'Resume Audio') : (isSw ? 'Pumzisha Sauti' : 'Pause Audio'))
                      : (isSw ? 'Sikiliza Sura Hii (Audio TTS)' : 'Listen to Chapter (Audio)')}
                </span>
              </button>

              {/* Explicit Instant Stop Button */}
              {(isPlayingAudio || isGeneratingSpeech) && (
                <button
                  onClick={stopAudio}
                  className="btn-secondary"
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.35rem',
                    fontSize: '0.82rem',
                    color: '#ef4444',
                    borderColor: 'rgba(239, 68, 68, 0.4)',
                    backgroundColor: 'rgba(239, 68, 68, 0.08)'
                  }}
                  title="Simamisha Sauti Mara Moja (Stop All Audio)"
                >
                  <Square size={13} fill="currentColor" />
                  <span>{isSw ? 'Simamisha' : 'Stop'}</span>
                </button>
              )}

              {/* Offline Chapter Audio Download Button / Badge */}
              {voiceEngine.startsWith('gemini-') && (
                <div>
                  {isDownloadingChapter ? (
                    <div style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '0.45rem',
                      backgroundColor: 'rgba(109, 0, 179, 0.08)',
                      padding: '0.32rem 0.75rem',
                      borderRadius: 'var(--radius-full)',
                      border: '1px solid rgba(109, 0, 179, 0.3)'
                    }}>
                      <Loader2 size={13} className="animate-spin" style={{ color: 'var(--primary)' }} />
                      <span style={{ fontSize: '0.74rem', fontWeight: 600, color: 'var(--primary)' }}>
                        {isSw
                          ? `Inapakua: ${downloadProgress?.downloaded || 0}/${downloadProgress?.total || 0} (${downloadProgress?.percent || 0}%)`
                          : `Downloading: ${downloadProgress?.percent || 0}%`}
                      </span>
                      <button
                        onClick={handleCancelDownload}
                        className="icon-btn"
                        title={isSw ? 'Ghairi kupakua' : 'Cancel download'}
                        style={{ color: '#ef4444', padding: '2px', marginLeft: '2px' }}
                      >
                        <Square size={11} fill="currentColor" />
                      </button>
                    </div>
                  ) : isChapterDownloaded ? (
                    <div style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '0.45rem',
                      backgroundColor: 'rgba(5, 150, 105, 0.08)',
                      padding: '0.32rem 0.75rem',
                      borderRadius: 'var(--radius-full)',
                      border: '1px solid rgba(5, 150, 105, 0.3)'
                    }}>
                      <CheckCircle2 size={14} style={{ color: '#059669' }} />
                      <span style={{ fontSize: '0.74rem', fontWeight: 700, color: '#059669' }}>
                        {isSw ? `Offline (${chapterStorageSize || 'Tayari'})` : `Offline Ready (${chapterStorageSize || ''})`}
                      </span>
                      <button
                        onClick={handleDeleteDownloadedChapter}
                        className="icon-btn"
                        title={isSw ? 'Futa sauti ya sura hii kwenye hifadhi' : 'Delete cached audio'}
                        style={{ color: 'var(--on-surface-variant)', padding: '2px', marginLeft: '2px' }}
                      >
                        <Trash2 size={12} />
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={handleDownloadChapter}
                      className="btn-secondary"
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.4rem',
                        fontSize: '0.82rem',
                        padding: '0.45rem 0.85rem'
                      }}
                      title={isSw ? 'Pakua sura hii nzima ili uisikilize bila intaneti (100% Offline)' : 'Download whole chapter for 100% offline audio playback'}
                    >
                      <Download size={14} style={{ color: 'var(--primary)' }} />
                      <span>{isSw ? 'Pakua Sura (Offline)' : 'Download Chapter'}</span>
                    </button>
                  )}
                </div>
              )}
            </div>
          </div>

          {/* Main Bible Split Layout: Left Nav + Right Text */}
          <div style={{ display: 'grid', gridTemplateColumns: 'minmax(260px, 300px) 1fr', gap: '1.25rem', alignItems: 'start' }}>
            {/* Left Sidebar: Testament Filter, Books List, Chapter Grid */}
            <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '1rem', maxHeight: '82vh', overflowY: 'auto' }}>
              {/* Search Filter */}
              <div style={{ position: 'relative' }}>
                <Search size={15} style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--on-surface-variant)' }} />
                <input
                  type="text"
                  className="form-input"
                  placeholder={isSw ? 'Tafuta kitabu (k.m. Zaburi, Mathayo)...' : 'Search book (e.g. Psalms, Matthew)...'}
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  style={{ paddingLeft: '2.25rem', fontSize: '0.82rem' }}
                />
              </div>

              {/* Testament Tabs: All / Old (39) / New (27) */}
              <div style={{ display: 'flex', gap: '0.25rem', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '0.5rem' }}>
                <button
                  onClick={() => setTestamentFilter('All')}
                  className={`badge ${testamentFilter === 'All' ? 'badge-primary' : 'badge-subtle'}`}
                  style={{ cursor: 'pointer', flex: 1, justifyContent: 'center' }}
                >
                  {isSw ? 'Zote (66)' : 'All (66)'}
                </button>
                <button
                  onClick={() => setTestamentFilter('Old')}
                  className={`badge ${testamentFilter === 'Old' ? 'badge-primary' : 'badge-subtle'}`}
                  style={{ cursor: 'pointer', flex: 1, justifyContent: 'center' }}
                >
                  {isSw ? 'Kale (39)' : 'Old (39)'}
                </button>
                <button
                  onClick={() => setTestamentFilter('New')}
                  className={`badge ${testamentFilter === 'New' ? 'badge-primary' : 'badge-subtle'}`}
                  style={{ cursor: 'pointer', flex: 1, justifyContent: 'center' }}
                >
                  {isSw ? 'Jipya (27)' : 'New (27)'}
                </button>
              </div>

              {/* Book List */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.2rem', maxHeight: '280px', overflowY: 'auto' }}>
                {bibleIndex
                  .filter(b => {
                    const matchQuery = b.swahili_name.toLowerCase().includes(searchQuery.toLowerCase()) || 
                                       b.english_name.toLowerCase().includes(searchQuery.toLowerCase());
                    const matchTestament = testamentFilter === 'All' || b.testament === testamentFilter;
                    return matchQuery && matchTestament;
                  })
                  .map(b => {
                    const isSelected = b.number === selectedBookNumber;
                    return (
                      <button
                        key={b.number}
                        onClick={() => {
                          setSelectedBookNumber(b.number);
                          setSelectedChapterNumber('1');
                        }}
                        style={{
                          textAlign: 'left',
                          padding: '0.45rem 0.65rem',
                          borderRadius: 'var(--radius-sm)',
                          fontSize: '0.82rem',
                          fontWeight: isSelected ? 700 : 500,
                          backgroundColor: isSelected ? 'var(--primary-container)' : 'transparent',
                          color: isSelected ? 'var(--on-primary)' : 'var(--on-surface)',
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'center'
                        }}
                      >
                        <span>{isSw ? b.swahili_name : b.english_name}</span>
                        <span style={{ fontSize: '0.7rem', opacity: 0.75 }}>
                          {b.chapters} sura
                        </span>
                      </button>
                    );
                  })}
              </div>

              {/* Chapters Grid */}
              {activeBookMeta && (
                <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '0.75rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                    <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--on-surface-variant)', textTransform: 'uppercase' }}>
                      {isSw ? 'Chagua Sura' : 'Select Chapter'}
                    </span>
                    <span style={{ fontSize: '0.72rem', color: 'var(--primary)', fontWeight: 600 }}>
                      Sura {selectedChapterNumber} ya {activeBookMeta.chapters}
                    </span>
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '0.35rem', maxHeight: '180px', overflowY: 'auto' }}>
                    {Array.from({ length: activeBookMeta.chapters }, (_, i) => String(i + 1)).map(chapNum => {
                      const isSel = chapNum === selectedChapterNumber;
                      return (
                        <button
                          key={chapNum}
                          onClick={() => handleChapterChange(chapNum)}
                          style={{
                            padding: '0.4rem 0',
                            textAlign: 'center',
                            borderRadius: 'var(--radius-sm)',
                            fontSize: '0.78rem',
                            fontWeight: isSel ? 700 : 500,
                            backgroundColor: isSel ? 'var(--primary)' : 'var(--surface-container-low)',
                            color: isSel ? 'var(--on-primary)' : 'var(--on-surface)',
                            border: isSel ? 'none' : '1px solid var(--border-subtle)'
                          }}
                        >
                          {chapNum}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>

            {/* Right Main Scripture Area */}
            <div className="church-card" style={{ padding: '1.75rem', minHeight: '600px' }}>
              {isLoading ? (
                <div style={{ padding: '4rem', textAlign: 'center' }}>
                  <Loader2 size={36} className="animate-spin" style={{ margin: '0 auto 1rem auto', color: 'var(--primary)' }} />
                  <p style={{ color: 'var(--on-surface-variant)', fontSize: '0.9rem' }}>
                    {isSw ? 'Inapakia maneno ya Mungu...' : 'Loading scriptures...'}
                  </p>
                </div>
              ) : (
                <>
                  {/* Chapter Header Navigation */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '1rem', marginBottom: '1.5rem', flexWrap: 'wrap', gap: '0.75rem' }}>
                    <div>
                      <h1 style={{ fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-headline)', margin: 0 }}>
                        {isSw ? (activeBookMeta?.swahili_name || swBook?.book_name) : (activeBookMeta?.english_name || enBook?.book_name)} {selectedChapterNumber}
                      </h1>
                      <span style={{ fontSize: '0.78rem', color: 'var(--on-surface-variant)' }}>
                        {translation === 'parallel' 
                          ? 'Kiswahili (SUV) & English (KJV) Sambamba' 
                          : translation === 'kjv' ? 'King James Version (English)' 
                          : translation === 'web' ? 'World English Bible (Modern English)' 
                          : 'Biblia Takatifu (Swahili Union Version)'}
                      </span>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <button
                        onClick={handlePrevChapter}
                        className="btn-secondary"
                        style={{ padding: '0.4rem 0.85rem', fontSize: '0.8rem' }}
                        title="Sura Iliyopita"
                      >
                        <ChevronLeft size={15} />
                        <span>{isSw ? 'Iliyopita' : 'Prev'}</span>
                      </button>
                      <button
                        onClick={handleNextChapter}
                        className="btn-secondary"
                        style={{ padding: '0.4rem 0.85rem', fontSize: '0.8rem' }}
                        title="Sura Inayofuata"
                      >
                        <span>{isSw ? 'Inayofuata' : 'Next'}</span>
                        <ChevronRight size={15} />
                      </button>
                    </div>
                  </div>

                  {/* Verses List */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1.1rem' }}>
                    {currentSwChapter?.VERSES.map((swVerse, idx) => {
                      const vNum = parseInt(swVerse.verse_number, 10);
                      const isVerseSpeaking = isPlayingAudio && activeSpeakingVerse === vNum;
                      const enVerse = currentEnChapter?.VERSES[idx];
                      const bookmarkKey = `${selectedBookNumber}:${selectedChapterNumber}:${swVerse.verse_number}`;
                      const isBookmarked = bookmarkedVerses.includes(bookmarkKey);

                      return (
                        <div
                          key={swVerse.verse_number}
                          ref={isVerseSpeaking ? activeVerseRef : null}
                          style={{
                            display: 'flex',
                            gap: '0.85rem',
                            padding: '0.65rem 0.85rem',
                            borderRadius: 'var(--radius-sm)',
                            backgroundColor: isVerseSpeaking 
                              ? 'rgba(109, 0, 179, 0.08)' 
                              : isBookmarked ? 'rgba(197, 155, 39, 0.08)' : 'transparent',
                            borderLeft: isVerseSpeaking 
                              ? '4px solid var(--primary)' 
                              : isBookmarked ? '4px solid var(--border-gold)' : '4px solid transparent',
                            transition: 'all 0.2s ease',
                            fontSize: `${fontSize}px`,
                            lineHeight: 1.75
                          }}
                        >
                          {/* Verse Number */}
                          <span style={{ 
                            fontSize: '0.75rem', 
                            fontWeight: 800, 
                            color: isVerseSpeaking ? 'var(--primary)' : 'var(--on-surface-variant)', 
                            marginTop: '0.2rem',
                            minWidth: '24px'
                          }}>
                            {swVerse.verse_number}
                          </span>

                          {/* Verse Text (Single or Parallel) */}
                          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                            {translation === 'parallel' ? (
                              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                                <div>
                                  <span style={{ display: 'block', fontSize: '0.68rem', fontWeight: 700, color: 'var(--primary)', textTransform: 'uppercase' }}>Kiswahili (SUV)</span>
                                  <p style={{ margin: 0, color: 'var(--on-surface)' }}>{swVerse.verse_text}</p>
                                </div>
                                <div style={{ borderLeft: '1px solid var(--border-subtle)', paddingLeft: '1rem' }}>
                                  <span style={{ display: 'block', fontSize: '0.68rem', fontWeight: 700, color: 'var(--on-surface-variant)', textTransform: 'uppercase' }}>English (KJV)</span>
                                  <p style={{ margin: 0, color: 'var(--on-surface)' }}>{enVerse?.verse_text || '—'}</p>
                                </div>
                              </div>
                            ) : translation === 'kjv' || translation === 'web' ? (
                              <p style={{ margin: 0, color: 'var(--on-surface)' }}>
                                {enVerse?.verse_text || swVerse.verse_text}
                              </p>
                            ) : (
                              <p style={{ margin: 0, color: 'var(--on-surface)' }}>
                                {swVerse.verse_text}
                              </p>
                            )}
                          </div>

                          {/* Verse Action Buttons */}
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.2rem', opacity: 0.85, flexShrink: 0 }}>
                            <button
                              onClick={() => {
                                if (isVerseSpeaking) {
                                  stopAudio();
                                } else {
                                  playVerseAudio(idx);
                                }
                              }}
                              className="icon-btn"
                              title={isVerseSpeaking ? (isSw ? 'Simamisha sauti ya mstari huu' : 'Stop audio') : (isSw ? 'Soma mstari huu kwa sauti' : 'Read verse aloud')}
                              style={{ color: isVerseSpeaking ? '#ef4444' : 'inherit' }}
                            >
                              {isVerseSpeaking ? <Square size={13} fill="currentColor" /> : <Volume2 size={14} />}
                            </button>
                            <button
                              onClick={() => toggleBookmark(swVerse.verse_number)}
                              className="icon-btn"
                              title="Hifadhi mstari (Bookmark)"
                              style={{ color: isBookmarked ? '#d97706' : 'inherit' }}
                            >
                              <Bookmark size={14} />
                            </button>
                            <button
                              onClick={() => copyVerse(swVerse.verse_number, swVerse.verse_text, enVerse?.verse_text)}
                              className="icon-btn"
                              title="Nakili mstari"
                            >
                              {copiedVerse === swVerse.verse_number ? <Check size={14} style={{ color: '#059669' }} /> : <Copy size={14} />}
                            </button>
                            <button
                              onClick={() => shareVerseWhatsApp(swVerse.verse_number, swVerse.verse_text, enVerse?.verse_text)}
                              className="icon-btn"
                              title="Share kwenye WhatsApp"
                            >
                              <Share2 size={14} />
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </>
              )}
            </div>
          </div>
        </>
      )}

      {/* =========================================================================
          MODULE 2: TENZI ZA ROHONI (SWAHILI HYMNAL BOOK)
          ========================================================================= */}
      {activeModule === 'tenzi' && (
        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(280px, 340px) 1fr', gap: '1.25rem', alignItems: 'start' }}>
          {/* Left: Hymns List & Search */}
          <div className="church-card" style={{ display: 'flex', flexDirection: 'column', gap: '1rem', maxHeight: '82vh', overflowY: 'auto' }}>
            {/* Search by Number or Title */}
            <div style={{ position: 'relative' }}>
              <Search size={15} style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--on-surface-variant)' }} />
              <input
                type="text"
                className="form-input"
                placeholder={isSw ? 'Tafuta kwa namba (k.m. 8, 24) au jina...' : 'Search by number or title...'}
                value={tenziSearch}
                onChange={(e) => setTenziSearch(e.target.value)}
                style={{ paddingLeft: '2.25rem', fontSize: '0.82rem' }}
              />
            </div>

            {/* Category Filter */}
            <div style={{ display: 'flex', gap: '0.35rem', overflowX: 'auto', paddingBottom: '0.3rem' }}>
              {['All', 'Sifa na Shukrani', 'Imani na Tumaini', 'Msalaba na Damu ya Yesu', 'Maombi na Urafiki na Yesu'].map(cat => (
                <button
                  key={cat}
                  onClick={() => setTenziCategory(cat)}
                  className={`badge ${tenziCategory === cat ? 'badge-purple' : 'badge-subtle'}`}
                  style={{ cursor: 'pointer', whiteSpace: 'nowrap', fontSize: '0.68rem' }}
                >
                  {cat === 'All' ? (isSw ? 'Zote' : 'All') : cat}
                </button>
              ))}
            </div>

            {/* Hymns List */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.3rem', maxHeight: '480px', overflowY: 'auto' }}>
              {filteredTenzi.map(h => {
                const isSel = h.number === selectedTenziNumber;
                return (
                  <button
                    key={h.number}
                    onClick={() => {
                      stopAudio();
                      setSelectedTenziNumber(h.number);
                    }}
                    style={{
                      textAlign: 'left',
                      padding: '0.65rem 0.8rem',
                      borderRadius: 'var(--radius-sm)',
                      backgroundColor: isSel ? 'var(--primary-container)' : 'var(--surface-container-low)',
                      color: isSel ? 'var(--on-primary)' : 'var(--on-surface)',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.65rem',
                      transition: 'all 0.15s ease'
                    }}
                  >
                    <span style={{
                      width: '32px',
                      height: '32px',
                      borderRadius: '50%',
                      backgroundColor: isSel ? 'rgba(255,255,255,0.25)' : 'var(--surface-container)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: 800,
                      fontSize: '0.78rem',
                      flexShrink: 0
                    }}>
                      {h.number}
                    </span>
                    <div style={{ minWidth: 0, flex: 1 }}>
                      <span style={{ display: 'block', fontWeight: 600, fontSize: '0.84rem', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {h.title}
                      </span>
                      <span style={{ display: 'block', fontSize: '0.68rem', opacity: 0.75 }}>
                        {h.category} • {h.key}
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Right: Selected Hymn View with Lyrics */}
          <div className="church-card" style={{ padding: '2rem', minHeight: '600px' }}>
            {selectedHymn ? (
              <div>
                {/* Hymn Header */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', borderBottom: '1px solid var(--border-subtle)', paddingBottom: '1.25rem', marginBottom: '1.75rem', flexWrap: 'wrap', gap: '1rem' }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.4rem' }}>
                      <span className="badge badge-purple" style={{ fontSize: '0.75rem' }}>
                        Tenzi #{selectedHymn.number}
                      </span>
                      <span className="badge badge-emerald">
                        {selectedHymn.key}
                      </span>
                      <span className="badge badge-subtle">
                        {selectedHymn.time_signature}
                      </span>
                    </div>
                    <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: 'var(--text-headline)', margin: '0 0 0.25rem 0' }}>
                      {selectedHymn.title}
                    </h1>
                    <span style={{ fontSize: '0.82rem', color: 'var(--on-surface-variant)' }}>
                      Kitengo: {selectedHymn.category} • Sayuni Jerusalem Church Hymnal
                    </span>
                  </div>

                  {/* Actions */}
                  <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', flexWrap: 'wrap' }}>
                    <button
                      onClick={() => {
                        if (isPlayingAudio || isGeneratingSpeech) {
                          stopAudio();
                        } else {
                          reciteTenziAloud(selectedHymn);
                        }
                      }}
                      className={isPlayingAudio || isGeneratingSpeech ? "btn-secondary" : "btn-secondary"}
                      style={{
                        fontSize: '0.8rem',
                        padding: '0.45rem 0.9rem',
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.4rem',
                        color: (isPlayingAudio || isGeneratingSpeech) ? '#ef4444' : undefined,
                        borderColor: (isPlayingAudio || isGeneratingSpeech) ? 'rgba(239, 68, 68, 0.4)' : undefined
                      }}
                      title={isPlayingAudio || isGeneratingSpeech ? (isSw ? "Simamisha wimbo mara moja" : "Stop recitation") : (isSw ? "Soma Tenzi kwa sauti" : "Listen aloud")}
                    >
                      {isGeneratingSpeech ? (
                        <Loader2 size={14} className="animate-spin" />
                      ) : isPlayingAudio ? (
                        <Square size={13} fill="currentColor" />
                      ) : (
                        <Volume2 size={14} style={{ color: 'var(--primary)' }} />
                      )}
                      <span>
                        {isGeneratingSpeech 
                          ? (isSw ? 'Inaandaa Sauti...' : 'Generating...') 
                          : isPlayingAudio 
                            ? (isSw ? 'Simamisha Tenzi' : 'Stop Recitation') 
                            : (isSw ? 'Soma kwa Sauti' : 'Listen Aloud')}
                      </span>
                    </button>
                    <button
                      onClick={() => copyTenziLyrics(selectedHymn)}
                      className="btn-secondary"
                      style={{ fontSize: '0.8rem', padding: '0.45rem 0.9rem' }}
                    >
                      {copiedHymn ? <Check size={14} style={{ color: '#059669' }} /> : <Copy size={14} />}
                      <span>{copiedHymn ? 'Imenakiliwa!' : 'Nakili Maneno'}</span>
                    </button>
                    <button
                      onClick={() => {
                        const text = `*Tenzi #${selectedHymn.number} — ${selectedHymn.title}*\n\n${selectedHymn.stanzas[0].text}\n\n_Sayuni Jerusalem Church_`;
                        window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, '_blank');
                      }}
                      className="btn-primary"
                      style={{ fontSize: '0.8rem', padding: '0.45rem 0.9rem' }}
                    >
                      <Share2 size={14} />
                      <span>WhatsApp</span>
                    </button>
                  </div>
                </div>

                {/* Stanzas & Chorus */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.75rem', maxWidth: '680px' }}>
                  {selectedHymn.stanzas.map((stanza) => (
                    <div key={stanza.verse_number} style={{ display: 'flex', gap: '1rem', alignItems: 'flex-start' }}>
                      <span style={{ 
                        width: '28px', 
                        height: '28px', 
                        borderRadius: '50%', 
                        backgroundColor: 'var(--surface-container)', 
                        display: 'flex', 
                        alignItems: 'center', 
                        justifyContent: 'center',
                        fontSize: '0.8rem',
                        fontWeight: 800,
                        color: 'var(--primary)',
                        flexShrink: 0
                      }}>
                        {stanza.verse_number}
                      </span>
                      <div style={{ flex: 1 }}>
                        <p style={{ 
                          fontSize: `${fontSize}px`, 
                          lineHeight: 1.85, 
                          color: 'var(--on-surface)',
                          whiteSpace: 'pre-line',
                          margin: 0,
                          fontWeight: 500
                        }}>
                          {stanza.text}
                        </p>
                      </div>
                    </div>
                  ))}

                  {/* Chorus Card */}
                  {selectedHymn.chorus && (
                    <div style={{ 
                      padding: '1.25rem 1.5rem', 
                      borderRadius: 'var(--radius-md)', 
                      backgroundColor: 'rgba(109, 0, 179, 0.05)', 
                      borderLeft: '4px solid var(--primary)',
                      marginTop: '0.5rem'
                    }}>
                      <span style={{ display: 'block', fontSize: '0.72rem', fontWeight: 800, color: 'var(--primary)', textTransform: 'uppercase', marginBottom: '0.4rem', letterSpacing: '0.05em' }}>
                        Kikwagizo (Chorus)
                      </span>
                      <p style={{ 
                        fontSize: `${fontSize}px`, 
                        lineHeight: 1.85, 
                        color: 'var(--on-surface)', 
                        whiteSpace: 'pre-line',
                        margin: 0,
                        fontWeight: 600,
                        fontStyle: 'italic'
                      }}>
                        {selectedHymn.chorus}
                      </p>
                    </div>
                  )}
                </div>
              </div>
            ) : (
              <p>Chagua Tenzi kusoma</p>
            )}
          </div>
        </div>
      )}

      {/* =========================================================================
          FLOATING LITURGICAL AUDIO CONTROL DOCK (When Audio is Active)
          ========================================================================= */}
      {(isPlayingAudio || isGeneratingSpeech) && (
        <div style={{
          position: 'fixed',
          bottom: '24px',
          left: '50%',
          transform: 'translateX(-50%)',
          width: '90%',
          maxWidth: '680px',
          backgroundColor: 'rgba(18, 19, 24, 0.96)',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          border: '1px solid rgba(255, 255, 255, 0.14)',
          borderRadius: 'var(--radius-full)',
          boxShadow: '0 12px 36px rgba(0, 17, 88, 0.35)',
          zIndex: 80,
          padding: '0.65rem 1.25rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '1rem',
          color: '#ffffff',
          animation: 'fadeIn 0.2s ease-out'
        }}>
          {/* Active Verse Info */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem', minWidth: 0, flex: 1 }}>
            <span style={{
              width: '34px',
              height: '34px',
              borderRadius: '50%',
              backgroundColor: 'var(--primary)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0
            }}>
              {isGeneratingSpeech ? (
                <Loader2 size={16} className="animate-spin" />
              ) : (
                <Volume2 size={16} />
              )}
            </span>
            <div style={{ minWidth: 0, flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <span style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {activeBookMeta?.swahili_name || swBook?.book_name} {selectedChapterNumber} : Mstari {activeSpeakingVerse}
                </span>
                {isPlayingAudio && !isAudioPaused && (
                  <div className="audio-equalizer" title="Inasoma kwa sauti">
                    <span className="eq-bar eq-bar-1" />
                    <span className="eq-bar eq-bar-2" />
                    <span className="eq-bar eq-bar-3" />
                    <span className="eq-bar eq-bar-4" />
                  </div>
                )}
              </div>
              <span style={{ display: 'block', fontSize: '0.68rem', color: isGeneratingSpeech ? '#e4bc4a' : 'rgba(255, 255, 255, 0.65)' }}>
                {isGeneratingSpeech 
                  ? (isSw ? 'Inaandaa sauti ya Gemini...' : 'Generating Gemini voice...')
                  : engineNotice 
                    ? engineNotice
                    : voiceEngine === 'gemini-charon' 
                      ? 'Gemini Studio Charon (Baritone ya Hekaluni)' 
                      : voiceEngine === 'gemini-aoede'
                        ? 'Gemini Studio Aoede (Kiliturjia)'
                        : voiceEngine === 'gemini-kore'
                          ? 'Gemini Studio Kore (Upole & Faraja)'
                          : voiceEngine === 'puter'
                            ? 'Puter Cloud AI Speech'
                            : 'Sauti ya Kifaa Chako'}
              </span>
            </div>
          </div>

          {/* Voice Engine Selector */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', flexShrink: 0 }}>
            <select
              value={voiceEngine}
              onChange={(e) => {
                const nextEngine = e.target.value as any;
                setVoiceEngine(nextEngine);
                if (isPlayingAudio && activeSpeakingVerse) {
                  playVerseAudio(activeSpeakingVerse - 1);
                }
              }}
              style={{
                backgroundColor: 'rgba(109, 0, 179, 0.45)',
                color: '#ffffff',
                border: '1px solid rgba(228, 188, 74, 0.45)',
                borderRadius: 'var(--radius-full)',
                padding: '0.25rem 0.65rem',
                fontSize: '0.72rem',
                fontWeight: 600,
                cursor: 'pointer',
                outline: 'none'
              }}
              title="Chagua Sauti ya AI"
            >
              <option value="gemini-charon" style={{ color: '#000' }}>✨ Gemini Charon (Sauti ya Hekaluni)</option>
              <option value="gemini-aoede" style={{ color: '#000' }}>✨ Gemini Aoede (Kiliturjia)</option>
              <option value="gemini-kore" style={{ color: '#000' }}>✨ Gemini Kore (Upole na Faraja)</option>
              <option value="puter" style={{ color: '#000' }}>☁️ Puter Cloud AI</option>
              <option value="native" style={{ color: '#000' }}>🔊 Sauti ya Kifaa (Offline)</option>
            </select>
          </div>

          {/* Audio Controls */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flexShrink: 0 }}>
            <button
              onClick={skipPrevAudioVerse}
              className="icon-btn"
              style={{ color: '#ffffff' }}
              title="Mstari Uliopita"
            >
              <SkipBack size={17} />
            </button>
            <button
              onClick={togglePlayPauseChapter}
              style={{
                width: '38px',
                height: '38px',
                borderRadius: '50%',
                backgroundColor: '#ffffff',
                color: 'var(--primary)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                boxShadow: '0 2px 8px rgba(0,0,0,0.2)'
              }}
              title={isGeneratingSpeech ? 'Simamisha (Ghairi)' : isAudioPaused ? 'Endelea' : 'Pumzisha'}
            >
              {isGeneratingSpeech ? (
                <Loader2 size={18} className="animate-spin" />
              ) : isAudioPaused ? (
                <Play size={18} />
              ) : (
                <Pause size={18} />
              )}
            </button>
            <button
              onClick={skipNextAudioVerse}
              className="icon-btn"
              style={{ color: '#ffffff' }}
              title="Mstari Unaofuata"
            >
              <SkipForward size={17} />
            </button>
          </div>

          {/* Speed Controller & Stop */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flexShrink: 0 }}>
            <select
              value={audioSpeed}
              onChange={(e) => {
                const spd = parseFloat(e.target.value);
                setAudioSpeed(spd);
                if (currentAudioRef.current) {
                  currentAudioRef.current.playbackRate = spd;
                }
              }}
              style={{
                backgroundColor: 'rgba(255, 255, 255, 0.12)',
                color: '#ffffff',
                border: 'none',
                borderRadius: 'var(--radius-sm)',
                padding: '0.25rem 0.5rem',
                fontSize: '0.75rem',
                fontWeight: 600,
                cursor: 'pointer'
              }}
            >
              <option value="0.8" style={{ color: '#000' }}>0.8x</option>
              <option value="1.0" style={{ color: '#000' }}>1.0x</option>
              <option value="1.25" style={{ color: '#000' }}>1.25x</option>
              <option value="1.5" style={{ color: '#000' }}>1.5x</option>
            </select>

            <button
              onClick={() => setAutoAdvance(!autoAdvance)}
              style={{
                backgroundColor: autoAdvance ? 'var(--primary)' : 'rgba(255, 255, 255, 0.12)',
                color: '#ffffff',
                border: 'none',
                borderRadius: 'var(--radius-sm)',
                padding: '0.25rem 0.5rem',
                fontSize: '0.72rem',
                fontWeight: 600,
                cursor: 'pointer'
              }}
              title={isSw ? 'Kusoma mfululizo (Auto-advance)' : 'Continuous play'}
            >
              {autoAdvance ? (isSw ? 'Mfululizo' : 'Auto-Next') : (isSw ? 'Mstari 1' : 'Single')}
            </button>

            <button
              onClick={stopAudio}
              className="icon-btn"
              style={{ color: '#f87171' }}
              title="Funga Sauti"
            >
              <VolumeX size={18} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default BibleReader;
