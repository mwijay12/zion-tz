import { GState, jsPDF } from 'jspdf';
import { CERTIFICATE_DEFINITIONS, certificateBody } from '../data/certificateContent';
import { CERTIFICATE_DESIGNS, hexToRgb, type CertificateVariant } from '../data/certificateDesign';
import { CHURCH_PROFILE } from '../data/mockData';
import type { CertificateType, Language } from '../types';

export interface CertificatePdfInput {
  type: CertificateType;
  recipientName: string;
  spouseName?: string;
  parentNames?: string;
  eventDate: string;
  scripture: string;
  notes?: string;
  serialNumber: string;
  language: Language;
  /** Which of the two official designs to render. */
  variant: CertificateVariant;
}

type Rgb = readonly [number, number, number];

interface Theme {
  variant: CertificateVariant;
  paper: Rgb;
  surface: Rgb;
  ink: Rgb;
  accent: Rgb;
  muted: Rgb;
  hairline: Rgb;
}

const PAGE_WIDTH = 297;
const PAGE_HEIGHT = 210;
const CENTER_X = PAGE_WIDTH / 2;
const MARGIN = 22;

const SW_MONTHS = [
  'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
  'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
];

const EN_MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

let logoPromise: Promise<string | null> | null = null;

function themeFor(variant: CertificateVariant): Theme {
  const palette = CERTIFICATE_DESIGNS[variant].palette;
  return {
    variant,
    paper: hexToRgb(palette.paper),
    surface: hexToRgb(palette.surface),
    ink: hexToRgb(palette.ink),
    accent: hexToRgb(palette.accent),
    muted: hexToRgb(palette.muted),
    hairline: hexToRgb(palette.hairline)
  };
}

function setTextColor(doc: jsPDF, color: Rgb): void {
  doc.setTextColor(color[0], color[1], color[2]);
}

function setFillColor(doc: jsPDF, color: Rgb): void {
  doc.setFillColor(color[0], color[1], color[2]);
}

function setDrawColor(doc: jsPDF, color: Rgb): void {
  doc.setDrawColor(color[0], color[1], color[2]);
}

function textOrDefault(value: string | undefined, fallback: string): string {
  return value?.trim() || fallback;
}

function fitFontSize(
  doc: jsPDF,
  text: string,
  maxWidth: number,
  startSize: number,
  minSize: number,
  font = 'times',
  style = 'normal'
): number {
  let size = startSize;
  doc.setFont(font, style);
  while (size > minSize) {
    doc.setFontSize(size);
    if (doc.getTextWidth(text) <= maxWidth) break;
    size -= 0.5;
  }
  doc.setFontSize(size);
  return size;
}

function drawCenteredLines(doc: jsPDF, lines: string[], y: number, lineHeight: number): void {
  lines.forEach((line, index) => {
    doc.text(line, CENTER_X, y + index * lineHeight, { align: 'center' });
  });
}

function drawLeftLines(doc: jsPDF, lines: string[], x: number, y: number, lineHeight: number): void {
  lines.forEach((line, index) => {
    doc.text(line, x, y + index * lineHeight);
  });
}

function loadLogo(): Promise<string | null> {
  if (logoPromise) return logoPromise;

  const baseUrl = import.meta.env?.BASE_URL ?? '/';
  logoPromise = fetch(`${baseUrl}zion_logo.png`)
    .then((response) => (response.ok ? response.blob() : null))
    .then(
      (blob) =>
        new Promise<string | null>((resolve, reject) => {
          if (!blob) {
            resolve(null);
            return;
          }
          const reader = new FileReader();
          reader.onload = () => resolve(typeof reader.result === 'string' ? reader.result : null);
          reader.onerror = () => reject(reader.error);
          reader.readAsDataURL(blob);
        })
    )
    .catch(() => null);

  return logoPromise;
}

function localIsoDate(date: Date): string {
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${date.getFullYear()}-${month}-${day}`;
}

export function formatCertificateDate(value: string, language: Language): string {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return value;

  const months = language === 'sw' ? SW_MONTHS : EN_MONTHS;
  const month = months[Number(match[2]) - 1];
  if (!month) return value;

  return `${Number(match[3])} ${month} ${match[1]}`;
}

export function createCertificateSerial(type: CertificateType, issuedAt = new Date()): string {
  const randomPart =
    globalThis.crypto?.randomUUID?.().replace(/-/g, '').slice(0, 6).toUpperCase() ??
    Math.random().toString(36).slice(2, 8).toUpperCase();

  return `ZJ-${CERTIFICATE_DEFINITIONS[type].serialCode}-${issuedAt.getFullYear()}-${randomPart}`;
}

/** Fine rule. Classic: centred with a small lozenge. Modern: plain straight line. */
function drawRule(doc: jsPDF, theme: Theme, y: number, halfWidth: number): void {
  if (theme.variant === 'modern') {
    setDrawColor(doc, theme.hairline);
    doc.setLineWidth(0.25);
    doc.line(MARGIN, y, PAGE_WIDTH - MARGIN, y);
    setDrawColor(doc, theme.accent);
    doc.setLineWidth(0.9);
    doc.line(MARGIN, y, MARGIN + 26, y);
    return;
  }

  setDrawColor(doc, theme.accent);
  doc.setLineWidth(0.22);
  doc.line(CENTER_X - halfWidth, y, CENTER_X - 2.4, y);
  doc.line(CENTER_X + 2.4, y, CENTER_X + halfWidth, y);
  setFillColor(doc, theme.accent);
  setDrawColor(doc, theme.accent);
  doc.setLineWidth(0.2);
  doc.circle(CENTER_X, y, 1.05, 'FD');
}

function drawBackground(doc: jsPDF, theme: Theme): void {
  setFillColor(doc, theme.paper);
  doc.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, 'F');

  if (theme.variant === 'modern') {
    // A single quiet accent spine instead of a decorative frame.
    setFillColor(doc, theme.accent);
    doc.rect(0, 0, 3.2, PAGE_HEIGHT, 'F');
    setDrawColor(doc, theme.hairline);
    doc.setLineWidth(0.2);
    doc.line(MARGIN, 15, PAGE_WIDTH - MARGIN, 15);
    return;
  }

  setFillColor(doc, theme.surface);
  doc.rect(15, 15, 267, 180, 'F');

  setDrawColor(doc, theme.accent);
  doc.setLineWidth(0.8);
  doc.rect(9, 9, 279, 192);
  doc.setLineWidth(0.25);
  doc.rect(12.5, 12.5, 272, 185);

  setDrawColor(doc, theme.hairline);
  doc.setLineWidth(0.18);
  doc.rect(15.8, 15.8, 265.4, 178.4);

  const corners: Array<[number, number, number, number]> = [
    [20, 20, 1, 1],
    [277, 20, -1, 1],
    [20, 190, 1, -1],
    [277, 190, -1, -1]
  ];

  corners.forEach(([x, y, xDirection, yDirection]) => {
    setDrawColor(doc, theme.accent);
    doc.setLineWidth(0.9);
    doc.line(x, y, x + xDirection * 10, y);
    doc.line(x, y, x, y + yDirection * 10);
  });
}

function drawWatermark(doc: jsPDF, theme: Theme, logo: string | null): void {
  if (!logo) return; // A missing asset must never print a fake monogram.

  doc.saveGraphicsState();
  doc.setGState(new GState({ opacity: theme.variant === 'modern' ? 0.02 : 0.025 }));
  if (theme.variant === 'modern') {
    doc.addImage(logo, 'PNG', 206, 68, 62, 62, undefined, 'FAST');
  } else {
    doc.addImage(logo, 'PNG', CENTER_X - 38, 62, 76, 76, undefined, 'FAST');
  }
  doc.restoreGraphicsState();
}

function drawHeader(doc: jsPDF, theme: Theme, logo: string | null, isSw: boolean): void {
  if (theme.variant === 'modern') {
    const logoX = MARGIN;
    const logoY = 22;
    if (logo) {
      doc.addImage(logo, 'PNG', logoX, logoY, 16, 16, undefined, 'FAST');
    }
    setDrawColor(doc, theme.accent);
    doc.setLineWidth(0.6);
    doc.roundedRect(logoX, logoY, 16, 16, 2, 2, 'S');

    fitFontSize(doc, CHURCH_PROFILE.name, 200, 14, 10, 'helvetica', 'bold');
    setTextColor(doc, theme.ink);
    doc.text(CHURCH_PROFILE.name, 44, 28.5, { charSpace: 0.5 });

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(7.2);
    setTextColor(doc, theme.accent);
    doc.text((isSw ? CHURCH_PROFILE.motto : CHURCH_PROFILE.mottoEn).toUpperCase(), 44, 34, { charSpace: 0.8 });

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(6.8);
    setTextColor(doc, theme.muted);
    doc.text(`${CHURCH_PROFILE.location}  •  ${CHURCH_PROFILE.phone}`, 44, 38.4);

    // Right-aligned labels use a plain align (charSpace + align can overflow
    // the right margin in jsPDF), then the accent is added with a short rule.
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(6.2);
    setTextColor(doc, theme.accent);
    doc.text(isSw ? 'HATI RASMI YA KANISA' : 'OFFICIAL CHURCH DOCUMENT', PAGE_WIDTH - MARGIN, 27, {
      align: 'right'
    });

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(6.6);
    setTextColor(doc, theme.muted);
    doc.text(isSw ? 'SAYUNI YERUSALEMU' : 'ZION JERUSALEM', PAGE_WIDTH - MARGIN, 32, {
      align: 'right'
    });

    drawRule(doc, theme, 44, 110);
    return;
  }

  const logoCenterY = 25;
  if (logo) {
    doc.addImage(logo, 'PNG', CENTER_X - 8.5, logoCenterY - 8.5, 17, 17, undefined, 'FAST');
  }
  setDrawColor(doc, theme.accent);
  doc.setLineWidth(0.6);
  doc.circle(CENTER_X, logoCenterY, 9.2);

  fitFontSize(doc, CHURCH_PROFILE.name, 252, 20, 14, 'times', 'bold');
  setTextColor(doc, theme.ink);
  doc.text(CHURCH_PROFILE.name, CENTER_X, 42.5, { align: 'center', charSpace: 0.9 });

  fitFontSize(doc, isSw ? CHURCH_PROFILE.motto : CHURCH_PROFILE.mottoEn, 240, 8.6, 7, 'times', 'bolditalic');
  setTextColor(doc, theme.accent);
  doc.text(isSw ? CHURCH_PROFILE.motto : CHURCH_PROFILE.mottoEn, CENTER_X, 48.2, {
    align: 'center',
    charSpace: 0.5
  });

  fitFontSize(doc, `${CHURCH_PROFILE.location}  •  ${CHURCH_PROFILE.phone}`, 254, 7.4, 6.4, 'helvetica', 'normal');
  setTextColor(doc, theme.muted);
  doc.text(`${CHURCH_PROFILE.location}  •  ${CHURCH_PROFILE.phone}`, CENTER_X, 53.4, { align: 'center' });

  drawRule(doc, theme, 56.6, 108);
}

function drawTitle(doc: jsPDF, theme: Theme, title: string, isSw: boolean): void {
  if (theme.variant === 'modern') {
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(6.5);
    setTextColor(doc, theme.accent);
    doc.text(isSw ? 'HATI RASMI' : 'OFFICIAL DOCUMENT', MARGIN, 53, { charSpace: 1.4 });

    fitFontSize(doc, title, 250, 17, 10, 'helvetica', 'bold');
    setTextColor(doc, theme.ink);
    doc.text(title, MARGIN, 62, { charSpace: 0.2 });

    setDrawColor(doc, theme.accent);
    doc.setLineWidth(0.9);
    doc.line(MARGIN, 66, MARGIN + 30, 66);
    return;
  }

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(6.5);
  setTextColor(doc, theme.accent);
  doc.text(isSw ? 'HATI RASMI YA KANISA' : 'OFFICIAL CHURCH DOCUMENT', CENTER_X, 62, {
    align: 'center',
    charSpace: 1.4
  });

  fitFontSize(doc, title, 246, 17, 10, 'times', 'bold');
  setTextColor(doc, theme.ink);
  doc.text(title, CENTER_X, 71, { align: 'center', charSpace: 0.5 });

  drawRule(doc, theme, 75, 34);
}

function drawRecipientName(doc: jsPDF, theme: Theme, name: string, baselineY: number): number {
  const modern = theme.variant === 'modern';
  doc.setFont(modern ? 'helvetica' : 'times', 'bold');
  let size = modern ? 25 : 27;

  while (size > 15) {
    doc.setFontSize(size);
    if (doc.getTextWidth(name) <= (modern ? 235 : 222)) break;
    size -= 1;
  }

  doc.setFontSize(size);
  let lines = [name];
  let lineHeight = 8.2;

  if (doc.getTextWidth(name) > (modern ? 235 : 222)) {
    doc.setFontSize(17);
    lines = doc.splitTextToSize(name, modern ? 235 : 222) as string[];
    lineHeight = 7.2;
  }

  setTextColor(doc, theme.ink);
  if (modern) {
    drawLeftLines(doc, lines, MARGIN, baselineY, lineHeight);
  } else {
    drawCenteredLines(doc, lines, baselineY, lineHeight);
  }

  const lastLineWidth = Math.min(doc.getTextWidth(lines[lines.length - 1]), 235);
  const underlineY = baselineY + (lines.length - 1) * lineHeight + 3.2;

  setDrawColor(doc, theme.accent);
  doc.setLineWidth(0.8);
  if (modern) {
    doc.line(MARGIN, underlineY, MARGIN + Math.max(60, lastLineWidth + 8), underlineY);
  } else {
    doc.line(CENTER_X - lastLineWidth / 2 - 9, underlineY, CENTER_X + lastLineWidth / 2 + 9, underlineY);
  }

  setDrawColor(doc, theme.hairline);
  doc.setLineWidth(0.18);
  if (modern) {
    doc.line(MARGIN, underlineY + 1.4, PAGE_WIDTH - MARGIN, underlineY + 1.4);
  } else {
    doc.line(CENTER_X - 74, underlineY + 1.2, CENTER_X + 74, underlineY + 1.2);
  }

  return underlineY + 8;
}

function drawBody(doc: jsPDF, theme: Theme, input: CertificatePdfInput, isSw: boolean): void {
  const modern = theme.variant === 'modern';
  const definition = CERTIFICATE_DEFINITIONS[input.type];
  const recipientName = textOrDefault(input.recipientName, isSw ? 'Mpokeaji' : 'Recipient');
  const intro = isSw ? 'Hati hii inathibitisha kwamba:' : 'This certifies that:';

  let cursorY: number;
  // Keep the content block optically centred in the space between the title
  // rule and the footer rule (this mirrors the flex centring in the preview).
  const shift = modern ? 6 : 9;

  if (modern) {
    doc.setFont('helvetica', 'italic');
    doc.setFontSize(9.4);
    setTextColor(doc, theme.muted);
    doc.text(intro, MARGIN, 77 + shift);

    cursorY = drawRecipientName(doc, theme, recipientName, 88 + shift);
  } else {
    doc.setFont('times', 'italic');
    doc.setFontSize(9.8);
    setTextColor(doc, theme.muted);
    doc.text(intro, CENTER_X, 80 + shift, { align: 'center' });

    cursorY = drawRecipientName(doc, theme, recipientName, 89.5 + shift);
  }

  if (input.type === 'marriage') {
    const spouseLine = `${isSw ? 'Na' : 'And'} ${textOrDefault(input.spouseName, isSw ? 'Mwanandoa' : 'Spouse')}`;
    fitFontSize(doc, spouseLine, 228, 11.5, 8, modern ? 'helvetica' : 'times', 'bold');
    setTextColor(doc, theme.ink);
    if (modern) doc.text(spouseLine, MARGIN, cursorY);
    else doc.text(spouseLine, CENTER_X, cursorY, { align: 'center' });
    cursorY += 8;
  }

  if (input.type === 'dedication') {
    const parentLine = `${isSw ? 'Mtoto wa' : 'Child of'}: ${textOrDefault(input.parentNames, isSw ? 'Wazazi' : 'Parents')}`;
    fitFontSize(doc, parentLine, 228, 9.2, 7, modern ? 'helvetica' : 'times', 'normal');
    setTextColor(doc, theme.ink);
    if (modern) doc.text(parentLine, MARGIN, cursorY);
    else doc.text(parentLine, CENTER_X, cursorY, { align: 'center' });
    cursorY += 7;
  }

  doc.setFont(modern ? 'helvetica' : 'times', 'normal');
  doc.setFontSize(modern ? 9.4 : 9.8);
  setTextColor(doc, theme.ink);
  const bodyLines = doc.splitTextToSize(certificateBody(input.type, input.language), modern ? 236 : 228) as string[];
  if (modern) drawLeftLines(doc, bodyLines, MARGIN, cursorY + 2, 5.2);
  else drawCenteredLines(doc, bodyLines, cursorY + 1.5, 5.2);
  cursorY += (bodyLines.length - 1) * 5.2 + 9;

  const notes = input.notes?.trim();
  if (notes) {
    const noteLines = doc.splitTextToSize(
      `${isSw ? 'Mahali / Maelezo' : 'Location / Notes'}: ${notes}`,
      modern ? 236 : 208
    ) as string[];
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.2);
    setTextColor(doc, theme.muted);
    if (modern) drawLeftLines(doc, noteLines, MARGIN, cursorY, 3.7);
    else drawCenteredLines(doc, noteLines, cursorY + 1, 3.7);
    cursorY += noteLines.length * 3.7 + 2;
  }

  // Scripture: a quiet panel, never a decorative element.
  const quote = textOrDefault(input.scripture, definition.defaultVerse).replace(/"/g, '');
  doc.setFont(modern ? 'helvetica' : 'times', 'italic');
  doc.setFontSize(modern ? 9 : 8.7);
  setTextColor(doc, theme.ink);
  const quoteText = `“${quote}”`;
  const quoteLines = doc.splitTextToSize(quoteText, modern ? 232 : 208) as string[];
  const quoteHeight = 10 + quoteLines.length * 4.6;
  const boxTop = Math.min(cursorY + 2, 154 - quoteHeight);

  setFillColor(doc, theme.surface);
  setDrawColor(doc, theme.hairline);
  doc.setLineWidth(0.22);
  if (modern) {
    doc.rect(MARGIN, boxTop, PAGE_WIDTH - MARGIN * 2, quoteHeight, 'FD');
    setFillColor(doc, theme.accent);
    doc.rect(MARGIN, boxTop + 2, 1.1, quoteHeight - 4, 'F');
    doc.setFont('helvetica', 'italic');
    doc.setFontSize(9);
    drawLeftLines(doc, quoteLines, MARGIN + 6, boxTop + 5.8, 4.6);
  } else {
    doc.roundedRect(CENTER_X - 110, boxTop, 220, quoteHeight, 2, 2, 'FD');
    setFillColor(doc, theme.accent);
    doc.rect(CENTER_X - 110, boxTop + 2.5, 0.9, quoteHeight - 5, 'F');
    drawCenteredLines(doc, quoteLines, boxTop + 5.8, 4.6);
  }
}

function drawFooter(doc: jsPDF, theme: Theme, input: CertificatePdfInput, isSw: boolean): void {
  const modern = theme.variant === 'modern';
  const issuedDate = formatCertificateDate(localIsoDate(new Date()), input.language);
  const eventDate = formatCertificateDate(input.eventDate, input.language);

  const meta: Array<{ label: string; value: string }> = [
    { label: isSw ? 'IMETOLEWA' : 'ISSUED', value: issuedDate },
    { label: isSw ? 'TAREHE YA TUKIO' : 'DATE OF EVENT', value: eventDate },
    { label: isSw ? 'NAMBA YA UTHIBITISHO' : 'VERIFICATION NO.', value: input.serialNumber }
  ];

  drawRule(doc, theme, 166, 118);

  const columns = modern ? [MARGIN, 108, 196] : [46, CENTER_X, PAGE_WIDTH - 46];
  meta.forEach((item, index) => {
    const x = columns[index];
    const align = modern ? undefined : 'center';

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(6.2);
    setTextColor(doc, theme.accent);
    doc.text(item.label, x, 173, align ? { align, charSpace: 0.7 } : { charSpace: 0.7 });

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8.2);
    setTextColor(doc, theme.ink);
    doc.text(item.value, x, 179, align ? { align } : {});
  });

  setDrawColor(doc, theme.hairline);
  doc.setLineWidth(0.2);
  doc.line(modern ? MARGIN : 30, 187, modern ? PAGE_WIDTH - MARGIN : 267, 187);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(6.2);
  setTextColor(doc, theme.muted);

  if (modern) {
    doc.text(CHURCH_PROFILE.name, MARGIN, 192);
    doc.text(`${CHURCH_PROFILE.email}  •  ${CHURCH_PROFILE.phone}`, CENTER_X, 192, { align: 'center' });
    doc.text(isSw ? 'HATI RASMI' : 'OFFICIAL DOCUMENT', PAGE_WIDTH - MARGIN, 192, { align: 'right' });
  } else {
    doc.text(
      `${CHURCH_PROFILE.name}  •  ${CHURCH_PROFILE.email}  •  ${CHURCH_PROFILE.phone}`,
      CENTER_X,
      192,
      { align: 'center' }
    );
  }
}

function safeFileName(value: string): string {
  const cleaned = value
    .trim()
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 40);

  return cleaned || 'certificate';
}

export function certificateFileName(input: CertificatePdfInput): string {
  return `Zion-${CERTIFICATE_DEFINITIONS[input.type].serialCode}-${safeFileName(input.recipientName)}-${input.serialNumber}.pdf`;
}

export async function createCertificatePdf(input: CertificatePdfInput): Promise<jsPDF> {
  const title = input.language === 'sw'
    ? CERTIFICATE_DEFINITIONS[input.type].titleSw
    : CERTIFICATE_DEFINITIONS[input.type].titleEn;
  const isSw = input.language === 'sw';
  const theme = themeFor(input.variant ?? 'classic');
  const logo = await loadLogo();

  const doc = new jsPDF({
    orientation: 'landscape',
    unit: 'mm',
    format: 'a4',
    compress: true
  });

  doc.setProperties({
    title: `${title} - ${textOrDefault(input.recipientName, 'Certificate')}`,
    subject: isSw ? 'Cheti rasmi cha kanisa' : 'Official church certificate',
    author: CHURCH_PROFILE.name,
    creator: 'Zion Jerusalem Church Portal',
    keywords: `certificate,${input.type},${input.serialNumber},${theme.variant}`
  });

  drawBackground(doc, theme);
  drawWatermark(doc, theme, logo);
  drawHeader(doc, theme, logo, isSw);
  drawTitle(doc, theme, title, isSw);
  drawBody(doc, theme, input, isSw);
  drawFooter(doc, theme, input, isSw);

  return doc;
}

export async function downloadCertificatePdf(input: CertificatePdfInput): Promise<string> {
  const doc = await createCertificatePdf(input);
  const fileName = certificateFileName(input);
  doc.save(fileName);
  return fileName;
}
