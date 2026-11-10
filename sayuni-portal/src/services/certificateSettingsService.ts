import { loadStored, saveStored, STORAGE_KEYS } from '../utils/storage';

/**
 * Optional certificate signature images.
 *
 * By default BOTH are `null`: certificates are printed with a clean, empty
 * line so they can be signed physically with a pen. An administrator may add
 * a scanned signature later from the Certificate Studio settings panel; the
 * image is kept in this browser's localStorage only (never uploaded to the
 * cloud, never part of a demo session's Firestore data).
 */
export interface CertificateSettings {
  pastorSignature: string | null;
  secretarySignature: string | null;
}

export const DEFAULT_CERTIFICATE_SETTINGS: CertificateSettings = {
  pastorSignature: null,
  secretarySignature: null
};

const MAX_SIGNATURE_BYTES = 1.5 * 1024 * 1024;
const ALLOWED_TYPES = ['image/png', 'image/jpeg'];

export function loadCertificateSettings(): CertificateSettings {
  const stored = loadStored<Partial<CertificateSettings>>(
    STORAGE_KEYS.certificateSettings,
    DEFAULT_CERTIFICATE_SETTINGS
  );

  return {
    pastorSignature: typeof stored?.pastorSignature === 'string' ? stored.pastorSignature : null,
    secretarySignature:
      typeof stored?.secretarySignature === 'string' ? stored.secretarySignature : null
  };
}

export function saveCertificateSettings(settings: CertificateSettings): void {
  saveStored(STORAGE_KEYS.certificateSettings, settings);
}

/** Convert a picked file into a data URL, with a small size/type guard. */
export function readSignatureImage(file: File): Promise<string> {
  if (!ALLOWED_TYPES.includes(file.type)) {
    return Promise.reject(new Error('unsupported-type'));
  }
  if (file.size > MAX_SIGNATURE_BYTES) {
    return Promise.reject(new Error('too-large'));
  }

  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      if (typeof reader.result === 'string' && reader.result.startsWith('data:image/')) {
        resolve(reader.result);
      } else {
        reject(new Error('unreadable'));
      }
    };
    reader.onerror = () => reject(reader.error ?? new Error('unreadable'));
    reader.readAsDataURL(file);
  });
}

/** jsPDF needs the format explicitly when given a data URL. */
export function signatureImageFormat(dataUrl: string): 'PNG' | 'JPEG' {
  return dataUrl.startsWith('data:image/png') ? 'PNG' : 'JPEG';
}
