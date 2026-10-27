'use strict';

/**
 * Hekalu la Sayuni — Zion Jerusalem Church (Mbagala)
 * Server-side authority for church roles.
 * ---------------------------------------------------------------------------
 * WHY THIS FILE EXISTS
 * `firestore.rules` decides authorisation from `request.auth.token.role`, and
 * that value can only be produced by `admin.auth().setCustomUserClaims()`.
 * Nothing a client writes (SharedPreferences, `profiles/<uid>.role`, a
 * `role` field in a POST body) can ever create a real permission. This file is
 * therefore the only door to privilege in the whole system.
 *
 * RULES OF THE HOUSE
 *  1. Every privileged mutation happens here, never in the app.
 *  2. Every call is authenticated AND re-checked against the caller's own
 *     verified claims (`request.auth.token` — signed by Firebase Auth).
 *  3. Every call leaves an append-only row in `audit_logs` (who, whom, what,
 *     before/after). `firestore.rules` makes that collection read-only for
 *     clients, so the trail cannot be rewritten.
 *  4. Claims are denormalised into `members/<uid>` for reporting only.
 *     Authorisation never reads that document.
 *
 * The role strings below MUST stay identical to `ChurchRole.wireName` in
 * sayuni/lib/core/services/church_role_policy.dart and to the strings used in
 * firestore.rules.
 */

const admin = require('firebase-admin');
const { setGlobalOptions } = require('firebase-functions/v2');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

admin.initializeApp();
const db = admin.firestore();

/**
 * Region of the callable endpoints. Joburg (`africa-south1`) is the shortest
 * round trip from Dar es Salaam. If your project/plan rejects it, set
 * ZION_REGION=us-central1 (or asia-southeast1) in `functions/.env` and
 * redeploy — the Flutter client reads the same value from
 * `ChurchRoleGrantService.region`.
 */
const REGION = process.env.ZION_REGION || 'africa-south1';

setGlobalOptions({
  region: REGION,
  timeoutSeconds: 60,
  memory: '256MiB',
});

// --- Role vocabulary (mirror of church_role_policy.dart) --------------------

const ROLES = [
  'guest',
  'member',
  'jumuiya_leader',
  'choir_leader',
  'children_teacher',
  'treasurer',
  'deacon',
  'secretary',
  'pastor',
  'admin',
  'super_admin',
];

/** Roles that may hand out roles at all. */
const ROOT_ROLES = ['admin', 'super_admin'];
/** Roles that may only be handed out by an account already holding them. */
const SENSITIVE_GRANTS = ['admin', 'super_admin'];

/** Ranks used only for the "you cannot demote someone above yourself" guard. */
const RANK = ROLES.reduce((acc, role, i) => ({ ...acc, [role]: i }), {});

// --- Small helpers ---------------------------------------------------------

function callerUid(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError('unauthenticated', 'Lazwa uwe umeingia (sign in) kwanza.');
  }
  return request.auth.uid;
}

function callerRole(request) {
  const token = (request.auth && request.auth.token) || {};
  return typeof token.role === 'string' ? token.role : null;
}

function requireRoot(request) {
  const uid = callerUid(request);
  const role = callerRole(request);
  if (!ROOT_ROLES.includes(role)) {
    throw new HttpsError(
      'permission-denied',
      'Mamlaka huyo ana role ya "' + (role || 'hakuna') + '". ' +
        'Role zinaweza kupewa na admin/super_admin pekee — role ya kweli hutoka ' +
        'kwenye Firebase Auth claims, si kifaa.',
    );
  }
  return { uid, role };
}

function pickTarget(data) {
  const uid = typeof data.targetUid === 'string' ? data.targetUid.trim() : '';
  const email =
    typeof data.targetEmail === 'string' ? data.targetEmail.trim().toLowerCase() : '';
  if (uid && email) {
    throw new HttpsError('invalid-argument', 'Tumia targetUid AU targetEmail, si vyote viwili.');
  }
  if (!uid && !email) {
    throw new HttpsError(
      'invalid-argument',
      'Kamata moja inahitajika: targetUid au targetEmail.',
    );
  }
  return { uid, email };
}

function validateRole(rawRole) {
  const role = typeof rawRole === 'string' ? rawRole.trim().toLowerCase() : '';
  if (!ROLES.includes(role)) {
    throw new HttpsError(
      'invalid-argument',
      'Role "' + (rawRole || '') + '" haijulikani. Halali: ' + ROLES.join(', ') + '.',
    );
  }
  return role;
}

function cleanString(raw, max) {
  if (typeof raw !== 'string') return null;
  const v = raw.trim();
  if (!v) return null;
  return v.slice(0, max);
}

async function resolveUser(target) {
  try {
    const rec = target.uid
      ? await admin.auth().getUser(target.uid)
      : await admin.auth().getUserByEmail(target.email);
    if (rec.disabled) {
      throw new HttpsError('failed-precondition', 'Akaunti hiyo imezimbwa (disabled).');
    }
    return rec;
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    if (err && err.code === 'auth/user-not-found') {
      throw new HttpsError(
        'not-found',
        'Hakuna akaunti ya Firebase kwa ' + (target.email || target.uid) + '. ' +
          'Mtumiaji anaanza kujiandikisha, kisha upe role.',
      );
    }
    throw new HttpsError('internal', 'Imeshindikana kusoma akaunti: ' + (err.message || err));
  }
}

/**
 * The one place claims are written. Returns the claims actually applied.
 */
async function applyClaims(uid, claims) {
  await admin.auth().setCustomUserClaims(uid, claims);
  return claims;
}

function claimPayload(role, branch, memberId) {
  const claims = { role };
  if (branch) claims.branch = branch;
  if (memberId) claims.memberId = memberId;
  return claims;
}

async function writeMemberRecord(userRec, claims, actorUid, reason) {
  const ref = db.collection('members').doc(userRec.uid);
  const before = (await ref.get()).data() || {};
  await ref.set(
    {
      uid: userRec.uid,
      email: userRec.email || null,
      displayName: userRec.displayName || null,
      phoneNumber: userRec.phoneNumber || null,
      role: claims.role,
      branch: claims.branch || before.branch || null,
      memberId: claims.memberId || before.memberId || null,
      grantedBy: actorUid,
      grantReason: reason || before.grantReason || null,
      roleUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: before.createdAt || admin.firestore.FieldValue.serverTimestamp(),
      // PDPA: the record exists because of an explicit administrative action,
      // and it is the mirror of the Auth claims — never the source of truth.
      sourceOfTruth: 'firebase_auth_custom_claims',
    },
    { merge: true },
  );
  return before;
}

async function writeAudit(entry) {
  await db.collection('audit_logs').add({
    ...entry,
    at: admin.firestore.FieldValue.serverTimestamp(),
    server: 'functions/' + (entry.fn || 'unknown'),
  });
}

// --- Callable: setUserRole --------------------------------------------------

/**
 * Grants (or changes) a real church role.
 *
 * data: { targetUid | targetEmail, role, branch?, memberId?, reason? }
 * returns: { uid, email, role, previousRole, branch, memberId }
 */
const setUserRole = onCall(async (request) => {
  const actor = requireRoot(request);
  const data = request.data || {};
  const target = pickTarget(data);
  const role = validateRole(data.role);
  const branch = cleanString(data.branch, 120);
  const memberId = cleanString(data.memberId, 60);
  const reason = cleanString(data.reason, 300);

  if (SENSITIVE_GRANTS.includes(role) && actor.role !== 'super_admin') {
    throw new HttpsError(
      'permission-denied',
      'Role ya "' + role + '" inaweza kupewa na super_admin pekee.',
    );
  }

  const userRec = await resolveUser(target);

  if (userRec.uid === actor.uid) {
    throw new HttpsError(
      'failed-precondition',
      'Huwezi kujibadilisha role yako mwenyewe hapa. Tumia akaunti nyingine ya ' +
        'admin au Firebase Console — hii inazuia kanisa kupoteza ufunguzi.',
    );
  }

  const previousRole =
    typeof userRec.customClaims?.role === 'string' ? userRec.customClaims.role : null;

  // A root may not demote someone who outranks them (prevents an admin from
  // silently stripping a super_admin, and vice-versa mistakes).
  if (previousRole && RANK[previousRole] > RANK[actor.role]) {
    throw new HttpsError(
      'permission-denied',
      'Huwezi kubadilisha role ya mtu aliye juu yako (' + previousRole + ').',
    );
  }

  const claims = claimPayload(role, branch, memberId);
  await applyClaims(userRec.uid, claims);
  const before = await writeMemberRecord(userRec, claims, actor.uid, reason);

  await db.collection('role_grants').add({
    targetUid: userRec.uid,
    targetEmail: userRec.email || null,
    previousRole,
    newRole: role,
    branch: branch || null,
    memberId: memberId || null,
    reason,
    grantedBy: actor.uid,
    grantedByEmail: (request.auth && request.auth.token.email) || null,
    revoke: false,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });

  await writeAudit({
    fn: 'setUserRole',
    action: 'role.assign',
    actorUid: actor.uid,
    actorRole: actor.role,
    targetUid: userRec.uid,
    targetEmail: userRec.email || null,
    before: { role: previousRole, branch: before.branch || null },
    after: claims,
    reason,
  });

  return {
    uid: userRec.uid,
    email: userRec.email || null,
    role,
    previousRole,
    branch: claims.branch || null,
    memberId: claims.memberId || null,
  };
});

// --- Callable: revokeUserRole ----------------------------------------------

/**
 * Removes the privileged claim from an account (falls back to `member`).
 * data: { targetUid | targetEmail, reason? }
 */
const revokeUserRole = onCall(async (request) => {
  const actor = requireRoot(request);
  const data = request.data || {};
  const target = pickTarget(data);
  const reason = cleanString(data.reason, 300);

  const userRec = await resolveUser(target);
  if (userRec.uid === actor.uid) {
    throw new HttpsError(
      'failed-precondition',
      'Huwezi kujiondoa role yako mwenyewe hapa.',
    );
  }

  const previousRole =
    typeof userRec.customClaims?.role === 'string' ? userRec.customClaims.role : null;
  if (previousRole && RANK[previousRole] > RANK[actor.role]) {
    throw new HttpsError(
      'permission-denied',
      'Huwezi kuondolea role mtu aliye juu yako (' + previousRole + ').',
    );
  }

  await admin.auth().setCustomUserClaims(userRec.uid, { role: 'member' });
  await writeMemberRecord(userRec, { role: 'member' }, actor.uid, reason);

  await db.collection('role_grants').add({
    targetUid: userRec.uid,
    targetEmail: userRec.email || null,
    previousRole,
    newRole: 'member',
    reason,
    grantedBy: actor.uid,
    revoke: true,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });

  await writeAudit({
    fn: 'revokeUserRole',
    action: 'role.revoke',
    actorUid: actor.uid,
    actorRole: actor.role,
    targetUid: userRec.uid,
    targetEmail: userRec.email || null,
    before: { role: previousRole },
    after: { role: 'member' },
    reason,
  });

  return { uid: userRec.uid, email: userRec.email || null, role: 'member', previousRole };
});

// --- Callable: myClaims (self-service, no privilege revealed to others) -----

/**
 * Lets any signed-in user (and the owner's setup script) see what the server
 * actually believes their role is. Read-only, only about the caller.
 * returns: { uid, email, role, branch, memberId, tokenIssuedAt }
 */
const myClaims = onCall(async (request) => {
  const uid = callerUid(request);
  const token = (request.auth && request.auth.token) || {};
  return {
    uid,
    email: token.email || null,
    role: typeof token.role === 'string' ? token.role : null,
    branch: typeof token.branch === 'string' ? token.branch : null,
    memberId: typeof token.memberId === 'string' ? token.memberId : null,
    tokenIssuedAt: token.iat ? new Date(token.iat * 1000).toISOString() : null,
    verified: true,
  };
});

// --- Trigger: mirror a manually created members/<uid> into claims -----------

/**
 * Escape hatch for the very first administrator: the owner creates
 * `members/<uid> = { role: "super_admin" }` in the Firebase Console (the
 * collection is `allow write: if false` for clients, so only the Console or the
 * Admin SDK can do it). This trigger turns that into real Auth claims and then
 * rewrites the document with the audit fields. After the first admin exists,
 * everyday grants go through `setUserRole`.
 */
const mirrorMemberDocumentIntoClaims = onDocumentCreated(
  'members/{userId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return { skipped: 'no-document' };
    const d = snap.data() || {};
    const uid = event.params.userId;
    const role = validateRole(d.role);

    const existing = await admin.auth().getUser(uid).catch(() => null);
    if (!existing) {
      await writeAudit({
        fn: 'onMemberCreate',
        action: 'role.mirror_failed',
        targetUid: uid,
        before: null,
        after: { role },
        reason: 'Hakuna akaunti ya Auth kwa uid hiyo.',
      });
      return { skipped: 'no-auth-user', uid };
    }

    const previousRole =
      typeof existing.customClaims?.role === 'string' ? existing.customClaims.role : null;
    await applyClaims(uid, claimPayload(role, cleanString(d.branch, 120), cleanString(d.memberId, 60)));

    await snap.ref.set(
      {
        uid,
        role,
        mirroredAt: admin.firestore.FieldValue.serverTimestamp(),
        sourceOfTruth: 'firebase_auth_custom_claims',
        previousRole,
      },
      { merge: true },
    );

    await writeAudit({
      fn: 'onMemberCreate',
      action: 'role.mirror',
      actorUid: 'system',
      targetUid: uid,
      targetEmail: existing.email || null,
      before: { role: previousRole },
      after: { role },
      reason: 'Document iliyundwa na Firebase Console / Admin SDK.',
    });

    return { uid, role, previousRole };
  },
);

/**
 * PDPA 2022 — data subject rights, executed with Admin privileges.
 *
 * Both functions act **only** on the caller's own uid taken from the verified
 * ID token; there is no target parameter, so no one can read or erase anyone
 * else's record through them.
 */
const SUBJECT_COLLECTIONS = [
  { path: 'members', docIdIsUid: true },
  { path: 'profiles', docIdIsUid: true },
  { path: 'consent_records', uidField: 'uid' },
  { path: 'prayer_requests', uidField: 'userId' },
];

async function collectSubjectData(uid) {
  const out = {};
  for (const spec of SUBJECT_COLLECTIONS) {
    try {
      if (spec.docIdIsUid) {
        const snap = await db.collection(spec.path).doc(uid).get();
        out[spec.path] = snap.exists ? [{ id: snap.id, ...snap.data() }] : [];
      } else {
        const snap = await db
          .collection(spec.path)
          .where(spec.uidField, '==', uid)
          .limit(300)
          .get();
        out[spec.path] = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      }
    } catch (e) {
      out[spec.path] = { error: String((e && e.message) || e) };
    }
  }
  return out;
}

/** "Pakia nakala ya data yangu" — right of access (section 26 PDPA). */
const exportMyData = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Lazima uwe umeingia kwenye akaunti yako ili kupata nakala ya data yako.',
    );
  }
  const user = await admin.auth().getUser(uid).catch(() => null);
  const cloudData = await collectSubjectData(uid);
  await writeAudit({
    fn: 'exportMyData',
    action: 'pdpa.access',
    actorUid: uid,
    targetUid: uid,
    before: null,
    after: { collections: Object.keys(cloudData) },
    reason: 'Ombi la mtu binafsi la kupata nakala ya data (DSAR).',
  });
  return {
    generatedAt: new Date().toISOString(),
    law: 'Tanzania Personal Data Protection Act, 2022',
    uid,
    email: (user && user.email) || null,
    claims: (user && user.customClaims) || {},
    cloudData,
  };
});

/** "Futa akaunti yangu" — right to erasure (section 27 PDPA). */
const deleteMyData = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Lazima uwe umeingia kwanza.');
  if (!request.data || request.data.confirm !== true) {
    throw new HttpsError(
      'failed-precondition',
      'Ombi lazima libe confirm:true — hatua hii hairudishwi nyuma.',
    );
  }
  const user = await admin.auth().getUser(uid).catch(() => null);
  const role = (user && user.customClaims && user.customClaims.role) || null;
  if (ROOT_ROLES.includes(role)) {
    throw new HttpsError(
      'failed-precondition',
      'Akaunti hii ina mamlaka ya msimamizi. Ili kufutwa, mmiliki mwingine au ' +
        'wewe kupitia Firebase Console kwanza uondoe role, kisha jaribu tena.',
    );
  }
  if (
    user &&
    Array.isArray(user.providerData) &&
    user.providerData.some((p) => p.providerId === 'phone')
  ) {
    throw new HttpsError(
      'failed-precondition',
      'Akaunti hii imethibitishwa kwa namba ya simu. Wasiliana na Katibu ' +
        '(privacy@zionjerusalem.org) ili kufutwa kwa mkono.',
    );
  }

  const snapshot = await collectSubjectData(uid);
  const counts = {};
  for (const spec of SUBJECT_COLLECTIONS) {
    counts[spec.path] = Array.isArray(snapshot[spec.path])
      ? snapshot[spec.path].length
      : 0;
  }

  // The erasure receipt is written BEFORE the data goes, and it holds only
  // counts — no personal values — so the audit trail does not defeat erasure.
  await writeAudit({
    fn: 'deleteMyData',
    action: 'pdpa.erasure',
    actorUid: uid,
    targetUid: uid,
    targetEmail: (user && user.email) || null,
    before: { counts },
    after: null,
    reason: 'Ombi la mtu binafsi la kufutwa kwa taarifa zake (right to erasure).',
  });

  const removed = {};
  for (const spec of SUBJECT_COLLECTIONS) {
    const rows = Array.isArray(snapshot[spec.path]) ? snapshot[spec.path] : [];
    let n = 0;
    for (const row of rows) {
      try {
        await db.collection(spec.path).doc(row.id).delete();
        n += 1;
      } catch (e) {
        console.error('deleteMyData doc failed', spec.path, row.id, e);
      }
    }
    removed[spec.path] = n;
  }

  let authDeleted = false;
  try {
    await admin.auth().deleteUser(uid);
    authDeleted = true;
  } catch (e) {
    console.error('deleteMyData auth user not deleted', uid, e);
  }

  return { uid, removed, authDeleted, receipt: 'audit_logs/pdpa.erasure' };
});

module.exports = {
  setUserRole,
  revokeUserRole,
  myClaims,
  exportMyData,
  deleteMyData,
  mirrorMemberDocumentIntoClaims,
};
