/**
 * Puter.js Zero-Backend AI Speech Service
 * Provides free cloud AI TTS without requiring personal API keys.
 * Integrates Puter auth flow correctly: isSignedIn(), signIn(), txt2speech().
 */

declare global {
  interface Window {
    puter?: any;
  }
}

export interface PuterVoiceOptions {
  provider?: 'gemini' | 'openai' | 'elevenlabs' | 'aws-polly';
  voice?: string;
  language?: string;
}

/**
 * Checks if Puter.js is loaded in the browser.
 */
export function isPuterAvailable(): boolean {
  return typeof window !== 'undefined' && !!window.puter && !!window.puter.ai;
}

let puterLoader: Promise<void> | null = null;

/**
 * Loads the Puter SDK on first use.
 *
 * The script used to be a hard <script> tag in index.html, so every leader
 * downloaded and executed a third-party bundle on every page view — even
 * though Puter only powers one optional Bible voice. Loading it on demand
 * keeps that code (and any tracking it carries) off the portal entirely until
 * someone actually picks that voice.
 */
export function ensurePuterLoaded(): Promise<void> {
  if (typeof window === 'undefined') return Promise.resolve();
  if (isPuterAvailable()) return Promise.resolve();
  if (puterLoader) return puterLoader;

  puterLoader = new Promise<void>((resolve, reject) => {
    const script = document.createElement('script');
    script.src = 'https://js.puter.com/v2/';
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => {
      puterLoader = null;
      reject(new Error('Imeshindikana kupakia Puter.js. Kagua muunganisho wako.'));
    };
    document.head.appendChild(script);
  });

  return puterLoader;
}

/**
 * Checks if the user is currently signed in to Puter.
 */
export function isPuterSignedIn(): boolean {
  if (!isPuterAvailable() || !window.puter.auth) return false;
  try {
    return !!window.puter.auth.isSignedIn();
  } catch (_) {
    return false;
  }
}

/**
 * Prompts the user to connect their Puter account.
 */
export async function connectPuter(): Promise<boolean> {
  await ensurePuterLoaded();
  if (!isPuterAvailable()) {
    throw new Error('Puter.js haijapakiwa kwenye kivinjari.');
  }

  try {
    await window.puter.auth.signIn();
    return isPuterSignedIn();
  } catch (err: any) {
    throw new Error(`Kushindwa kuunganisha Puter: ${err?.message || err}`);
  }
}

/**
 * Synthesizes text to speech using Puter.js.
 * Returns an HTMLAudioElement.
 */
export async function synthesizePuterSpeech(
  text: string,
  options: PuterVoiceOptions = { provider: 'gemini' }
): Promise<HTMLAudioElement> {
  await ensurePuterLoaded();
  if (!isPuterAvailable()) {
    throw new Error('Puter SDK haipatikani.');
  }

  const cleanText = text.trim();
  if (!cleanText) {
    throw new Error('Maandishi hayawezi kuwa matupu.');
  }

  try {
    const audio = await window.puter.ai.txt2speech(cleanText, options);
    if (!audio) {
      throw new Error('Puter haikurudisha audio object.');
    }
    return audio;
  } catch (err: any) {
    throw new Error(`Puter TTS Error: ${err?.message || err}`);
  }
}
