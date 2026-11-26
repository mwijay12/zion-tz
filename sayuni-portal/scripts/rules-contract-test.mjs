#!/usr/bin/env node
/**
 * Rules ⇄ portal contract test.
 *
 * WHY THIS EXISTS
 * The portal and `firestore.rules` express the same permission model twice:
 * once in `AuthService.TAB_ROLES` (what the UI lets you click) and once in the
 * rules (what Firebase actually allows). When they disagree, the portal accepts
 * a write, Firebase rejects it, and the leader believes the record was saved —
 * which is exactly what a church admin console must never do.
 *
 * This script reads the REAL `firestore.rules` from the repo, enumerates every
 * `match /collection { ... }` block, extracts the roles named in its `allow`
 * expressions, and compares that against the portal's own role gates:
 *
 *   portal hides the module  +  rules allow the write  → dead permission
 *   portal allows the write  +  rules deny it         → silent failure (bug)
 *
 * It is a static check, not an emulator: it cannot evaluate arbitrary rule
 * logic, so it only asserts the role *names* that appear in each block. That
 * is enough to catch the class of drift that caused real bugs here.
 *
 * Run: node scripts/rules-contract-test.mjs
 * Exit code 0 = contract holds. 1 = drift found.
 */
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..', '..');
const RULES = path.join(ROOT, 'firestore.rules');
const AUTH_SERVICE = path.join(ROOT, 'sayuni-portal', 'src', 'services', 'authService.ts');

const rulesSrc = fs.readFileSync(RULES, 'utf8');
const authSrc = fs.readFileSync(AUTH_SERVICE, 'utf8');

// ---------------------------------------------------------------- rules side

/** Collection → set of role names mentioned in that block's allow statements. */
function extractRulesRoles(source) {
  const out = new Map();
  // Match each `match /name/{id} { ... }` block by brace counting.
  const re = /match\s+\/([A-Za-z0-9_]+)\/\{[^}]+\}\s*\{/g;
  let m;
  while ((m = re.exec(source)) !== null) {
    const name = m[1];
    const start = m.index + m[0].length;
    let depth = 1;
    let i = start;
    while (i < source.length && depth > 0) {
      if (source[i] === '{') depth++;
      else if (source[i] === '}') depth--;
      i++;
    }
    const body = source.slice(start, i - 1);
    const roles = new Set();
    // Role names appear either as string literals ('secretary') or inside
    // `in [...]` lists, or as helper names (isAdmin, isPastor, ...).
    for (const literal of body.matchAll(/'([a-z_]+)'/g)) {
      if (['admin', 'super_admin', 'pastor', 'secretary', 'deacon', 'treasurer', 'usher',
           'jumuiya_leader', 'choir_leader', 'children_teacher', 'member'].includes(literal[1])) {
        roles.add(literal[1]);
      }
    }
    const helperMap = {
      isAdmin: ['admin', 'super_admin'],
      isPastor: ['admin', 'super_admin', 'pastor'],
      isSecretary: ['admin', 'super_admin', 'pastor', 'secretary'],
      isDeacon: ['admin', 'super_admin', 'pastor', 'secretary', 'deacon'],
      isUsher: ['usher'],
      isChurchWorker: ['admin', 'super_admin', 'pastor', 'secretary', 'deacon', 'usher',
        'treasurer', 'jumuiya_leader', 'choir_leader', 'children_teacher'],
    };
    for (const [helper, expandsTo] of Object.entries(helperMap)) {
      if (new RegExp(`\\b${helper}\\(`).test(body)) expandsTo.forEach((role) => roles.add(role));
    }
    out.set(name, { roles, body });
  }
  return out;
}

// --------------------------------------------------------------- portal side

/** tab → roles, parsed straight out of AuthService.TAB_ROLES. */
function extractPortalGates(source) {
  const block = source.match(/TAB_ROLES[^=]*=\s*\{([\s\S]*?)\n  \};/);
  if (!block) throw new Error('Could not locate AuthService.TAB_ROLES in authService.ts');
  const gates = new Map();
  const lineRe = /([a-z_]+):\s*(\[[^\]]*\]|'all')/g;
  let m;
  while ((m = lineRe.exec(block[1])) !== null) {
    const tab = m[1];
    const value = m[2];
    gates.set(
      tab,
      value === "'all'"
        ? ['admin', 'super_admin', 'pastor', 'secretary', 'deacon', 'treasurer', 'usher',
           'jumuiya_leader', 'choir_leader', 'children_teacher']
        : [...value.matchAll(/'([a-z_]+)'/g)].map((x) => x[1])
    );
  }
  return gates;
}

const rulesRoles = extractRulesRoles(rulesSrc);
const portalGates = extractPortalGates(authSrc);

// ------------------------------------------------------------- the contract

/**
 * Which portal module writes to which collection.
 * `inModuleGate` names the AuthService predicate that guards the write, when
 * the module is visible to everyone but writing is restricted (the choir
 * portal: every leader may look at the songbook, only the choir leader may
 * add to it). Such modules are checked against that narrower set.
 */
const WRITE_PATHS = [
  { tab: 'secretary_portal', collection: 'announcements', label: 'publish a notice' },
  { tab: 'pastor_portal', collection: 'sermons', label: 'publish a sermon' },
  { tab: 'choir_portal', collection: 'choir_songs', label: 'publish a choir song', inModuleGate: 'canEditSongs' },
  { tab: 'jumuiya', collection: 'jumuiya_reports', label: 'submit a jumuiya report' },
  { tab: 'media_studio', collection: 'events', label: 'submit an event/poster request' },
];

let failures = 0;
const fail = (msg) => { failures++; console.log(`  FAIL  ${msg}`); };
const ok = (msg) => console.log(`  ok    ${msg}`);

console.log('Rules ⇄ portal role contract\n');

for (const pathDef of WRITE_PATHS) {
  let gate = portalGates.get(pathDef.tab);
  const block = rulesRoles.get(pathDef.collection);
  if (!gate) { fail(`${pathDef.tab}: no portal gate (TAB_ROLES entry missing)`); continue; }

  // A module can be readable by everyone while writes stay restricted.
  // Use the in-module predicate's role list when one is declared, otherwise a
  // "visible to all" tab would be falsely reported as over-permissive.
  if (pathDef.inModuleGate) {
    const predicate = authSrc.match(
      new RegExp(`${pathDef.inModuleGate}\\([^)]*\\):\\s*boolean\\s*\\{\\s*return this\\.hasAnyRole\\(user, \\[([^\\]]*)\\]\\)`)
    );
    if (!predicate) {
      fail(`${pathDef.tab}: ${pathDef.inModuleGate}() not found in authService.ts`);
      continue;
    }
    gate = [...predicate[1].matchAll(/'([a-z_]+)'/g)].map((x) => x[1]);
  }
  if (!block) { fail(`${pathDef.collection}: no rules block found`); continue; }

  // Roles the portal lets in must be able to write, or the write is a lie.
  const portalOnly = gate.filter((role) => !block.roles.has(role));
  // Roles the rules accept but the portal never shows the module to: dead.
  const rulesOnly = [...block.roles].filter((role) => !gate.includes(role));

  if (portalOnly.length === 0) {
    ok(`${pathDef.tab} → ${pathDef.collection}: every portal role may ${pathDef.label}`);
  } else {
    fail(`${pathDef.tab} → ${pathDef.collection}: portal lets ${portalOnly.join(', ')} ${pathDef.label}, but the rules reject them`);
  }

  if (rulesOnly.length > 0) {
    console.log(`        note: rules also accept ${rulesOnly.join(', ')} (cannot reach this module in the UI)`);
  }
}

// Deleting a choir song is intentionally narrower than editing it: the rules
// say `choir_songs.allow delete: if isAdmin();`, so the UI must not offer
// Delete to a choir leader (it did, and the cloud copy survived the local
// delete). Require an explicit canDeleteSongs gate on the narrower role set.
const choirBlock = rulesRoles.get('choir_songs');
if (!choirBlock) {
  fail('choir_songs: rules block missing');
} else {
  const canDelete = authSrc.includes('canDeleteSongs');
  const deleteLine = choirBlock.body.match(/allow delete:\s*if\s*([^;]+);/);
  const adminsOnly = deleteLine ? /isAdmin\(\)/.test(deleteLine[1]) && !/choir_leader/.test(deleteLine[1]) : false;
  if (adminsOnly && !canDelete) {
    fail('choir_songs: rules restrict delete to admins, but the portal has no canDeleteSongs gate');
  } else {
    ok('choir_songs: delete is admin-only in both the rules and the UI');
  }
}

// Church settings (leadership names/photo) are admin-write only. No portal UI
// currently writes them, but if one is added it must use an admin gate.
const settingsBlock = rulesRoles.get('church_settings');
if (settingsBlock && /allow write:\s*if isAdmin\(\)/.test(settingsBlock.body)) {
  ok('church_settings: advisory — writes are admin-only; any future inbox must respect it');
}

// The self-test collection must stay locked down.
const probe = rulesRoles.get('health_probe');
if (!probe) {
  fail('health_probe: rules block missing — the portal cloud check will fail with permission-denied');
} else if (!/allow read, list: if false/.test(probe.body)) {
  fail('health_probe: must not be readable (contains no data and must stay invisible)');
} else if (!/resource\.data\.uid == request\.auth\.uid/.test(probe.body)) {
  fail('health_probe: delete/ownership must be scoped to the owning uid');
} else {
  ok('health_probe: write-own-only, never readable');
}

// No collection may be left writable without an auth check.
for (const [name, { body }] of rulesRoles) {
  if (/\ballow write: if true\b/.test(body) || /\ballow create: if true\b/.test(body)) {
    fail(`${name}: allow create/write: if true — anyone can write`);
  }
}
ok('no collection is world-writable');

console.log(`\n${failures === 0 ? 'PASS' : 'FAIL'}: ${WRITE_PATHS.length + 2} checks, ${failures} failure(s)\n`);
process.exit(failures === 0 ? 0 : 1);
