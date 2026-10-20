/**
 * Zion Jerusalem Liturgical Audio Storage Service
 * Native IndexedDB implementation for persistent offline Bible & Tenzi audio playback.
 * 
 * Features:
 * - Persistent binary Blob storage for 24kHz studio-quality WAV audio
 * - Zero external dependencies (uses native browser indexedDB)
 * - Automatic database versioning and quota error resilience
 * - Chapter-level download progress tracking and cache management
 */

const DB_NAME = 'zion_sacred_audio_db';
const DB_VERSION = 1;
const STORE_NAME = 'audio_blobs';

let dbPromise: Promise<IDBDatabase> | null = null;

function getDB(): Promise<IDBDatabase> {
  if (dbPromise) return dbPromise;

  dbPromise = new Promise((resolve, reject) => {
    if (!('indexedDB' in window)) {
      reject(new Error('IndexedDB is not supported on this device.'));
      return;
    }

    const request = window.indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = (event) => {
      const db = (event.target as IDBOpenDBRequest).result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        const store = db.createObjectStore(STORE_NAME, { keyPath: 'key' });
        store.createIndex('chapter_idx', 'chapterKey', { unique: false });
      }
    };

    request.onsuccess = (event) => {
      resolve((event.target as IDBOpenDBRequest).result);
    };

    request.onerror = (event) => {
      reject((event.target as IDBOpenDBRequest).error);
    };
  });

  return dbPromise;
}

export interface StoredAudioRecord {
  key: string;
  chapterKey: string; // e.g. "b1_c1"
  blob: Blob;
  size: number;
  voice: string;
  timestamp: number;
}

/**
 * Builds standard key for verse audio
 */
export function buildAudioKey(voice: string, bookNum: number, chapNum: number, verseNum: number): string {
  return `${voice}:b${bookNum}_c${chapNum}_v${verseNum}`;
}

/**
 * Builds standard chapter prefix key
 */
export function buildChapterKey(bookNum: number, chapNum: number): string {
  return `b${bookNum}_c${chapNum}`;
}

/**
 * Saves an audio blob into persistent offline IndexedDB
 */
export async function saveAudioBlob(
  key: string,
  chapterKey: string,
  blob: Blob,
  voice: string
): Promise<void> {
  try {
    const db = await getDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readwrite');
      const store = tx.objectStore(STORE_NAME);
      const record: StoredAudioRecord = {
        key,
        chapterKey,
        blob,
        size: blob.size,
        voice,
        timestamp: Date.now()
      };
      const req = store.put(record);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  } catch (err) {
    console.warn('Failed to store audio in IndexedDB:', err);
  }
}

/**
 * Retrieves an audio blob from persistent offline IndexedDB
 */
export async function getAudioBlob(key: string): Promise<Blob | null> {
  try {
    const db = await getDB();
    return new Promise((resolve) => {
      const tx = db.transaction(STORE_NAME, 'readonly');
      const store = tx.objectStore(STORE_NAME);
      const req = store.get(key);
      req.onsuccess = () => {
        if (req.result && req.result.blob) {
          resolve(req.result.blob);
        } else {
          resolve(null);
        }
      };
      req.onerror = () => resolve(null);
    });
  } catch {
    return null;
  }
}

/**
 * Checks if an audio blob exists in persistent storage
 */
export async function hasAudioBlob(key: string): Promise<boolean> {
  const blob = await getAudioBlob(key);
  return blob !== null;
}

/**
 * Checks download statistics for a specific chapter
 */
export async function getChapterDownloadStats(
  bookNum: number,
  chapNum: number,
  verseCount: number,
  voice: string
): Promise<{ downloadedCount: number; totalCount: number; isComplete: boolean; totalBytes: number }> {
  try {
    const db = await getDB();
    return new Promise((resolve) => {
      const tx = db.transaction(STORE_NAME, 'readonly');
      const store = tx.objectStore(STORE_NAME);
      const index = store.index('chapter_idx');
      const chapterKey = buildChapterKey(bookNum, chapNum);
      const req = index.getAll(chapterKey);

      req.onsuccess = () => {
        const records: StoredAudioRecord[] = req.result || [];
        const matchingVoice = records.filter(r => r.voice === voice);
        let totalBytes = 0;
        matchingVoice.forEach(r => {
          totalBytes += r.size || 0;
        });

        const downloadedCount = matchingVoice.length;
        const isComplete = verseCount > 0 && downloadedCount >= verseCount;

        resolve({
          downloadedCount,
          totalCount: verseCount,
          isComplete,
          totalBytes
        });
      };

      req.onerror = () => {
        resolve({
          downloadedCount: 0,
          totalCount: verseCount,
          isComplete: false,
          totalBytes: 0
        });
      };
    });
  } catch {
    return {
      downloadedCount: 0,
      totalCount: verseCount,
      isComplete: false,
      totalBytes: 0
    };
  }
}

/**
 * Deletes all cached audio for a given chapter
 */
export async function deleteChapterAudio(
  bookNum: number,
  chapNum: number,
  voice?: string
): Promise<void> {
  try {
    const db = await getDB();
    const chapterKey = buildChapterKey(bookNum, chapNum);

    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readwrite');
      const store = tx.objectStore(STORE_NAME);
      const index = store.index('chapter_idx');
      const req = index.getAllKeys(chapterKey);

      req.onsuccess = () => {
        const keys = req.result || [];
        keys.forEach(k => {
          if (!voice || (typeof k === 'string' && k.startsWith(`${voice}:`))) {
            store.delete(k);
          }
        });
        resolve();
      };

      req.onerror = () => reject(req.error);
    });
  } catch (err) {
    console.warn('Failed to delete chapter audio:', err);
  }
}
