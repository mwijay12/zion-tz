import { GState, jsPDF } from 'jspdf';
import { CERTIFICATE_DEFINITIONS, certificateBody } from '../data/certificateContent';
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
}

type Rgb = readonly [number, number, number];

const PAGE_WIDTH = 297;
const PAGE_HEIGHT = 210;
const CENTER_X = PAGE_WIDTH / 2;

const COLORS: Record<string, Rgb> = {
  paper: [255, 253, 250],
  cream: [253, 247, 231],
  navy: [30, 58, 138],
  navyDeep: [15, 23, 42],
  gold: [180, 120, 20],
  goldDeep: [146, 64, 14],
  goldLight: [232, 190, 100],
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

function drawBackground(doc: jsPDF): void {
  setFillColor(doc, COLORS.paper);
  doc.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, 'F');

  setDrawColor(doc, COLORS.gold);
  doc.setLineWidth(1.15);
  doc.rect(9, 9, 279, 192);
  doc.setLineWidth(0.32);
  doc.rect(12.5, 12.5, 272, 185);

  setDrawColor(doc, COLORS.navy);
  doc.setLineWidth(0.22);
  doc.rect(15, 15, 267, 180);

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

  fitFontSize(doc, CHURCH_PROFILE.name, 252, 21, 14, 'times', 'bold');
  setTextColor(doc, COLORS.navy);
  doc.text(CHURCH_PROFILE.name, CENTER_X, 42.5, { align: 'center' });

  fitFontSize(doc, isSw ? CHURCH_PROFILE.motto : CHURCH_PROFILE.mottoEn, 240, 8.6, 7, 'times', 'bolditalic');
  setTextColor(doc, COLORS.goldDeep);
  doc.text(isSw ? CHURCH_PROFILE.motto : CHURCH_PROFILE.mottoEn, CENTER_X, 48.2, { align: 'center' });

  const contactLine = `${CHURCH_PROFILE.location}  •  ${CHURCH_PROFILE.phone}`;
  fitFontSize(doc, contactLine, 254, 7.4, 6.4, 'helvetica', 'normal');
  setTextColor(doc, COLORS.muted);
  doc.text(contactLine, CENTER_X, 53.4, { align: 'center' });
}

function drawRibbon(doc: jsPDF, title: string): void {
  const ribbonWidth = 176;
  const ribbonHeight = 13;
  const ribbonY = 58.5;

  setFillColor(doc, COLORS.navy);
  setDrawColor(doc, COLORS.gold);
  doc.setLineWidth(0.55);
  doc.roundedRect(CENTER_X - ribbonWidth / 2, ribbonY, ribbonWidth, ribbonHeight, 6.5, 6.5, 'FD');

  fitFontSize(doc, title, ribbonWidth - 16, 13, 8, 'times', 'bold');
  setTextColor(doc, COLORS.ribbonText);
  doc.text(title, CENTER_X, ribbonY + 8.7, { align: 'center' });
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
  doc.setLineWidth(0.9);
  doc.line(CENTER_X - lastLineWidth / 2 - 9, underlineY, CENTER_X + lastLineWidth / 2 + 9, underlineY);

  return underlineY + 7;
}

function drawBody(doc: jsPDF, input: CertificatePdfInput, isSw: boolean): void {
  const definition = CERTIFICATE_DEFINITIONS[input.type];
  const recipientName = textOrDefault(input.recipientName, isSw ? 'Mpokeaji' : 'Recipient');
  let cursorY = 78.5;

  doc.setFont('times', 'italic');
  doc.setFontSize(9.8);
  setTextColor(doc, COLORS.ink);
  doc.text(isSw ? 'Hati hii inathibitisha kwamba:' : 'This certifies that:', CENTER_X, cursorY, {
    align: 'center'
  });

  cursorY = drawRecipientName(doc, recipientName, 88.5);

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

  const quote = textOrDefault(input.scripture, definition.defaultVerse);
  doc.setFont('times', 'italic');
  doc.setFontSize(8.7);
  setTextColor(doc, COLORS.muted);
  const quoteLines = doc.splitTextToSize(`“${quote}”`, 208) as string[];
  const quoteHeight = 10 + quoteLines.length * 4.6;

  setFillColor(doc, COLORS.cream);
  setDrawColor(doc, COLORS.goldLight);
  doc.setLineWidth(0.3);
  doc.roundedRect(CENTER_X - 110, cursorY, 220, quoteHeight, 2.5, 2.5, 'FD');
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
    if (noteY + noteLines.length * 3.7 <= 149) {
      drawCenteredLines(doc, noteLines, noteY, 3.7);
    }
  }
}

function drawSignature(
  doc: jsPDF,
  centerX: number,
  baselineY: number,
  width: number,
  role: string,
  dateText?: string
): void {
  setDrawColor(doc, COLORS.navy);
  doc.setLineWidth(0.5);
  doc.line(centerX - width / 2, baselineY + 3, centerX + width / 2, baselineY + 3);

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(6.6);
  setTextColor(doc, COLORS.navy);
  doc.text(role.toUpperCase(), centerX, baselineY + 7.5, { align: 'center' });

  if (dateText) {
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(6.5);
    setTextColor(doc, COLORS.muted);
    doc.text(dateText, centerX, baselineY + 11.5, { align: 'center' });
  }
}

function drawStampPlaceholder(doc: jsPDF, serialNumber: string, isSw: boolean): void {
  const stampY = 164.5;

  setDrawColor(doc, COLORS.gold);
  doc.setLineWidth(0.7);
  doc.setLineDashPattern([1.2, 0.9], 0);
  doc.circle(CENTER_X, stampY, 13.5);
  doc.setLineDashPattern([], 0);

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(5);
  setTextColor(doc, COLORS.muted);
  doc.text(isSw ? 'MUHURI WA KANISA' : 'CHURCH STAMP', CENTER_X, stampY - 0.8, {
    align: 'center'
  });

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(4.3);
  doc.text(isSw ? 'weka muhuri hapa' : 'affix stamp here', CENTER_X, stampY + 3.2, {
    align: 'center'
  });

  doc.setFont('courier', 'normal');
  doc.setFontSize(6.3);
  setTextColor(doc, COLORS.muted);
  doc.text(serialNumber, CENTER_X, 183.5, { align: 'center' });
}

function drawFooter(doc: jsPDF, input: CertificatePdfInput, isSw: boolean): void {
  const eventDate = formatCertificateDate(input.eventDate, input.language);

  drawSignature(
    doc,
    66,
    171,
    62,
    isSw ? 'Mchungaji Kiongozi' : 'Senior Pastor'
  );
  drawSignature(
    doc,
    231,
    171,
    62,
    isSw ? 'Katibu wa Kanisa' : 'Church Secretary',
    `${isSw ? 'Tarehe ya Tukio' : 'Event Date'}: ${eventDate}`
  );
  drawStampPlaceholder(doc, input.serialNumber, isSw);

  const issuedDate = formatCertificateDate(localIsoDate(new Date()), input.language);
  setDrawColor(doc, COLORS.goldLight);
  doc.setLineWidth(0.35);
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
  drawRibbon(doc, title);
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
