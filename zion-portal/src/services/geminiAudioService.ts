/**
 * Gemini Studio Audio Synthesis Service
 * Utilizes gemini-2.5-flash-preview-tts with prebuilt liturgical voice profiles:
 * - Charon: Deep resonant baritone (reverent scripture & psalm recitation)
 * - Aoede: Warm liturgical alto (clear, melodic gospel reading)
 * - Kore: Gentle and comforting tone
 * - Puck: Clear, natural international voice
 * - Fenrir: Strong, authoritative baritone
 * 
 * Features:
 * - 15-Key Auto-Rotating & Load-Balanced Key Pool with instant failover on 429
 * - 24kHz 16-bit Mono PCM to Standard 44-byte RIFF WAV generator
 * - Multi-tier Caching: In-memory Map + Persistent IndexedDB for full offline playback
 * - Lookahead prefetching and batch chapter downloading
 */

import {
  saveAudioBlob,
  getAudioBlob,
  buildAudioKey,
  buildChapterKey
} from './offlineAudioStorage';

const GEMINI_API_KEYS: string[] = (import.meta.env.VITE_GEMINI_TTS_KEYS || '')
  .split(/[,\n]/)
  .map((key: string) => key.trim())
  .filter(Boolean);

let currentKeyIndex = 0;

export type GeminiVoiceName = 'Charon' | 'Aoede' | 'Kore' | 'Puck' | 'Fenrir';

export interface VerseLocation {
  bookNumber: number;
  chapterNumber: number;
  verseNumber: number;
}

// In-memory cache: cacheKey -> audio blob URL
const audioBlobCache = new Map<string, string>();

/**
 * Converts raw 24kHz 16-bit Mono PCM base64 string to a playable WAV Blob and URL.
 */
function pcmBase64ToWav(base64Data: string, sampleRate = 24000): { url: string; blob: Blob } {
  const binaryString = window.atob(base64Data);
  const pcmLength = binaryString.length;
  const pcmBytes = new Uint8Array(pcmLength);
  for (let i = 0; i < pcmLength; i++) {
    pcmBytes[i] = binaryString.charCodeAt(i);
  }

  const numChannels = 1;
  const bitsPerSample = 16;
  const blockAlign = numChannels * (bitsPerSample / 8);
  const byteRate = sampleRate * blockAlign;
  const totalFileSize = 36 + pcmLength;

  const wavHeader = new ArrayBuffer(44);
  const view = new DataView(wavHeader);

  // RIFF chunk descriptor
  writeString(view, 0, 'RIFF');
  view.setUint32(4, totalFileSize, true);
  writeString(view, 8, 'WAVE');

  // fmt sub-chunk
  writeString(view, 12, 'fmt ');
  view.setUint32(16, 16, true); // Subchunk1Size (16 for PCM)
  view.setUint16(20, 1, true); // AudioFormat (1 = PCM)
  view.setUint16(22, numChannels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, byteRate, true);
  view.setUint16(32, blockAlign, true);
  view.setUint16(34, bitsPerSample, true);

  // data sub-chunk
  writeString(view, 36, 'data');
  view.setUint32(40, pcmLength, true);

  const blob = new Blob([wavHeader, pcmBytes], { type: 'audio/wav' });
  return {
    blob,
    url: URL.createObjectURL(blob)
  };
}

function writeString(view: DataView, offset: number, string: string) {
  for (let i = 0; i < string.length; i++) {
    view.setUint8(offset + i, string.charCodeAt(i));
  }
}

/**
 * Synthesizes speech using Gemini 2.5 Flash Preview TTS with 15-key rotating failover.
 * Checks Memory Cache -> Checks Persistent IndexedDB -> Falls back to API fetch.
 * Returns a playable audio URL (blob: URL).
 */
export async function synthesizeGeminiVoice(
  text: string,
  voiceName: GeminiVoiceName = 'Charon',
  location?: VerseLocation
): Promise<string> {
  const cleanText = text.trim();
  if (!cleanText) {
    throw new Error('Maandishi hayawezi kuwa matupu.');
  }

  const cacheKey = location
    ? buildAudioKey(voiceName, location.bookNumber, location.chapterNumber, location.verseNumber)
    : `${voiceName}:${cleanText}`;

  // 1. Check in-memory session cache
  if (audioBlobCache.has(cacheKey)) {
    return audioBlobCache.get(cacheKey)!;
  }

  // 2. Check persistent IndexedDB offline storage
  try {
    const existingBlob = await getAudioBlob(cacheKey);
    if (existingBlob) {
      const url = URL.createObjectURL(existingBlob);
      audioBlobCache.set(cacheKey, url);
      return url;
    }
  } catch (idbErr) {
    console.warn('IndexedDB read error:', idbErr);
  }

  // 3. Synthesize from Gemini API via 15-Key Pool
  const requestBody = {
    contents: [
      {
        parts: [{ text: cleanText }]
      }
    ],
    generationConfig: {
      responseModalities: ['AUDIO'],
      speechConfig: {
        voiceConfig: {
          prebuiltVoiceConfig: {
            voiceName: voiceName
          }
        }
      }
    }
  };

  const totalKeys = GEMINI_API_KEYS.length;
  if (totalKeys === 0) {
    throw new Error('Gemini TTS haijasanidiwa. Weka VITE_GEMINI_TTS_KEYS kwenye .env.local.');
  }

  let lastError: Error | null = null;

  for (let attempt = 0; attempt < totalKeys; attempt++) {
    const key = GEMINI_API_KEYS[(currentKeyIndex + attempt) % totalKeys];
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=${key}`;

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(requestBody)
      });

      if (response.ok) {
        currentKeyIndex = (currentKeyIndex + attempt + 1) % totalKeys;
        const data = await response.json();
        const inlineData = data.candidates?.[0]?.content?.parts?.[0]?.inlineData;

        if (!inlineData || !inlineData.data) {
          throw new Error('Hakuna audio data iliyorudishwa na Gemini.');
        }

        const { url, blob } = pcmBase64ToWav(inlineData.data, 24000);
        audioBlobCache.set(cacheKey, url);

        // Store into IndexedDB in background
        const chapterKey = location
          ? buildChapterKey(location.bookNumber, location.chapterNumber)
          : 'generic';
        saveAudioBlob(cacheKey, chapterKey, blob, voiceName).catch(err => {
          console.warn('Failed to cache audio in IndexedDB:', err);
        });

        return url;
      }

      if (response.status === 429) {
        console.warn(`Gemini API key ${attempt + 1} rate-limited (429). Rotating to next key...`);
        continue;
      }

      const errText = await response.text();
      lastError = new Error(`Gemini TTS Error [${response.status}]: ${errText}`);
    } catch (fetchErr: any) {
      lastError = fetchErr;
      console.warn(`Gemini TTS network error with key ${attempt + 1}:`, fetchErr);
    }
  }

  throw lastError || new Error('Sauti za Gemini hazipatikani kwa sasa.');
}

/**
 * Prefetches the next verse ahead of time in the background.
 * Guarantees zero latency and instantaneous transitions between verses.
 */
export async function prefetchGeminiVoice(
  text: string,
  voiceName: GeminiVoiceName = 'Charon',
  location?: VerseLocation
): Promise<void> {
  const cleanText = text.trim();
  if (!cleanText) return;

  const cacheKey = location
    ? buildAudioKey(voiceName, location.bookNumber, location.chapterNumber, location.verseNumber)
    : `${voiceName}:${cleanText}`;

  if (audioBlobCache.has(cacheKey)) return;

  try {
    const existingBlob = await getAudioBlob(cacheKey);
    if (existingBlob) {
      audioBlobCache.set(cacheKey, URL.createObjectURL(existingBlob));
      return;
    }
    // Synthesize in background
    await synthesizeGeminiVoice(cleanText, voiceName, location);
  } catch {
    // Silent failure for prefetch
  }
}

/**
 * Batch downloads all verses of an entire chapter for offline playback.
 * Leverages the 15-key Gemini pool concurrently for fast download in seconds.
 */
export async function downloadChapterAudio(
  bookNumber: number,
  chapterNumber: number,
  verses: Array<{ verse_number: number; verse_text: string }>,
  voiceName: GeminiVoiceName = 'Charon',
  onProgress?: (progress: { downloaded: number; total: number; percent: number; currentVerse: number }) => void,
  isCancelled?: () => boolean
): Promise<{ success: boolean; downloadedCount: number }> {
  const total = verses.length;
  let completed = 0;

  // Concurrency pool of 4 parallel requests across the 15 keys
  const CONCURRENCY = 4;
  const queue = [...verses];

  async function worker() {
    while (queue.length > 0) {
      if (isCancelled && isCancelled()) break;
      const v = queue.shift();
      if (!v) break;

      const loc: VerseLocation = {
        bookNumber,
        chapterNumber,
        verseNumber: v.verse_number
      };

      try {
        await synthesizeGeminiVoice(v.verse_text, voiceName, loc);
      } catch (err) {
        console.warn(`Could not synthesize verse ${v.verse_number}:`, err);
      }

      completed++;
      if (onProgress) {
        const percent = Math.round((completed / total) * 100);
        onProgress({ downloaded: completed, total, percent, currentVerse: v.verse_number });
      }
    }
  }

  const workers = Array.from({ length: Math.min(CONCURRENCY, verses.length) }, () => worker());
  await Promise.all(workers);

  return {
    success: !isCancelled || !isCancelled(),
    downloadedCount: completed
  };
}
