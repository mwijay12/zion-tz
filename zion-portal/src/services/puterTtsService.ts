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
