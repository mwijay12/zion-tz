#!/usr/bin/env node
/**
 * Portal ⇄ Flutter app data contract test.
 *
 * WHY THIS EXISTS
 * ---------------
 * The portal and the APK are two codebases writing to and reading from the
 * same Firestore collections with no shared schema. There is no compiler and
 * no type generator between them, so every field name is a handshake done by
 * memory. When the handshake breaks the failure is silent and one-sided:
 *
 *   - the portal writes `body`, the app reads `content` → the notice arrives
 *     on the phone with a blank body;
 *   - the portal writes `type: 'urgent'`, the app only looks at `isUrgent`
 *     → an urgent announcement lands as a quiet normal one;
 *   - the app writes `prayer_requests`, the portal reads localStorage
 *     → the pastor never sees the prayer a member submitted.
 *
 * None of those throw. That is why this is a *contract* test: it reads the
 * real Dart sources and the real TypeScript services and asserts that the
 * field names on both sides of each collection still match.
 *
 * It is deliberately written against source text rather than a schema file, so
 * it keeps working without anyone maintaining a third copy of the truth.
 *
 * Run: node scripts/data-contract-test.mjs
 * Exit code 0 = contract holds. 1 = drift found.
 */
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..', '..');
const PORTAL = path.join(ROOT, 'sayuni-portal', 'src');
const APP = path.join(ROOT, 'sayuni', 'lib');

const read = (p) => {
  if (!fs.existsSync(p)) throw new Error(`Missing file: ${p}`);
  return fs.readFileSync(p, 'utf8');
};

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

function assertIncludes(haystack, needle, message) {
  assert(haystack.includes(needle), message);
}

// ---------------------------------------------------------------------------
// Sources
// ---------------------------------------------------------------------------
const portalAnnouncements = read(path.join(PORTAL, 'services', 'firebaseChurchService.ts'));
const appSync = read(path.join(APP, 'core', 'services', 'church_sync_service.dart'));
const appModel = read(path.join(APP, 'features', 'notifications', 'models', 'church_announcement.dart'));
const appNotifService = read(
  path.join(APP, 'features', 'notifications', 'services', 'notifications_data_service.dart')
);
const appEventRequest = read(
  path.join(APP, 'features', 'notifications', 'presentation', 'event_request_screen.dart')
);
const rules = read(path.join(ROOT, 'firestore.rules'));

const blockOf = (source, header, endToken = '}') => {
  const start = source.indexOf(header);
  assert(start !== -1, `Could not find "${header}"`);
  const end = source.indexOf(endToken, start);
  return source.slice(start, end === -1 ? undefined : end);
};

// Extracts the keys of an object literal written as `key: value,` up to `stop`.
function literalKeys(source, startMarker, stopMarker) {
  const start = source.indexOf(startMarker);
  assert(start !== -1, `Could not find write to "${startMarker}"`);
  const stop = source.indexOf(stopMarker, start);
  assert(stop !== -1, `Could not find "${stopMarker}" after "${startMarker}"`);
  const body = source.slice(start, stop);
  return [...body.matchAll(/^\s*['"]?([A-Za-z_][A-Za-z0-9_]*)['"]?\s*:/gm)].map((m) => m[1]);
}

// ---------------------------------------------------------------------------
// 1. Announcements: the fields the portal writes and the app reads must overlap.
// ---------------------------------------------------------------------------
check('announcements: portal write fields the app understands', () => {
  const written = new Set(
    literalKeys(portalAnnouncements, 'addDoc(collection(db, "announcements")', 'createdAt: serverTimestamp()')
  );
  // The app must be able to render a notice using the fields actually written.
  const appReads = ['body', 'content', 'title', 'type', 'category', 'branch', 'targetAudience'];
  const missing = appReads.filter((field) => !written.has(field));
  assert(missing.length === 0, `portal no longer writes: ${missing.join(', ')}`);

  // Every field the app *prefers* must be produced by at least one write path.
  for (const field of ['eventDate', 'eventTime', 'venue']) {
    assert(
      written.has(field) || portalAnnouncements.includes(`${field}: announcement.${field}`),
      `portal does not write "${field}" but the app shows it as the notice date/place`
    );
  }
  return `${written.size} fields written, all app-critical fields present`;
});

check('announcements: app falls back across body/content/summary', () => {
  // This is the concrete bug that shipped: `??` stopped at an empty string.
  assertIncludes(
    appSync,
    '_firstNonEmpty',
    'church_sync_service.dart must use _firstNonEmpty so a blank body cannot win over a populated content'
  );
  assertIncludes(
    appSync,
    "['body', 'content', 'summary']",
    'announcement body must be resolved from body → content → summary'
  );
  return 'blank-field resolution present';
});

check('announcements: urgency survives the trip', () => {
  // Rules only accept these three values.
  assertIncludes(rules, "'normal', 'urgent', 'bereavement'", 'rules must constrain announcement type');
  assertIncludes(
    portalAnnouncements,
    "priority: announcement.type === 'urgent'",
    'portal must derive priority from the type so both sides agree on urgency'
  );
  assertIncludes(
    appSync,
    "rawType == 'urgent'",
    'app must treat type == "urgent" as urgent, not only the unused isUrgent flag'
  );
  assertIncludes(
    appModel,
    "json['type'] == 'urgent'",
    'ChurchAnnouncement.isHighPriority must honour type == "urgent"'
  );
  return 'type/priority agree on both sides';
});

check('announcements: edits and deletions reach the device', () => {
  assertIncludes(
    appSync,
    '_noticeFingerprint',
    'the app must key de-duplication on content, or edits to a notice are dropped forever'
  );
  assertIncludes(
    appSync,
    'pruneMissingPortalNotices',
    'the app must prune notices the portal deleted'
  );
  assertIncludes(
    appNotifService,
    'pruneMissingPortalNotices',
    'NotificationsDataService must implement pruning'
  );
  assertIncludes(
    appNotifService,
    '_syncedNoticesKey',
    'pruning must only touch portal-delivered notices, never the local seed set'
  );
  return 'edit + delete paths covered';
});

// ---------------------------------------------------------------------------
// 2. Events: app writes, portal lists. Field names must line up.
// ---------------------------------------------------------------------------
check('events: app-submitted event satisfies isValidEvent', () => {
  // Dart object literals quote their keys, hence "'createdAt'".
  const written = literalKeys(appEventRequest, "collection('events').add(", "'createdAt'");
  assert(written.includes('title'), 'app must write a title (rules require it)');
  assert(written.includes('description'), 'app must write a description (rules require it)');
  assert(written.includes('posterStatus'), 'app must write posterStatus so the Poster Desk can queue it');
  assertIncludes(rules, 'isValidEvent', 'rules must validate events');
  return `app writes ${written.length} event fields`;
});

check('events: portal reads the fields the app writes', () => {
  const readFields = ['title', 'description', 'category', 'eventDate', 'eventTime', 'venue'];
  for (const field of readFields) {
    assertIncludes(portalAnnouncements, `${field}: event.${field}`, `publishEvent must carry "${field}"`);
  }
  assertIncludes(
    portalAnnouncements,
    'subscribeToEvents',
    'portal must subscribe to events so app-submitted events appear'
  );
  return 'portal ⇄ events agree';
});

// ---------------------------------------------------------------------------
// 3. Prayer requests: the app writes to Firestore; the portal must read it.
// ---------------------------------------------------------------------------
check('prayer_requests: portal does not rely on localStorage only', () => {
  assertIncludes(appSync, "collection('prayer_requests')", 'app must write prayer requests to Firestore');
  assertIncludes(rules, 'isValidPrayerRequest', 'rules must validate prayer requests');
  // The surfaced bug: the pastor portal fed the War Room from localStorage.
  assertIncludes(
    portalAnnouncements,
    'subscribeToPrayerRequests',
    'portal needs a Firestore subscription for prayer_requests — localStorage can never see a phone'
  );
  return 'portal has a cloud read path for prayers';
});

check('prayer_requests: pastor view is fed from the cloud feed', () => {
  const pastors = read(path.join(PORTAL, 'components', 'PastorsPortal.tsx'));
  assertIncludes(
    pastors,
    'subscribeToPrayerRequests',
    'PastorsPortal must consume the Firestore prayer feed, not only churchSync.getPrayers()'
  );
  return 'PastorsPortal wired to Firestore';
});

// ---------------------------------------------------------------------------
// 4. Sermons: portal and app both write; both must produce createdAt.
// ---------------------------------------------------------------------------
check('sermons: both writers set createdAt (orderBy silently drops documents without it)', () => {
  const portalSermon = blockOf(portalAnnouncements, 'static async publishSermon', 'return docRef.id;');
  assertIncludes(portalSermon, 'createdAt: serverTimestamp()', 'portal publishSermon must write createdAt');
  assertIncludes(appSync, "'createdAt': FieldValue.serverTimestamp()", 'app syncNewSermon must write createdAt');
  return 'both writers stamp createdAt';
});

check('sermons: rules requirement is satisfiable by the portal', () => {
  assertIncludes(
    rules,
    'isValidSermon',
    'rules must validate sermons so a bad write is rejected loudly'
  );
  const portalSermon = blockOf(portalAnnouncements, 'static async publishSermon', 'return docRef.id;');
  assertIncludes(portalSermon, 'mediaUrl:', 'portal must write mediaUrl (rules require it) or a media_url alias');
  return 'sermon writes satisfy the rules shape';
});

// ---------------------------------------------------------------------------
// 5. Leadership settings: portal writes, app subscribes to the same doc id.
// ---------------------------------------------------------------------------
check('church_settings/leadership: both sides use the same document id', () => {
  assertIncludes(
    portalAnnouncements,
    'doc(db, "church_settings", "leadership")',
    'portal must write the leadership document at church_settings/leadership'
  );
  assertIncludes(
    appSync,
    ".collection('church_settings')",
    'app must subscribe to church_settings'
  );
  assertIncludes(appSync, ".doc('leadership')", 'app must read the same leadership document id');
  const keys = ['bishopName', 'coLeaderName', 'assistantPastor', 'assistantPhone', 'leadershipPhotoUrl'];
  for (const key of keys) {
    assertIncludes(portalAnnouncements, key, `portal leadership write must include "${key}"`);
  }
  return 'leadership document contract holds';
});

// ---------------------------------------------------------------------------
// 6. Ordering: orderBy on a missing field hides documents. Both sides must
//    order by a field the writer actually sets.
// ---------------------------------------------------------------------------
check('ordering: every orderBy field is written by some producer', () => {
  const orderFields = [...portalAnnouncements.matchAll(/orderBy\("([A-Za-z_]+)"/g)].map((m) => m[1]);
  for (const field of new Set(orderFields)) {
    const produced =
      portalAnnouncements.includes(`${field}: serverTimestamp()`) ||
      portalAnnouncements.includes(`${field}:`) ||
      appSync.includes(`'${field}':`);
    assert(produced, `portal orders by "${field}" but nothing writes it`);
  }
  return `${new Set(orderFields).size} ordering fields verified`;
});

// ---------------------------------------------------------------------------
// 7. The bell must be fed by real records, not by a hardcoded seed.
// ---------------------------------------------------------------------------
check('portal notifications: no hardcoded seed notification feed', () => {
  const header = read(path.join(PORTAL, 'components', 'Header.tsx'));
  assert(
    !/INITIAL_NOTIFICATIONS/.test(header),
    'Header.tsx must not ship a hardcoded notification list — the bell has to reflect Firestore'
  );
  assertIncludes(header, 'buildNotifications', 'Header must build the feed via notificationCenter');
  assertIncludes(header, 'saveReadState', 'read state must persist across reloads');
  assertIncludes(header, 'portal-notif-empty', 'the bell needs an honest empty state');
  return 'bell is derived from Firestore';
});

// ---------------------------------------------------------------------------
// 8. PDF export must be vector text, never a screenshot of the DOM.
// ---------------------------------------------------------------------------
check('pdf: exports are vector documents, not screen captures', () => {
  const pdf = read(path.join(PORTAL, 'services', 'officialPdfService.ts'));
  const cert = read(path.join(PORTAL, 'services', 'certificatePdfService.ts'));
  for (const [name, source] of [['officialPdfService', pdf], ['certificatePdfService', cert]]) {
    assert(!/html2canvas/.test(source), `${name} must not rasterise the DOM with html2canvas`);
    assert(!/toDataURL\(\s*\)/.test(source), `${name} must not screenshot a canvas`);
    assert(/doc\.text\(/.test(source), `${name} must draw real text`);
  }
  const pkg = JSON.parse(read(path.join(ROOT, 'sayuni-portal', 'package.json')));
  const deps = { ...pkg.dependencies, ...pkg.devDependencies };
  assert(!('html2canvas' in deps), 'html2canvas must not be a dependency');
  assert('jspdf' in deps, 'jspdf must stay a dependency');
  return 'both PDF services draw glyphs, not pixels';
});

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------
const pad = Math.max(...checks.map((c) => c.name.length));
console.log('\nPortal ⇄ App data contract\n');
for (const c of checks) {
  console.log(`  ${c.ok ? 'PASS' : 'FAIL'}  ${c.name.padEnd(pad)}  ${c.detail}`);
}
console.log(`\n${checks.length - failures.length}/${checks.length} checks passed\n`);

if (failures.length) {
  console.error(`Drift found in: ${failures.join(', ')}\n`);
  process.exit(1);
}
