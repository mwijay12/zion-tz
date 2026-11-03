/**
 * Official Church Document PDF Service
 *
 * Generates REAL A4 PDF documents (vector text, selectable, searchable) with jsPDF.
 * This replaces every `window.print()` call in the portal. `window.print()` prints
 * the live web page (sidebar, banners, cards), which produced "screenshot" PDFs.
 * Documents generated here contain ONLY the official letterhead, content, signatures
 * and seal — never any part of the web interface.
 */
import { jsPDF } from 'jspdf';
import { CHURCH_PROFILE, SUNDAY_SCHEDULE } from '../data/mockData';
import type {
  BulletinNotice,
  ChurchExpense,
  FinancialProject,
  FinancialRecord,
  JumuiyaReport,
  VisitorRecord
} from '../types';

type Rgb = readonly [number, number, number];

const PAGE_W = 210;
const PAGE_H = 297;
const MARGIN = 15;
const CONTENT_W = PAGE_W - MARGIN * 2;
const FOOTER_Y = PAGE_H - 10;
const BOTTOM_LIMIT = PAGE_H - 22;

const C: Record<string, Rgb> = {
  navy: [0, 17, 88],
  blue: [13, 82, 205],
  gold: [197, 155, 39],
  ink: [30, 27, 24],
  body: [51, 65, 85],
  muted: [100, 116, 139],
  line: [203, 213, 225],
  zebra: [248, 250, 252],
  headerFill: [236, 240, 252],
  red: [186, 26, 26],
  green: [5, 150, 105]
};

const SW_MONTHS = [
  'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
  'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
];

// ---------------------------------------------------------------------------
// Low-level helpers
// ---------------------------------------------------------------------------

const text = (doc: jsPDF, c: Rgb) => doc.setTextColor(c[0], c[1], c[2]);
const fill = (doc: jsPDF, c: Rgb) => doc.setFillColor(c[0], c[1], c[2]);
const draw = (doc: jsPDF, c: Rgb) => doc.setDrawColor(c[0], c[1], c[2]);

const tsh = (n: number) => `Tsh ${Math.round(n).toLocaleString('en-US')}`;

function todaySw(): string {
  const d = new Date();
  return `${d.getDate()} ${SW_MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}

function makeReference(prefix: string): string {
  const d = new Date();
  const ymd = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
  return `ZJC/${prefix}/${ymd}/${Date.now().toString().slice(-4)}`;
}

let logoPromise: Promise<string | null> | null = null;
function loadLogo(): Promise<string | null> {
  if (logoPromise) return logoPromise;
  const baseUrl = import.meta.env?.BASE_URL ?? '/';
  logoPromise = fetch(`${baseUrl}zion_logo.png`)
    .then((r) => (r.ok ? r.blob() : null))
    .then(
      (blob) =>
        new Promise<string | null>((resolve) => {
          if (!blob) return resolve(null);
          const reader = new FileReader();
          reader.onload = () => resolve(typeof reader.result === 'string' ? reader.result : null);
          reader.onerror = () => resolve(null);
          reader.readAsDataURL(blob);
        })
    )
    .catch(() => null);
  return logoPromise;
}

// ---------------------------------------------------------------------------
// Document builder
// ---------------------------------------------------------------------------

interface DocMeta {
  title: string;
  subtitle?: string;
  office: string;
  refPrefix: string;
  fileName: string;
}

class OfficialDocument {
  readonly doc: jsPDF;
  y = MARGIN;
  readonly reference: string;
  private logo: string | null;
  private meta: DocMeta;

  constructor(meta: DocMeta, logo: string | null) {
    this.doc = new jsPDF({ unit: 'mm', format: 'a4', orientation: 'portrait' });
    this.meta = meta;
    this.logo = logo;
    this.reference = makeReference(meta.refPrefix);
    this.doc.setProperties({
      title: meta.title,
      subject: meta.subtitle ?? meta.title,
      author: CHURCH_PROFILE.nameSw,
      creator: 'Sayuni Admin Portal'
    });
    this.letterhead();
    this.titleBlock();
  }

  private letterhead(): void {
    const { doc } = this;
    const top = MARGIN;
    if (this.logo) {
      try {
        doc.addImage(this.logo, 'PNG', MARGIN, top, 20, 20, undefined, 'FAST');
      } catch {
        /* logo optional */
      }
    }
    const cx = PAGE_W / 2;
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(15);
    text(doc, C.navy);
    doc.text(CHURCH_PROFILE.name, cx, top + 6, { align: 'center' });

    doc.setFontSize(10);
    text(doc, C.gold);
    doc.text(CHURCH_PROFILE.nameSw, cx, top + 11.5, { align: 'center' });

    doc.setFont('helvetica', 'italic');
    doc.setFontSize(8.5);
    text(doc, C.muted);
    doc.text(`"${CHURCH_PROFILE.motto}"`, cx, top + 16, { align: 'center' });

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.8);
    doc.text(
      `Makao Makuu: ${CHURCH_PROFILE.location}  |  Simu: ${CHURCH_PROFILE.phone}  |  ${CHURCH_PROFILE.email}`,
      cx,
      top + 20.5,
      { align: 'center' }
    );

    draw(doc, C.navy);
    doc.setLineWidth(0.8);
    doc.line(MARGIN, top + 24, PAGE_W - MARGIN, top + 24);
    draw(doc, C.gold);
    doc.setLineWidth(0.35);
    doc.line(MARGIN, top + 25.3, PAGE_W - MARGIN, top + 25.3);

    this.y = top + 32;
  }

  private titleBlock(): void {
    const { doc } = this;
    const boxW = 62;
    const leftW = CONTENT_W - boxW - 6;

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(12.5);
    text(doc, C.ink);
    const titleLines = doc.splitTextToSize(this.meta.title.toUpperCase(), leftW) as string[];
    doc.text(titleLines, MARGIN, this.y + 4);
    let leftBottom = this.y + 4 + titleLines.length * 5.4;

    if (this.meta.subtitle) {
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(8.8);
      text(doc, C.muted);
      const sub = doc.splitTextToSize(this.meta.subtitle, leftW) as string[];
      doc.text(sub, MARGIN, leftBottom + 0.5);
      leftBottom += sub.length * 4 + 0.5;
    }

    // Reference box
    const bx = PAGE_W - MARGIN - boxW;
    const by = this.y;
    fill(doc, C.zebra);
    draw(doc, C.line);
    doc.setLineWidth(0.3);
    doc.roundedRect(bx, by, boxW, 18, 1.5, 1.5, 'FD');
    doc.setFontSize(7.8);
    const rows: Array<[string, string]> = [
      ['Tarehe:', todaySw()],
      ['Ofisi:', this.meta.office],
      ['Rejea:', this.reference]
    ];
    rows.forEach(([k, v], i) => {
      doc.setFont('helvetica', 'bold');
      text(doc, C.navy);
      doc.text(k, bx + 3, by + 5 + i * 5);
      doc.setFont('helvetica', 'normal');
      text(doc, C.body);
      const val = doc.splitTextToSize(v, boxW - 18)[0] as string;
      doc.text(val, bx + 16, by + 5 + i * 5);
    });

    this.y = Math.max(leftBottom, by + 18) + 6;
  }

  /** Ensure there's `needed` mm of vertical space, otherwise start a new page. */
  ensure(needed: number): boolean {
    if (this.y + needed > BOTTOM_LIMIT) {
      this.doc.addPage();
      this.y = MARGIN + 4;
      return true;
    }
    return false;
  }

  sectionHeading(label: string): void {
    this.ensure(14);
    const { doc } = this;
    fill(doc, C.gold);
    doc.rect(MARGIN, this.y - 3.6, 1.4, 5, 'F');
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10.5);
    text(doc, C.navy);
    doc.text(label.toUpperCase(), MARGIN + 3.5, this.y);
    this.y += 5.5;
  }

  paragraph(value: string, opts: { size?: number; color?: Rgb; bold?: boolean; italic?: boolean; indent?: number } = {}): void {
    const { doc } = this;
    const size = opts.size ?? 9;
    const indent = opts.indent ?? 0;
    doc.setFont('helvetica', opts.bold ? 'bold' : opts.italic ? 'italic' : 'normal');
    doc.setFontSize(size);
    text(doc, opts.color ?? C.body);
    const lines = doc.splitTextToSize(value, CONTENT_W - indent) as string[];
    const lh = size * 0.45;
    lines.forEach((line) => {
      this.ensure(lh + 1);
      doc.text(line, MARGIN + indent, this.y);
      this.y += lh;
    });
    this.y += 1.5;
  }

  summaryBoxes(items: Array<{ label: string; value: string }>): void {
    if (items.length === 0) return;
    this.ensure(20);
    const { doc } = this;
    const gap = 4;
    const w = (CONTENT_W - gap * (items.length - 1)) / items.length;
    items.forEach((it, i) => {
      const x = MARGIN + i * (w + gap);
      fill(doc, C.headerFill);
      draw(doc, C.line);
      doc.setLineWidth(0.3);
      doc.roundedRect(x, this.y, w, 16, 1.5, 1.5, 'FD');
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(7.3);
      text(doc, C.muted);
      doc.text(doc.splitTextToSize(it.label.toUpperCase(), w - 6)[0] as string, x + 3, this.y + 5.2);
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(11.5);
      text(doc, C.navy);
      doc.text(doc.splitTextToSize(it.value, w - 6)[0] as string, x + 3, this.y + 12);
    });
    this.y += 22;
  }

  keyValueRows(rows: Array<[string, string]>, opts: { totalLast?: boolean } = {}): void {
    const { doc } = this;
    rows.forEach(([k, v], i) => {
      this.ensure(7);
      const isTotal = opts.totalLast && i === rows.length - 1;
      if (isTotal) {
        fill(doc, C.headerFill);
        doc.rect(MARGIN, this.y - 4.2, CONTENT_W, 6.4, 'F');
      }
      doc.setFont('helvetica', isTotal ? 'bold' : 'normal');
      doc.setFontSize(9);
      text(doc, isTotal ? C.navy : C.body);
      doc.text(k, MARGIN + 2, this.y);
      doc.setFont('helvetica', 'bold');
      doc.text(v, PAGE_W - MARGIN - 2, this.y, { align: 'right' });
      draw(doc, C.line);
      doc.setLineWidth(0.2);
      doc.line(MARGIN, this.y + 2.2, PAGE_W - MARGIN, this.y + 2.2);
      this.y += 6.4;
    });
    this.y += 3;
  }

  /**
   * Table with wrapped cells, zebra rows and repeated header on page breaks.
   * Column widths are fractions of the content width (they are normalised).
   */
  table(columns: Array<{ header: string; width: number; align?: 'left' | 'right' | 'center' }>, rows: string[][], emptyMessage = 'Hakuna rekodi zilizopatikana kwa kipindi hiki.'): void {
    const { doc } = this;
    const totalW = columns.reduce((s, c) => s + c.width, 0);
    const widths = columns.map((c) => (c.width / totalW) * CONTENT_W);
    const pad = 1.8;
    const fontSize = 8;
    const lh = 3.6;

    const drawHeader = () => {
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(7.6);
      const headerLines = columns.map((c, i) => doc.splitTextToSize(c.header, widths[i] - pad * 2) as string[]);
      const h = Math.max(...headerLines.map((l) => l.length)) * 3.4 + pad * 2;
      fill(doc, C.navy);
      doc.rect(MARGIN, this.y, CONTENT_W, h, 'F');
      doc.setTextColor(255, 255, 255);
      let x = MARGIN;
      headerLines.forEach((lines, i) => {
        const align = columns[i].align ?? 'left';
        const tx = align === 'right' ? x + widths[i] - pad : align === 'center' ? x + widths[i] / 2 : x + pad;
        doc.text(lines, tx, this.y + pad + 2.6, { align });
        x += widths[i];
      });
      this.y += h;
    };

    this.ensure(18);
    drawHeader();

    if (rows.length === 0) {
      doc.setFont('helvetica', 'italic');
      doc.setFontSize(8.5);
      text(doc, C.muted);
      draw(doc, C.line);
      doc.rect(MARGIN, this.y, CONTENT_W, 10);
      doc.text(emptyMessage, PAGE_W / 2, this.y + 6.2, { align: 'center' });
      this.y += 14;
      return;
    }

    rows.forEach((row, rIdx) => {
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(fontSize);
      const cellLines = row.map((cell, i) => doc.splitTextToSize(cell ?? '', widths[i] - pad * 2) as string[]);
      const h = Math.max(...cellLines.map((l) => l.length)) * lh + pad * 2;

      if (this.ensure(h)) drawHeader();

      if (rIdx % 2 === 1) {
        fill(doc, C.zebra);
        doc.rect(MARGIN, this.y, CONTENT_W, h, 'F');
      }
      draw(doc, C.line);
      doc.setLineWidth(0.2);
      doc.line(MARGIN, this.y + h, PAGE_W - MARGIN, this.y + h);

      doc.setFont('helvetica', 'normal');
      doc.setFontSize(fontSize);
      text(doc, C.ink);
      let x = MARGIN;
      cellLines.forEach((lines, i) => {
        const align = columns[i].align ?? 'left';
        const tx = align === 'right' ? x + widths[i] - pad : align === 'center' ? x + widths[i] / 2 : x + pad;
        doc.text(lines, tx, this.y + pad + 2.8, { align });
        x += widths[i];
      });
      this.y += h;
    });
    this.y += 5;
  }

  noticeCard(n: BulletinNotice): void {
    const { doc } = this;
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8.6);
    const body = doc.splitTextToSize(n.content, CONTENT_W - 10) as string[];
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9.6);
    const titleLines = doc.splitTextToSize(n.title, CONTENT_W - 50) as string[];
    const h = titleLines.length * 4.4 + body.length * 3.9 + 9;
    this.ensure(h + 3);

    const urgent = n.isUrgent || n.type === 'urgent';
    fill(doc, C.zebra);
    draw(doc, C.line);
    doc.setLineWidth(0.25);
    doc.roundedRect(MARGIN, this.y, CONTENT_W, h, 1.2, 1.2, 'FD');
    fill(doc, urgent ? C.red : C.blue);
    doc.rect(MARGIN, this.y, 1.6, h, 'F');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(7);
    text(doc, urgent ? C.red : C.blue);
    doc.text(`${(n.category || 'Taarifa Kuu').toUpperCase()}${urgent ? '  |  DHARURA' : ''}`, MARGIN + 5, this.y + 4.6);
    doc.setFont('helvetica', 'normal');
    text(doc, C.muted);
    doc.text(n.date || '', PAGE_W - MARGIN - 3, this.y + 4.6, { align: 'right' });

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9.6);
    text(doc, C.ink);
    doc.text(titleLines, MARGIN + 5, this.y + 9.4);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(8.6);
    text(doc, C.body);
    doc.text(body, MARGIN + 5, this.y + 9.4 + titleLines.length * 4.4);
    this.y += h + 3;
  }

  signatures(left: { name: string; title: string }, right: { name: string; title: string }): void {
    this.ensure(46);
    const { doc } = this;
    this.y += 6;
    const colW = 58;
    const yLine = this.y + 16;

    const sig = (x: number, label: string, p: { name: string; title: string }) => {
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(7.8);
      text(doc, C.muted);
      doc.text(label, x, this.y);
      draw(doc, C.ink);
      doc.setLineWidth(0.3);
      doc.line(x, yLine, x + colW, yLine);
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(9);
      text(doc, C.ink);
      doc.text(p.name, x, yLine + 4.5);
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(7.6);
      text(doc, C.muted);
      doc.text(doc.splitTextToSize(p.title, colW) as string[], x, yLine + 8.5);
      doc.text(`Tarehe: ${todaySw()}`, x, yLine + 16);
    };

    sig(MARGIN, 'Imeandaliwa na Kuthibitishwa:', left);
    sig(PAGE_W - MARGIN - colW, 'Imeridhiwa na Kuidhinishwa:', right);

    // Official seal (vector)
    const cx = PAGE_W / 2;
    const cy = this.y + 13;
    draw(doc, C.blue);
    doc.setLineWidth(0.6);
    doc.circle(cx, cy, 13);
    doc.setLineWidth(0.25);
    doc.circle(cx, cy, 10.8);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(5.6);
    text(doc, C.blue);
    doc.text('ZION JERUSALEM', cx, cy - 4.5, { align: 'center' });
    doc.setFontSize(6.8);
    doc.text('MUHURI RASMI', cx, cy + 1, { align: 'center' });
    doc.setFontSize(5.6);
    doc.text('MBAGALA HQ', cx, cy + 6, { align: 'center' });

    this.y = yLine + 22;
  }

  private footers(): void {
    const { doc } = this;
    const pages = doc.getNumberOfPages();
    for (let p = 1; p <= pages; p++) {
      doc.setPage(p);
      draw(doc, C.line);
      doc.setLineWidth(0.2);
      doc.line(MARGIN, FOOTER_Y - 4, PAGE_W - MARGIN, FOOTER_Y - 4);
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(7);
      text(doc, C.muted);
      doc.text(`${CHURCH_PROFILE.nameSw}  |  Hati Rasmi  |  Rejea: ${this.reference}`, MARGIN, FOOTER_Y);
      doc.text(`Ukurasa ${p} / ${pages}`, PAGE_W - MARGIN, FOOTER_Y, { align: 'right' });
    }
  }

  /** Opens the PDF in a new tab (print from the PDF viewer). Falls back to download. */
  deliver(): void {
    this.footers();
    const fileName = `${this.meta.fileName}_${new Date().toISOString().slice(0, 10)}.pdf`;
    try {
      const url = this.doc.output('bloburl') as unknown as string;
      const win = window.open(url, '_blank', 'noopener');
      if (!win) this.doc.save(fileName);
    } catch {
      this.doc.save(fileName);
    }
  }

  download(): void {
    this.footers();
    this.doc.save(`${this.meta.fileName}_${new Date().toISOString().slice(0, 10)}.pdf`);
  }
}

async function create(meta: DocMeta): Promise<OfficialDocument> {
  const logo = await loadLogo();
  return new OfficialDocument(meta, logo);
}

const SECRETARY = { name: 'Mwl. Peter Mwita', title: 'Katibu Mkuu wa Kanisa - Sayuni Yerusalemu' };
const BISHOP = { name: 'Askofu Mercy Mgalla', title: 'Mchungaji Askofu Kiongozi - Sayuni Yerusalemu' };
const TREASURER = { name: 'Mhazini Mkuu', title: 'Kamati ya Hazina na Fedha - Sayuni Yerusalemu' };

// ---------------------------------------------------------------------------
// Public generators
// ---------------------------------------------------------------------------

export type PdfMode = 'open' | 'download';

function finish(d: OfficialDocument, mode: PdfMode) {
  if (mode === 'download') d.download();
  else d.deliver();
}

export async function generateVisitorsReportPdf(
  visitors: VisitorRecord[],
  opts: { title?: string; subtitle?: string; mode?: PdfMode } = {}
): Promise<void> {
  const d = await create({
    title: opts.title ?? 'Ripoti Rasmi ya Wageni na Ufuatiliaji wa Kichungaji',
    subtitle: opts.subtitle ?? 'Daftari Kuu la Wageni Waliofika Kanisani - Mbagala Kwa Matope',
    office: 'Sekretarieti / Mashemasi',
    refPrefix: 'WGN',
    fileName: 'Ripoti_ya_Wageni'
  });
  const count = (s: VisitorRecord['followUpStatus']) => visitors.filter((v) => v.followUpStatus === s).length;
  d.summaryBoxes([
    { label: 'Jumla ya Wageni', value: String(visitors.length) },
    { label: 'Wageni Wapya', value: String(count('Mpya')) },
    { label: 'Waliotembelewa', value: String(count('Ametembelewa')) },
    { label: 'Wamejiunga Jumuiya', value: String(count('Amejiunga na Jumuiya')) }
  ]);
  d.sectionHeading('Orodha ya Wageni');
  d.table(
    [
      { header: '#', width: 5, align: 'center' },
      { header: 'Jina Kamili / Ombi', width: 30 },
      { header: 'Simu', width: 17 },
      { header: 'Makazi', width: 16 },
      { header: 'Tarehe', width: 12 },
      { header: 'Jumuiya', width: 12 },
      { header: 'Hali', width: 14 }
    ],
    visitors.map((v, i) => [
      String(i + 1),
      v.prayerRequest ? `${v.fullName}\nOmbi: ${v.prayerRequest}` : v.fullName,
      v.phone,
      v.residence,
      v.firstVisitDate,
      v.assignedJumuiya,
      v.followUpStatus
    ])
  );
  d.paragraph(
    'Taarifa hii ni ya siri ya kichungaji. Taarifa binafsi za wageni zinalindwa kwa mujibu wa Sheria ya Ulinzi wa Taarifa Binafsi (PDPA 2022) na hazipaswi kusambazwa nje ya uongozi wa kanisa.',
    { size: 7.6, italic: true, color: C.muted }
  );
  d.signatures(SECRETARY, BISHOP);
  finish(d, opts.mode ?? 'open');
}

export async function generateGroupsReportPdf(
  reports: JumuiyaReport[],
  opts: { title?: string; subtitle?: string; mode?: PdfMode } = {}
): Promise<void> {
  const d = await create({
    title: opts.title ?? 'Ripoti Jumuishi ya Vikundi na Jumuiya za Nyumbani',
    subtitle: opts.subtitle ?? 'Tathmini ya Mahudhurio, Mafundisho na Sadaka za Nyumba kwa Nyumba',
    office: 'Sekretarieti Kuu ya Kanisa',
    refPrefix: 'JMY',
    fileName: 'Ripoti_ya_Vikundi'
  });
  const attendees = (r: JumuiyaReport) => r.attendeesMen + r.attendeesWomen + r.attendeesYouth + r.attendeesChildren;
  const totalAtt = reports.reduce((s, r) => s + attendees(r), 0);
  const totalOff = reports.reduce((s, r) => s + r.offeringAmount, 0);
  const totalNew = reports.reduce((s, r) => s + (r.newVisitors || 0), 0);
  d.summaryBoxes([
    { label: 'Ripoti Zilizopokelewa', value: String(reports.length) },
    { label: 'Jumla ya Mahudhurio', value: String(totalAtt) },
    { label: 'Wageni Wapya', value: String(totalNew) },
    { label: 'Sadaka za Jumuiya', value: tsh(totalOff) }
  ]);
  d.sectionHeading('Muhtasari kwa Kila Jumuiya');
  d.table(
    [
      { header: '#', width: 5, align: 'center' },
      { header: 'Jumuiya', width: 18 },
      { header: 'Tarehe', width: 12 },
      { header: 'Mwenyeji', width: 16 },
      { header: 'Wanaume / Wanawake / Vijana / Watoto', width: 18, align: 'center' },
      { header: 'Somo', width: 22 },
      { header: 'Sadaka (Tsh)', width: 13, align: 'right' }
    ],
    reports.map((r, i) => [
      String(i + 1),
      r.jumuiyaName,
      r.reportDate,
      r.hostFamily || '-',
      `${r.attendeesMen} / ${r.attendeesWomen} / ${r.attendeesYouth} / ${r.attendeesChildren}\nJumla: ${attendees(r)}`,
      r.scriptureTopic,
      r.offeringAmount.toLocaleString('en-US')
    ])
  );
  const needs = reports.filter((r) => r.prayerRequests || r.sickOrWelfareNeeds);
  if (needs.length) {
    d.sectionHeading('Mahitaji ya Maombi na Ustawi');
    needs.forEach((r) => {
      d.paragraph(r.jumuiyaName, { bold: true, size: 9, color: C.navy });
      if (r.prayerRequests) d.paragraph(`Maombi: ${r.prayerRequests}`, { size: 8.6, indent: 3 });
      if (r.sickOrWelfareNeeds) d.paragraph(`Ustawi: ${r.sickOrWelfareNeeds}`, { size: 8.6, indent: 3 });
    });
  }
  d.signatures(SECRETARY, BISHOP);
  finish(d, opts.mode ?? 'open');
}

export async function generateJumuiyaReportPdf(report: JumuiyaReport, mode: PdfMode = 'open'): Promise<void> {
  const d = await create({
    title: `Ripoti ya Jumuiya: ${report.jumuiyaName}`,
    subtitle: `Ibada ya nyumbani ya tarehe ${report.reportDate} - Nakala ya Faili`,
    office: 'Jumuiya za Nyumbani',
    refPrefix: 'JMR',
    fileName: `Ripoti_Jumuiya_${report.jumuiyaName.replace(/\s+/g, '_')}`
  });
  const total = report.attendeesMen + report.attendeesWomen + report.attendeesYouth + report.attendeesChildren;
  d.summaryBoxes([
    { label: 'Jumla ya Mahudhurio', value: String(total) },
    { label: 'Wageni Wapya', value: String(report.newVisitors || 0) },
    { label: 'Sadaka', value: tsh(report.offeringAmount) }
  ]);
  d.sectionHeading('Taarifa za Ibada');
  d.keyValueRows([
    ['Mwenyeji / Nyumba ya Ibada', report.hostFamily || '-'],
    ['Somo / Neno Lililofundishwa', report.scriptureTopic || '-'],
    ['Wanaume', String(report.attendeesMen)],
    ['Wanawake', String(report.attendeesWomen)],
    ['Vijana', String(report.attendeesYouth)],
    ['Watoto', String(report.attendeesChildren)],
    ['Imewasilishwa na', `${report.submittedBy} (${report.submittedAt})`]
  ]);
  if (report.prayerRequests) {
    d.sectionHeading('Maombi Maalum ya Washirika');
    d.paragraph(report.prayerRequests);
  }
  if (report.sickOrWelfareNeeds) {
    d.sectionHeading('Wagonjwa na Mahitaji ya Ustawi');
    d.paragraph(report.sickOrWelfareNeeds);
  }
  d.signatures({ name: report.submittedBy, title: `Kiongozi - ${report.jumuiyaName}` }, SECRETARY);
  finish(d, mode);
}

export async function generateBulletinPdf(
  notices: BulletinNotice[],
  opts: {
    title?: string;
    subtitle?: string;
    includeSchedule?: boolean;
    finance?: { monthIncome: number; projectTitle?: string; projectPercent?: number };
    mode?: PdfMode;
  } = {}
): Promise<void> {
  const d = await create({
    title: opts.title ?? 'Kijarida Rasmi cha Matangazo ya Jumapili',
    subtitle: opts.subtitle ?? `${CHURCH_PROFILE.headPastor}  |  Usimamizi: ${CHURCH_PROFILE.bishopHusband}`,
    office: 'Sekretarieti Kuu ya Kanisa',
    refPrefix: 'KJR',
    fileName: 'Kijarida_cha_Matangazo'
  });
  const publicNotices = notices.filter((n) => !n.targetAudience || n.targetAudience === 'all');
  d.summaryBoxes([
    { label: 'Matangazo ya Wiki', value: String(publicNotices.length) },
    { label: 'Ya Dharura', value: String(publicNotices.filter((n) => n.isUrgent || n.type === 'urgent').length) },
    { label: 'Wigo', value: 'Waumini Wote' }
  ]);
  if (opts.includeSchedule !== false) {
    d.sectionHeading('Ratiba ya Ibada ya Jumapili');
    d.table(
      [
        { header: 'Muda', width: 22 },
        { header: 'Kipindi', width: 78 }
      ],
      SUNDAY_SCHEDULE.map((s) => [s.time, s.desc ? `${s.title}\n${s.desc}` : s.title])
    );
  }
  d.sectionHeading('Matangazo ya Wiki Hii');
  if (publicNotices.length === 0) {
    d.paragraph('Hakuna matangazo ya hadhara kwa wiki hii.', { italic: true, color: C.muted });
  } else {
    publicNotices.forEach((n) => d.noticeCard(n));
  }
  if (opts.finance) {
    d.sectionHeading('Muhtasari wa Fedha na Matoleo');
    const rows: Array<[string, string]> = [['Mapato ya Mwezi', tsh(opts.finance.monthIncome)]];
    if (opts.finance.projectTitle) {
      rows.push([`Mradi: ${opts.finance.projectTitle}`, `${opts.finance.projectPercent ?? 0}% imekamilika`]);
    }
    d.keyValueRows(rows);
  }
  d.sectionHeading('Njia Rasmi za Matoleo');
  const pc = CHURCH_PROFILE.paymentChannels;
  d.keyValueRows([
    ['M-Pesa Lipa Namba (Till)', `${pc.mpesaTill} - ${pc.mpesaName}`],
    [pc.bankName, `${pc.accountNumber} - ${pc.accountName}`]
  ]);
  d.signatures(SECRETARY, BISHOP);
  finish(d, opts.mode ?? 'open');
}

const INCOME_LABELS: Record<FinancialRecord['type'], string> = {
  tithe: 'Mafungu ya Kumi',
  offering: 'Sadaka za Ibada',
  project: 'Michango ya Miradi / Ujenzi',
  benevolence: 'Sadaka za Huruma',
  jumuiya: 'Sadaka za Jumuiya'
};

const EXPENSE_LABELS: Record<ChurchExpense['category'], string> = {
  Operations: 'Uendeshaji',
  Evangelism: 'Uinjilisti',
  Maintenance: 'Matengenezo',
  Benevolence: 'Huruma / Ustawi',
  Utilities: 'Huduma (Umeme, Maji)'
};

export async function generateFinanceStatementPdf(
  finances: FinancialRecord[],
  expenses: ChurchExpense[],
  projects: FinancialProject[],
  mode: PdfMode = 'open'
): Promise<void> {
  const d = await create({
    title: 'Taarifa ya Mapato na Matumizi ya Fedha',
    subtitle: 'Kamati ya Hazina na Fedha - Taarifa kwa Baraza la Wazee na Uongozi',
    office: 'Hazina ya Kanisa',
    refPrefix: 'FDH',
    fileName: 'Taarifa_ya_Fedha'
  });
  const income = finances.reduce((s, f) => s + f.amount, 0);
  const approved = expenses.filter((e) => e.isApproved);
  const spent = approved.reduce((s, e) => s + e.amount, 0);
  const pending = expenses.filter((e) => !e.isApproved).reduce((s, e) => s + e.amount, 0);

  d.summaryBoxes([
    { label: 'Jumla ya Mapato', value: tsh(income) },
    { label: 'Matumizi Yaliyoidhinishwa', value: tsh(spent) },
    { label: 'Salio', value: tsh(income - spent) }
  ]);

  d.sectionHeading('1. Muhtasari wa Mapato');
  const types = Object.keys(INCOME_LABELS) as Array<FinancialRecord['type']>;
  d.keyValueRows(
    [
      ...types.map((t): [string, string] => [INCOME_LABELS[t], tsh(finances.filter((f) => f.type === t).reduce((s, f) => s + f.amount, 0))]),
      ['JUMLA YA MAPATO', tsh(income)]
    ],
    { totalLast: true }
  );

  d.sectionHeading('2. Muhtasari wa Matumizi');
  const cats = Object.keys(EXPENSE_LABELS) as Array<ChurchExpense['category']>;
  d.keyValueRows(
    [
      ...cats.map((c): [string, string] => [EXPENSE_LABELS[c], tsh(approved.filter((e) => e.category === c).reduce((s, e) => s + e.amount, 0))]),
      ['Yanayosubiri Idhini', tsh(pending)],
      ['JUMLA YA MATUMIZI YALIYOIDHINISHWA', tsh(spent)]
    ],
    { totalLast: true }
  );

  d.sectionHeading('3. Daftari la Mapato');
  d.table(
    [
      { header: 'Tarehe', width: 13 },
      { header: 'Aina', width: 20 },
      { header: 'Mtoaji', width: 22 },
      { header: 'Njia', width: 13 },
      { header: 'Kumbukumbu', width: 16 },
      { header: 'Kiasi (Tsh)', width: 16, align: 'right' }
    ],
    [...finances]
      .sort((a, b) => (a.date < b.date ? 1 : -1))
      .map((f) => [
        f.date,
        INCOME_LABELS[f.type] ?? f.category,
        f.isAnonymous ? 'Bila Jina' : f.donorName || '-',
        f.paymentMethod,
        f.referenceNumber || '-',
        f.amount.toLocaleString('en-US')
      ])
  );

  d.sectionHeading('4. Daftari la Matumizi');
  d.table(
    [
      { header: 'Tarehe', width: 13 },
      { header: 'Maelezo', width: 32 },
      { header: 'Kundi', width: 16 },
      { header: 'Hali', width: 17 },
      { header: 'Kiasi (Tsh)', width: 16, align: 'right' }
    ],
    expenses.map((e) => [
      e.date,
      e.title,
      EXPENSE_LABELS[e.category] ?? e.category,
      e.isApproved ? `Imeidhinishwa (${e.approvedBy})` : 'Inasubiri',
      e.amount.toLocaleString('en-US')
    ])
  );

  if (projects.length) {
    d.sectionHeading('5. Miradi ya Maendeleo');
    d.table(
      [
        { header: 'Mradi', width: 34 },
        { header: 'Lengo (Tsh)', width: 18, align: 'right' },
        { header: 'Kilichopatikana', width: 18, align: 'right' },
        { header: 'Asilimia', width: 11, align: 'center' },
        { header: 'Hali', width: 13 }
      ],
      projects.map((p) => [
        p.title,
        p.targetAmount.toLocaleString('en-US'),
        p.currentAmount.toLocaleString('en-US'),
        p.targetAmount > 0 ? `${Math.round((p.currentAmount / p.targetAmount) * 100)}%` : '0%',
        p.status === 'active' ? 'Unaendelea' : p.status === 'completed' ? 'Umekamilika' : 'Mipango'
      ])
    );
  }

  d.signatures(TREASURER, BISHOP);
  finish(d, mode);
}
