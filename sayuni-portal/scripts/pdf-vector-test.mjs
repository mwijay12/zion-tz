#!/usr/bin/env node
/**
 * Proof that the portal's PDF exports are real vector documents.
 *
 * WHY THIS EXISTS
 * ---------------
 * "PDF inatoka vizuri sio screenshot ya view" is a question that cannot be
 * answered by looking at the code — a screenshot pipeline and a vector
 * pipeline look identical from the outside. The only honest check is to
 * generate a PDF and inspect the bytes.
 *
 * This script bundles the REAL `officialPdfService.ts` and
 * `certificatePdfService.ts` with the repo's own bundler, runs them in a
 * minimal DOM shim, captures the jsPDF output, and then counts what is inside
 * the file:
 *
 *   /Subtype /Image   → raster images. A screenshot export is mostly this.
 *   Tj / TJ operators → glyph-show operators. Vector text export is full of them.
 *   /Type /Font       → embedded fonts.
 *
 * Two logos are added to every official document, so a small, constant number
 * of images is expected. What must NOT happen is the page itself arriving as
 * an image.
 *
 * Run: node scripts/pdf-vector-test.mjs
 * Exit code 0 = exports are vector. 1 = something rasterises the page.
 */
import zlib from 'node:zlib';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PORTAL = path.resolve(HERE, '..');
const SRC = path.join(PORTAL, 'src', 'services');

const failures = [];
const checks = [];

function check(name, fn) {
  try {
    const detail = fn();
    checks.push({ name, ok: true, detail });
  } catch (error) {
    checks.push({ name, ok: false, detail: error.message });
    failures.push(name);
  }
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

// ---------------------------------------------------------------------------
// 1. Build a tiny entry point that generates every document type.
// ---------------------------------------------------------------------------
// Built inside the project so bare imports like `jspdf` and `firebase/app`
// resolve against sayuni-portal/node_modules, then removed afterwards.
const workDir = fs.mkdtempSync(path.join(PORTAL, '.pdf-test-'));
const entry = path.join(workDir, 'entry.ts');
const bundle = path.join(workDir, 'bundle.mjs');

fs.writeFileSync(entry, `
import { jsPDF } from 'jspdf';
import {
  generateBulletinPdf,
  generateVisitorsReportPdf,
  generateGroupsReportPdf,
  generateFinanceStatementPdf,
} from ${JSON.stringify(path.join(SRC, 'officialPdfService.ts'))};
import { INITIAL_PROJECTS, INITIAL_FINANCES, INITIAL_EXPENSES } from ${JSON.stringify(path.join(PORTAL, 'src', 'data', 'mockData.ts'))};
import { createCertificatePdf } from ${JSON.stringify(path.join(SRC, 'certificatePdfService.ts'))};

(globalThis as any).__runPdfSuite = async () => {
  const out: Record<string, Buffer> = {};
  const API = (jsPDF as any).API;
  const originalSave = API.save;

  const capture = (name: string, run: () => Promise<void> | void) => async () => {
    API.save = function (this: any) {
      out[name] = Buffer.from(this.output('arraybuffer'));
      return this;
    };
    try { await run(); } finally { API.save = originalSave; }
  };

  const notices = [
    { id: 'n1', title: 'Ibada ya Shukrani', content: 'Ibada kuu ya shukrani itafanyika Jumapili saa 4 asubuhi.', category: 'Ibada', date: '2026-11-29', isUrgent: true },
    { id: 'n2', title: 'Mazoezi ya Kwaya', content: 'Kwaya ya Galilaya itafanya mazoezi Ijumaa saa 11 jioni.', category: 'Kwaya', date: '2026-11-27' },
  ];
  const visitors = [
    { id: 'v1', fullName: 'Neema Joseph', phone: '+255 754 111 222', residence: 'Mbagala', firstVisitDate: '2026-11-23', assignedJumuiya: 'Chamazi', followUpStatus: 'Mpya', prayerRequest: 'Uponyaji wa mama' },
  ];
  const reports = [
    { id: 'r1', jumuiyaName: 'Chamazi', leaderName: 'Mzee Joseph', attendanceMen: 12, attendanceWomen: 18, attendanceYouth: 9, attendanceChildren: 7, offeringAmount: 85000, topicTaught: 'Imani', sickOrWelfareNeeds: '', prayerRequests: '' },
  ];
  // Real shapes from the portal's own seed data — a hand-written fixture would
  // drift and stop proving anything about the shipping document.
  const finances = INITIAL_FINANCES;
  const expenses = INITIAL_EXPENSES;
  const projects = INITIAL_PROJECTS;

  await capture('bulletin', () => generateBulletinPdf(notices as any, { mode: 'download' }))();
  await capture('visitors', () => generateVisitorsReportPdf(visitors as any, { mode: 'download' }))();
  await capture('groups', () => generateGroupsReportPdf(reports as any, { mode: 'download' }))();
  await capture('finance', () => generateFinanceStatementPdf(finances as any, expenses as any, projects as any, 'download'))();
  await capture('certificate', async () => {
    const doc = await createCertificatePdf({
      type: 'baptism',
      recipientName: 'Neema Joseph',
      eventDate: '2026-11-23',
      scripture: 'Mathayo 28:19',
      serialNumber: 'ZFC-2026-0001',
      language: 'sw',
      variant: 'classic',
    } as any);
    doc.save('certificate.pdf');
  })();

  return out;
};
`);

// ---------------------------------------------------------------------------
// 2. Bundle with the repo's own bundler (vite → rolldown).
// ---------------------------------------------------------------------------
const rolldownBin = path.join(PORTAL, 'node_modules', '.bin', 'rolldown');
assert(fs.existsSync(rolldownBin), 'rolldown is not installed; run npm ci in sayuni-portal');

execFileSync(
  rolldownBin,
  [entry, '--format', 'esm', '--file', bundle, '--inline-dynamic-imports'],
  { cwd: PORTAL, stdio: 'pipe' }
);

// ---------------------------------------------------------------------------
// 3. Minimal DOM so the services can resolve a logo and trigger a download.
//
// Deliberately hand-rolled rather than jsdom: this script must run on a plain
// `npm ci` with no extra devDependency, and the only DOM surface the PDF
// services touch is createElement/appendChild/anchor.click.
// ---------------------------------------------------------------------------
const noop = () => {};
const makeElement = () => ({
  style: {},
  setAttribute: noop,
  getAttribute: () => null,
  appendChild: noop,
  removeChild: noop,
  addEventListener: noop,
  removeEventListener: noop,
  click: noop,
  focus: noop,
  href: '',
  download: '',
  children: [],
  childNodes: [],
  classList: { add: noop, remove: noop, contains: () => false },
});
globalThis.window = globalThis;
globalThis.self = globalThis;
globalThis.document = {
  createElement: makeElement,
  createElementNS: makeElement,
  documentElement: makeElement(),
  body: makeElement(),
  head: makeElement(),
  querySelector: () => null,
  querySelectorAll: () => [],
  addEventListener: noop,
  removeEventListener: noop,
};
Object.defineProperty(globalThis, 'navigator', {
  value: { userAgent: 'node', platform: 'node' },
  configurable: true,
  writable: true,
});
Object.defineProperty(globalThis, 'location', {
  value: { href: 'https://sayuni-portal.vercel.app/', origin: 'https://sayuni-portal.vercel.app' },
  configurable: true,
  writable: true,
});
globalThis.Blob = class { constructor(parts) { this.parts = parts; } };
globalThis.FileReader = class {
  readAsDataURL() { if (this.onerror) this.onerror(new Error('no file')); }
};
globalThis.URL.createObjectURL = () => 'blob:pdf';
globalThis.URL.revokeObjectURL = noop;
globalThis.atob = (value) => Buffer.from(value, 'base64').toString('binary');
globalThis.btoa = (value) => Buffer.from(value, 'binary').toString('base64');
// No network in CI: the logo fetch must degrade to "no logo", not hang.
globalThis.fetch = async () => ({ ok: false, status: 404, blob: async () => null });

await import(bundle);
const generated = await globalThis.__runPdfSuite();

// ---------------------------------------------------------------------------
// 4. Inspect the bytes.
// ---------------------------------------------------------------------------
if (process.env.SAYUNI_PDF_DUMP) {
  for (const [name, buffer] of Object.entries(generated)) {
    fs.writeFileSync(path.join(process.env.SAYUNI_PDF_DUMP, `${name}.pdf`), buffer);
  }
}

const analyse = (buffer) => {
  let text = buffer.toString('latin1');
  // `compress: true` stores content streams deflated, so glyph operators are
  // invisible to a raw scan. Inflate every stream we can before counting,
  // otherwise a vector document would fail this check for the wrong reason.
  for (const match of text.matchAll(/stream\r?\n/g)) {
    const start = match.index + match[0].length;
    const end = text.indexOf('endstream', start);
    if (end === -1) continue;
    try {
      text += '\n' + zlib.inflateSync(buffer.subarray(start, end)).toString('latin1');
    } catch {
      // Not a deflate stream (font, image, metadata) — skip it.
    }
  }
  return {
    bytes: buffer.length,
    pages: (text.match(/\/Type\s*\/Page[^s]/g) || []).length,
    images: (text.match(/\/Subtype\s*\/Image/g) || []).length,
    jpeg: (text.match(/DCTDecode/g) || []).length,
    textOps: (text.match(/\bTj\b|\bTJ\b/g) || []).length,
    fonts: (text.match(/\/Type\s*\/Font/g) || []).length,
  };
};

console.log('\nPDF vector export check\n');

for (const [name, buffer] of Object.entries(generated)) {
  const stats = analyse(buffer);

  check(`${name}: is a real PDF`, () => {
    assert(buffer.subarray(0, 5).toString() === '%PDF-', 'missing %PDF- header');
    assert(stats.bytes > 2000, `suspiciously small (${stats.bytes} bytes)`);
    return `${stats.bytes} bytes, ${stats.pages} page(s)`;
  });

  check(`${name}: text is selectable vector glyphs`, () => {
    assert(stats.textOps >= 10, `only ${stats.textOps} text-show operators — text may be an image`);
    assert(stats.fonts >= 1, 'no font objects embedded');
    return `${stats.textOps} Tj/TJ ops, ${stats.fonts} font objects`;
  });

  check(`${name}: page is not a screenshot`, () => {
    // Two logos may be embedded; a full-page raster would be hundreds of KB
    // plus DCTDecode/FlateDecode image streams on almost every page.
    assert(stats.images <= 4, `${stats.images} embedded images — the page looks rasterised`);
    assert(
      stats.images === 0 || stats.bytes / Math.max(stats.pages, 1) < 200_000,
      'image payload per page is large enough to be a screenshot'
    );
    return `${stats.images} embedded image(s), ${stats.jpeg} JPEG stream(s)`;
  });
}

// A full-page screenshot of an A4 page at print resolution is typically
// >200 KB per page. Vector text documents of this size stay well under that.
const total = Object.values(generated).reduce((sum, b) => sum + b.length, 0);
check('overall: documents stay in vector byte range', () => {
  const pages = Object.values(generated).reduce((sum, b) => sum + analyse(b).pages, 0);
  assert(pages > 0, 'no pages generated');
  assert(total / pages < 200_000, `${Math.round(total / pages)} bytes/page suggests rasterised output`);
  return `${Object.keys(generated).length} documents, ${pages} pages, ${Math.round(total / pages)} bytes/page`;
});

const pad = Math.max(...checks.map((c) => c.name.length));
for (const c of checks) {
  console.log(`  ${c.ok ? 'PASS' : 'FAIL'}  ${c.name.padEnd(pad)}  ${c.detail}`);
}
console.log(`\n${checks.length - failures.length}/${checks.length} checks passed\n`);

fs.rmSync(workDir, { recursive: true, force: true });

if (failures.length) {
  console.error(`Vector export broken in: ${failures.join(', ')}\n`);
  process.exit(1);
}
