import { GState, jsPDF } from 'jspdf';
import { CERTIFICATE_DEFINITIONS, certificateBody } from '../data/certificateContent';
import { CHURCH_PROFILE } from '../data/mockData';
import { signatureImageFormat } from './certificateSettingsService';
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
  /**
   * Optional signature images (data URLs). Both are empty by default: the
   * certificate prints clean blank lines to be signed physically with a pen.
   * They can be supplied later from the studio's signature settings.
   */
  pastorSignature?: string | null;
  secretarySignature?: string | null;
}

type Rgb = readonly [number, number, number];

const PAGE_WIDTH = 297;
const PAGE_HEIGHT = 210;
const CENTER_X = PAGE_WIDTH / 2;

const COLORS: Record<string, Rgb> = {
  paper: [255, 253, 248],
  paperDeep: [253, 249, 240],
  cream: [253, 247, 231],
  navy: [30, 58, 138],
  navyDeep: [15, 23, 42],
  gold: [180, 120, 20],
  goldDeep: [146, 64, 14],
  goldLight: [232, 190, 100],
  goldSoft: [212, 178, 104],
  ribbonText: [254, 243, 199],
  ink: [51, 65, 85],
  muted: [100, 116, 139]
};

const SW_MONTHS = [
  'Januari',
  'Februari',
  'Machi',
  'Aprili',
  'Mei',
  'Juni',
  'Julai',
  'Agosti',
  'Septemba',
  'Oktoba',
  'Novemba',
  'Desemba'
];

const EN_MONTHS = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

let logoPromise: Promise<string | null> | null = null;

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
): void {
  let size = startSize;
  doc.setFont(font, style);
  while (size > minSize) {
    doc.setFontSize(size);
    if (doc.getTextWidth(text) <= maxWidth) {
      return;
    }
    size -= 0.5;
  }
  doc.setFontSize(minSize);
}

function drawCenteredLines(doc: jsPDF, lines: string[], y: number, lineHeight: number): void {
  lines.forEach((line, index) => {
    doc.text(line, CENTER_X, y + index * lineHeight, { align: 'center' });
  });
}

function loadLogo(): Promise<string | null> {
  if (logoPromise) {
    return logoPromise;
  }

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
  if (!match) {
    return value;
  }

  const months = language === 'sw' ? SW_MONTHS : EN_MONTHS;
  const month = months[Number(match[2]) - 1];
  if (!month) {
    return value;
  }

  return `${Number(match[3])} ${month} ${match[1]}`;
}

export function createCertificateSerial(type: CertificateType, issuedAt = new Date()): string {
  const randomPart =
    globalThis.crypto?.randomUUID?.().replace(/-/g, '').slice(0, 6).toUpperCase() ??
    Math.random().toString(36).slice(2, 8).toUpperCase();

  return `ZJ-${CERTIFICATE_DEFINITIONS[type].serialCode}-${issuedAt.getFullYear()}-${randomPart}`;
}

/** Fine gold rule with a small centre lozenge. */
function drawRule(doc: jsPDF, y: number, halfWidth: number): void {
  setDrawColor(doc, COLORS.goldSoft);
  doc.setLineWidth(0.22);
  doc.line(CENTER_X - halfWidth, y, CENTER_X - 2.4, y);
  doc.line(CENTER_X + 2.4, y, CENTER_X + halfWidth, y);
  setFillColor(doc, COLORS.gold);
  setDrawColor(doc, COLORS.gold);
  doc.setLineWidth(0.2);
  doc.circle(CENTER_X, y, 1.1, 'FD');
}

function drawBackground(doc: jsPDF): void {
  setFillColor(doc, COLORS.paper);
  doc.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, 'F');

  // Subtle ivory panel inside the engraved frame.
  setFillColor(doc, COLORS.paperDeep);
  doc.rect(15, 15, 267, 180, 'F');

  setDrawColor(doc, COLORS.gold);
  doc.setLineWidth(0.95);
  doc.rect(9, 9, 279, 192);
  doc.setLineWidth(0.28);
  doc.rect(12.5, 12.5, 272, 185);

  setDrawColor(doc, COLORS.navy);
  doc.setLineWidth(0.18);
  doc.rect(15.8, 15.8, 265.4, 178.4);

  const corners: Array<[number, number, number, number]> = [
    [20, 20, 1, 1],
    [277, 20, -1, 1],
    [20, 190, 1, -1],
    [277, 190, -1, -1]
  ];

  corners.forEach(([x, y, xDirection, yDirection]) => {
    setDrawColor(doc, COLORS.goldDeep);
    doc.setLineWidth(1.05);
    doc.line(x, y, x + xDirection * 12, y);
    doc.line(x, y, x, y + yDirection * 12);
    doc.setLineWidth(0.35);
    doc.line(x + xDirection * 4, y + yDirection * 4, x + xDirection * 12, y + yDirection * 4);
    doc.line(x + xDirection * 4, y + yDirection * 4, x + xDirection * 4, y + yDirection * 12);
  });
}

function drawWatermark(doc: jsPDF, logo: string | null): void {
  if (!logo) {
    doc.setFont('times', 'bold');
    doc.setFontSize(78);
    doc.setTextColor(249, 245, 235);
    doc.text('ZJ', CENTER_X, 125, { align: 'center' });
    return;
  }

  doc.saveGraphicsState();
  doc.setGState(new GState({ opacity: 0.045 }));
  doc.addImage(logo, 'PNG', CENTER_X - 42, 57, 84, 84, undefined, 'FAST');
  doc.restoreGraphicsState();
}

function drawHeader(doc: jsPDF, logo: string | null, isSw: boolean): void {
  const logoCenterY = 25;

  if (logo) {
    doc.addImage(logo, 'PNG', CENTER_X - 8.5, logoCenterY - 8.5, 17, 17, undefined, 'FAST');
  } else {
    setFillColor(doc, COLORS.cream);
    doc.circle(CENTER_X, logoCenterY, 8.5, 'F');
    doc.setFont('times', 'bold');
    doc.setFontSize(12);
    setTextColor(doc, COLORS.goldDeep);
    doc.text('ZJ', CENTER_X, logoCenterY + 1.8, { align: 'center' });
  }

  setDrawColor(doc, COLORS.gold);
  doc.setLineWidth(0.65);
  doc.circle(CENTER_X, logoCenterY, 9.2);

  fitFontSize(doc, CHURCH_PROFILE.name, 252, 20, 14, 'times', 'bold');
  setTextColor(doc, COLORS.navy);
  doc.text(CHURCH_PROFILE.name, CENTER_X, 42.5, { align: 'center', charSpace: 0.9 });

  fitFontSize(doc, isSw ? CHURCH_PROFILE.motto : CHURCH_PROFILE.mottoEn, 240, 8.6, 7, 'times', 'bolditalic');
  setTextColor(doc, COLORS.goldDeep);
  doc.text(isSw ? CHURCH_PROFILE.motto : CHURCH_PROFILE.mottoEn, CENTER_X, 48.2, {
    align: 'center',
    charSpace: 0.5
  });

  const contactLine = `${CHURCH_PROFILE.location}  •  ${CHURCH_PROFILE.phone}`;
  fitFontSize(doc, contactLine, 254, 7.4, 6.4, 'helvetica', 'normal');
  setTextColor(doc, COLORS.muted);
  doc.text(contactLine, CENTER_X, 53.4, { align: 'center' });

  drawRule(doc, 56.6, 108);
}

/** Restrained engraved title block (replaces the old heavy blue pill ribbon). */
function drawTitle(doc: jsPDF, title: string, isSw: boolean): void {
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(6.5);
  setTextColor(doc, COLORS.goldDeep);
  doc.text(isSw ? 'HATI RASMI YA KANISA' : 'OFFICIAL CHURCH DOCUMENT', CENTER_X, 62, {
    align: 'center',
    charSpace: 1.4
  });

  fitFontSize(doc, title, 246, 17, 10, 'times', 'bold');
  setTextColor(doc, COLORS.navy);
  doc.text(title, CENTER_X, 71, { align: 'center', charSpace: 0.5 });

  drawRule(doc, 75, 34);
}

function drawRecipientName(doc: jsPDF, name: string, baselineY: number): number {
  doc.setFont('times', 'bold');
  let size = 27;

  while (size > 15) {
    doc.setFontSize(size);
    if (doc.getTextWidth(name) <= 222) {
      break;
    }
    size -= 1;
  }

  doc.setFontSize(size);
  let lines = [name];
  let lineHeight = 8.2;

  if (doc.getTextWidth(name) > 222) {
    doc.setFontSize(17);
    lines = doc.splitTextToSize(name, 222) as string[];
    lineHeight = 7.2;
  }

  setTextColor(doc, COLORS.navy);
  lines.forEach((line, index) => {
    doc.text(line, CENTER_X, baselineY + index * lineHeight, { align: 'center' });
  });

  const lastLineWidth = Math.min(doc.getTextWidth(lines[lines.length - 1]), 222);
  const underlineY = baselineY + (lines.length - 1) * lineHeight + 3.2;
  setDrawColor(doc, COLORS.gold);
  doc.setLineWidth(0.8);
  doc.line(CENTER_X - lastLineWidth / 2 - 9, underlineY, CENTER_X + lastLineWidth / 2 + 9, underlineY);
  setDrawColor(doc, COLORS.goldSoft);
  doc.setLineWidth(0.18);
  doc.line(CENTER_X - 74, underlineY + 1.2, CENTER_X + 74, underlineY + 1.2);

  return underlineY + 8;
}

function drawBody(doc: jsPDF, input: CertificatePdfInput, isSw: boolean): void {
  const definition = CERTIFICATE_DEFINITIONS[input.type];
  const recipientName = textOrDefault(input.recipientName, isSw ? 'Mpokeaji' : 'Recipient');
  let cursorY = 80;

  doc.setFont('times', 'italic');
  doc.setFontSize(9.8);
  setTextColor(doc, COLORS.ink);
  doc.text(isSw ? 'Hati hii inathibitisha kwamba:' : 'This certifies that:', CENTER_X, cursorY, {
    align: 'center'
  });

  cursorY = drawRecipientName(doc, recipientName, 89.5);

  if (input.type === 'marriage') {
    const spouseName = textOrDefault(input.spouseName, isSw ? 'Mwanandoa' : 'Spouse');
    const spouseLine = `${isSw ? 'Na' : 'And'} ${spouseName}`;
    fitFontSize(doc, spouseLine, 228, 11.5, 8, 'times', 'bold');
    setTextColor(doc, COLORS.navy);
    doc.text(spouseLine, CENTER_X, cursorY, { align: 'center' });
    cursorY += 8;
  }

  if (input.type === 'dedication') {
    const parentNames = textOrDefault(input.parentNames, isSw ? 'Wazazi' : 'Parents');
    const parentLine = `${isSw ? 'Mtoto wa' : 'Child of'}: ${parentNames}`;
    fitFontSize(doc, parentLine, 228, 9.2, 7, 'times', 'normal');
    setTextColor(doc, COLORS.ink);
    doc.text(parentLine, CENTER_X, cursorY, { align: 'center' });
    cursorY += 7;
  }

  doc.setFont('times', 'normal');
  doc.setFontSize(9.8);
  setTextColor(doc, COLORS.ink);
  const bodyLines = doc.splitTextToSize(certificateBody(input.type, input.language), 228) as string[];
  drawCenteredLines(doc, bodyLines, cursorY + 1.5, 5.2);
  cursorY += (bodyLines.length - 1) * 5.2 + 8.5;

  // Verse templates already contain straight quotes inside them; strip those
  // so the enclosing typographic quotes never double up.
  const quote = textOrDefault(input.scripture, definition.defaultVerse).replace(/"/g, '');
  doc.setFont('times', 'italic');
  doc.setFontSize(8.7);
  setTextColor(doc, COLORS.muted);
  const quoteLines = doc.splitTextToSize(`“${quote}”`, 208) as string[];
  const quoteHeight = 10 + quoteLines.length * 4.6;

  setFillColor(doc, COLORS.cream);
  setDrawColor(doc, COLORS.goldLight);
  doc.setLineWidth(0.25);
  doc.roundedRect(CENTER_X - 110, cursorY, 220, quoteHeight, 2, 2, 'FD');
  setFillColor(doc, COLORS.gold);
  doc.rect(CENTER_X - 110, cursorY + 2.5, 0.9, quoteHeight - 5, 'F');
  drawCenteredLines(doc, quoteLines, cursorY + 5.8, 4.6);
  cursorY += quoteHeight + 4.5;

  const notes = input.notes?.trim();
  if (notes) {
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.2);
    setTextColor(doc, COLORS.muted);
    const noteLines = doc.splitTextToSize(
      `${isSw ? 'Mahali / Maelezo' : 'Location / Notes'}: ${notes}`,
      208
    ) as string[];
    const noteY = cursorY + 1;
    if (noteY + noteLines.length * 3.7 <= 147) {
      drawCenteredLines(doc, noteLines, noteY, 3.7);
    }
  }

  // Small ornamental flourish fills the open space above the signing area.
  drawRule(doc, 152, 16);
}

/**
 * A blank signing line. No handwriting / script names are ever printed unless
 * an administrator explicitly uploads a signature image in the settings.
 */
function drawSigningLine(
  doc: jsPDF,
  centerX: number,
  lineY: number,
  width: number,
  role: string,
  subText: string,
  hint: string,
  signatureImage?: string | null
): void {
  if (signatureImage) {
    try {
      const format = signatureImageFormat(signatureImage);
      const props = doc.getImageProperties(signatureImage);
      const ratio = props.width / Math.max(props.height, 1);
      let w = Math.min(46, width - 8);
      let h = w / ratio;
      if (h > 12) {
        h = 12;
        w = h * ratio;
      }
      doc.addImage(signatureImage, format, centerX - w / 2, lineY - h - 0.8, w, h, undefined, 'FAST');
    } catch {
      // A broken image must never remove the physical signing line.
    }
  } else {
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(5.4);
    setTextColor(doc, COLORS.muted);
    doc.text(hint, centerX, lineY - 2.6, { align: 'center', charSpace: 0.9 });
  }

  setDrawColor(doc, COLORS.navy);
  doc.setLineWidth(0.42);
  doc.line(centerX - width / 2, lineY, centerX + width / 2, lineY);

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(6.8);
  setTextColor(doc, COLORS.navy);
  doc.text(role.toUpperCase(), centerX, lineY + 5, { align: 'center', charSpace: 0.4 });

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(6.2);
  setTextColor(doc, COLORS.muted);
  doc.text(subText, centerX, lineY + 9, { align: 'center' });
}

/** Double-ring engraved church emblem. */
function drawSeal(doc: jsPDF, isSw: boolean): void {
  const cy = 165.5;
  const r = 11.5;

  setDrawColor(doc, COLORS.gold);
  doc.setLineWidth(0.7);
  doc.circle(CENTER_X, cy, r);
  doc.setLineWidth(0.22);
  doc.circle(CENTER_X, cy, r - 1.5);

  doc.setFont('times', 'bold');
  doc.setFontSize(11.5);
  setTextColor(doc, COLORS.goldDeep);
  doc.text('ZJ', CENTER_X, cy + 1.4, { align: 'center' });

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(4.1);
  doc.text(isSw ? 'MUHURI RASMI' : 'OFFICIAL SEAL', CENTER_X, cy + 5.2, {
    align: 'center',
    charSpace: 0.25
  });

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(3.7);
  doc.text('MBAGALA HQ', CENTER_X, cy + 7.8, { align: 'center', charSpace: 0.2 });
}

function drawFooter(doc: jsPDF, input: CertificatePdfInput, isSw: boolean): void {
  const eventDate = formatCertificateDate(input.eventDate, input.language);
  const hint = isSw ? 'SAINI HAPA' : 'SIGN HERE';

  drawSigningLine(
    doc,
    66,
    171,
    64,
    isSw ? 'Mchungaji Kiongozi' : 'Senior Pastor',
    isSw ? 'Kusainiwa kwa mkono' : 'To be signed by hand',
    hint,
    input.pastorSignature
  );
  drawSigningLine(
    doc,
    231,
    171,
    64,
    isSw ? 'Katibu wa Kanisa' : 'Church Secretary',
    `${isSw ? 'Tarehe ya Tukio' : 'Event Date'}: ${eventDate}`,
    hint,
    input.secretarySignature
  );

  drawSeal(doc, isSw);

  doc.setFont('courier', 'normal');
  doc.setFontSize(6.3);
  setTextColor(doc, COLORS.muted);
  doc.text(input.serialNumber, CENTER_X, 183.5, { align: 'center' });

  const issuedDate = formatCertificateDate(localIsoDate(new Date()), input.language);
  setDrawColor(doc, COLORS.goldSoft);
  doc.setLineWidth(0.3);
  doc.line(30, 190, 267, 190);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(6);
  setTextColor(doc, COLORS.muted);
  doc.text(
    `${isSw ? 'Imetolewa' : 'Issued'}: ${issuedDate}  •  ${CHURCH_PROFILE.name}  •  ${CHURCH_PROFILE.phone}`,
    CENTER_X,
    193.6,
    { align: 'center' }
  );
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
    keywords: `certificate,${input.type},${input.serialNumber}`
  });

  drawBackground(doc);
  drawWatermark(doc, logo);
  drawHeader(doc, logo, isSw);
  drawTitle(doc, title, isSw);
  drawBody(doc, input, isSw);
  drawFooter(doc, input, isSw);

  return doc;
}

export async function downloadCertificatePdf(input: CertificatePdfInput): Promise<string> {
  const doc = await createCertificatePdf(input);
  const fileName = certificateFileName(input);
  doc.save(fileName);
  return fileName;
}
