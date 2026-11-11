/**
 * Single source of truth for the two official certificate designs.
 *
 * Each design is deliberately built from TWO ink colours only (ink + accent)
 * on a neutral paper. `--cert-*` tokens are injected into the live preview as
 * CSS custom properties; `hexToRgb()` feeds the exact same values to the PDF
 * renderer, so the screen and the download can never drift apart.
 */

export type CertificateVariant = 'classic' | 'modern';

export interface CertificatePalette {
  paper: string;
  surface: string;
  ink: string;
  accent: string;
  /** A light tint of the same accent, used only for text on dark ink. */
  accentSoft: string;
  muted: string;
  hairline: string;
}

export interface CertificateDesign {
  id: CertificateVariant;
  labelSw: string;
  labelEn: string;
  descriptionSw: string;
  descriptionEn: string;
  palette: CertificatePalette;
}

export const CERTIFICATE_VARIANT_ORDER: CertificateVariant[] = ['classic', 'modern'];

export const CERTIFICATE_DESIGNS: Record<CertificateVariant, CertificateDesign> = {
  classic: {
    id: 'classic',
    labelSw: 'Rasmi',
    labelEn: 'Classic',
    descriptionSw: 'Karatasi ya pembe, herufi za kiserifu, fremu ya dhahabu iliyotulia.',
    descriptionEn: 'Ivory paper, formal serif type, a restrained bronze frame.',
    palette: {
      paper: '#FCFAF4',
      surface: '#F7F1E3',
      ink: '#1B2A4A',
      accent: '#A2761F',
      accentSoft: '#E3CE9A',
      muted: '#737B8C',
      hairline: '#DCD1B7'
    }
  },
  modern: {
    id: 'modern',
    labelSw: 'Kisasa',
    labelEn: 'Modern',
    descriptionSw: 'Bendera ya giza juu, utepe wa kijani, herufi kubwa za kisasa.',
    descriptionEn: 'Bold dark masthead, teal accent rail, large modern type.',
    palette: {
      paper: '#FFFFFF',
      surface: '#F4F6F8',
      ink: '#101C2E',
      accent: '#1F5F57',
      accentSoft: '#9FD3C9',
      muted: '#6B7686',
      hairline: '#D7DEE6'
    }
  }
};

/** CSS custom properties for the live preview (typed as a plain string map). */
export function certificateCssVars(variant: CertificateVariant): Record<string, string> {
  const { palette } = CERTIFICATE_DESIGNS[variant];
  return {
    '--cert-paper': palette.paper,
    '--cert-surface': palette.surface,
    '--cert-ink': palette.ink,
    '--cert-accent': palette.accent,
    '--cert-accent-soft': palette.accentSoft,
    '--cert-muted': palette.muted,
    '--cert-hairline': palette.hairline
  };
}

/** '#RRGGBB' -> jsPDF RGB tuple. */
export function hexToRgb(hex: string): readonly [number, number, number] {
  const value = hex.replace('#', '');
  return [
    parseInt(value.slice(0, 2), 16),
    parseInt(value.slice(2, 4), 16),
    parseInt(value.slice(4, 6), 16)
  ];
}
