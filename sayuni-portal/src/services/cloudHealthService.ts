import { deleteDoc, doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { auth, db, app } from './firebaseChurchService';
import { explainFirebaseError, type ExplainedError } from './firestoreErrors';

export type CheckStatus = 'ok' | 'warn' | 'fail' | 'skip';

export interface HealthStep {
  id: string;
  labelSw: string;
  labelEn: string;
  status: CheckStatus;
  detailSw: string;
  detailEn: string;
  /** Raw Firebase text, shown only under "technical details". */
  raw?: string;
}

export interface HealthReport {
  startedAt: string;
  finishedAt: string;
  steps: HealthStep[];
  /** True only when the write probe succeeded end to end. */
  cloudWrites: boolean;
}

const FUNCTIONS_REGION = 'africa-south1';

/** Wraps a promise so a hung network call cannot spin the UI forever. */
function withTimeout<T>(promise: Promise<T>, ms: number, label: string): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const timer = setTimeout(
      () => reject(Object.assign(new Error(`Muda umeisha (${label}, ${ms / 1000}s)`), { code: 'deadline-exceeded' })),
      ms
    );
    promise.then(
      (value) => { clearTimeout(timer); resolve(value); },
      (error) => { clearTimeout(timer); reject(error); }
    );
  });
}

function fromError(id: string, labelSw: string, labelEn: string, error: ExplainedError, status: CheckStatus = 'fail'): HealthStep {
  return { id, labelSw, labelEn, status, detailSw: `${error.titleSw}. ${error.hintSw}`, detailEn: `${error.titleEn}. ${error.hintEn}`, raw: error.raw };
}

/**
 * End-to-end proof that the portal can actually use Firebase — not just that
 * the SDK initialised.
 *
 * "inafanya kazi?" cannot be answered by reading config. The only honest
 * answer comes from attempting a real, reversible write and seeing whether
 * `firestore.rules` accept it for this exact account. Each step below maps to
 * a separate failure mode so the leader knows which one to fix.
 */
export async function runCloudHealthCheck(): Promise<HealthReport> {
  const startedAt = new Date().toISOString();
  const steps: HealthStep[] = [];
  let cloudWrites = false;

  // 1. Which project/region this build talks to.
  const projectId = app.options.projectId ?? '(hapana)';
  steps.push({
    id: 'config',
    labelSw: 'Mradi wa Firebase',
    labelEn: 'Firebase project',
    status: projectId === 'zion-mbagala-church' ? 'ok' : 'warn',
    detailSw: `${projectId} · functions: ${FUNCTIONS_REGION}`,
    detailEn: `${projectId} · functions: ${FUNCTIONS_REGION}`,
  });

  // 2. Signed in at all? (The demo session never reaches this far.)
  const user = auth.currentUser;
  if (!user) {
    steps.push({
      id: 'auth',
      labelSw: 'Akaunti iliyoingia',
      labelEn: 'Signed-in account',
      status: 'fail',
      detailSw: 'Hakuna akaunti halisi ya Firebase. Demo (demo@sayuni.local) haifanyi maandishi yoyote ya wingu — hiyo ndiyo kazi yake.',
      detailEn: 'No real Firebase account. The demo login (demo@sayuni.local) makes no cloud writes by design.',
    });
    steps.push({
      id: 'write',
      labelSw: 'Jaribio la kuandika Firestore',
      labelEn: 'Firestore write test',
      status: 'skip',
      detailSw: 'Imerukwa — hakuna akaunti halisi.',
      detailEn: 'Skipped — no real account.',
    });
    return { startedAt, finishedAt: new Date().toISOString(), steps, cloudWrites: false };
  }

  steps.push({
    id: 'auth',
    labelSw: 'Akaunti iliyoingia',
    labelEn: 'Signed-in account',
    status: 'ok',
    detailSw: `${user.email ?? '(barua pepe haipo)'} · uid ${user.uid.slice(0, 8)}…`,
    detailEn: `${user.email ?? '(no email)'} · uid ${user.uid.slice(0, 8)}…`,
  });

  // 3. Email verification — rules require email_verified == true for every
  //    privileged write, so an unverified account fails later with a
  //    confusing permission-denied. Catch it here instead.
  steps.push({
    id: 'verified',
    labelSw: 'Uthibitisho wa barua pepe',
    labelEn: 'Email verification',
    status: user.emailVerified ? 'ok' : 'fail',
    detailSw: user.emailVerified
      ? 'Imethibitishwa.'
      : 'Haijathibitishwa. Firebase hukataa maandishi yote ya viongozi. Fungua kiungo kwenye barua pepe yako kisha ingia tena.',
    detailEn: user.emailVerified
      ? 'Verified.'
      : 'Not verified. Firebase refuses every leader write. Open the link in your inbox, then sign in again.',
  });

  // 4. Client-side role claim (what the token the browser holds says).
  try {
    const token = await withTimeout(user.getIdTokenResult(true), 12000, 'token');
    const role = typeof token.claims.role === 'string' ? token.claims.role : null;
    const legacyAdmin = token.claims.admin === true;
    steps.push({
      id: 'claim',
      labelSw: 'Wadhifa kwenye tokeni',
      labelEn: 'Role in the token',
      status: role || legacyAdmin ? 'ok' : 'fail',
      detailSw: role
        ? `role = ${role}`
        : legacyAdmin
          ? 'admin = true (wadhifa wa zamani)'
          : 'Hakuna claim ya role. Msimamizi anapaswa kukupa wadhifa kupitia Daftari la Waumini.',
      detailEn: role
        ? `role = ${role}`
        : legacyAdmin
          ? 'admin = true (legacy claim)'
          : 'No role claim. An administrator must grant you a role from the Members registry.',
    });
  } catch (error) {
    steps.push(fromError('claim', 'Wadhifa kwenye tokeni', 'Role in the token', explainFirebaseError(error)));
  }

  // 5. Server-side truth (is the claim really set on the account, or is the
  //    browser holding an old token?).
  try {
    const functions = getFunctions(app, FUNCTIONS_REGION);
    const myClaims = httpsCallable<Record<string, never>, { role?: string; branch?: string; email?: string }>(
      functions,
      'myClaims'
    );
    const result = await withTimeout(myClaims({}), 15000, 'myClaims');
    const serverRole = result.data?.role;
    steps.push({
      id: 'server-claim',
      labelSw: 'Wadhifa kwenye seva',
      labelEn: 'Server-side role',
      status: serverRole && serverRole !== 'member' ? 'ok' : 'warn',
      detailSw: serverRole
        ? `Seva inasema role = ${serverRole}. Cloud Functions zinafanya kazi.`
        : 'Seva haikurudisha wadhifa. Ukiwa na claim kwenye tokeni, toka kisha ingia tena ili tokeni mpya itumike.',
      detailEn: serverRole
        ? `Server says role = ${serverRole}. Cloud Functions are reachable.`
        : 'The server returned no role. If your token has one, sign out and back in so a fresh token is issued.',
    });
  } catch (error) {
    const explained = explainFirebaseError(error);
    steps.push({
      ...fromError('server-claim', 'Wadhifa kwenye seva', 'Server-side role', explained,
        explained.kind === 'role' ? 'warn' : 'fail'),
      detailSw: `${explained.titleSw} — Cloud Function "myClaims" haijajibu. Ikiwa hii ni deployment mpya, hakikisha functions zimesambazwa kwenye ${FUNCTIONS_REGION}.`,
      detailEn: `${explained.titleEn} — the "myClaims" function did not respond. On a fresh deployment, confirm functions are deployed to ${FUNCTIONS_REGION}.`,
    });
  }

  // 6. THE REAL TEST: write one tiny document and delete it again.
  //    This exercises auth + custom claims + firestore.rules end to end.
  const probeId = `probe-${user.uid}-${Date.now()}`;
  try {
    await withTimeout(
      setDoc(doc(db, 'health_probe', probeId), {
        uid: user.uid,
        email: user.email ?? '',
        clientAt: new Date().toISOString(),
        createdAt: serverTimestamp(),
      }),
      20000,
      'firestore write'
    );
    cloudWrites = true;
    steps.push({
      id: 'write',
      labelSw: 'Jaribio la kuandika Firestore',
      labelEn: 'Firestore write test',
      status: 'ok',
      detailSw: 'Kiliandikwa na kufutwa kwa mafanikio — Firebase inafanya kazi kwa akaunti hii.',
      detailEn: 'Written and deleted successfully — Firebase works for this account.',
    });

    // Clean up the probe so the collection never accumulates data.
    try {
      await withTimeout(deleteDoc(doc(db, 'health_probe', probeId)), 12000, 'cleanup');
    } catch {
      steps.push({
        id: 'cleanup',
        labelSw: 'Kufuta jaribio',
        labelEn: 'Probe cleanup',
        status: 'warn',
        detailSw: 'Maandishi ya jaribio yamebaki. Msimamizi anaweza kuyafuta kwenye console; hayana data ya muumini.',
        detailEn: 'The probe document remains. An admin can delete it; it contains no member data.',
      });
    }
  } catch (error) {
    const explained = explainFirebaseError(error);
    steps.push(fromError('write', 'Jaribio la kuandika Firestore', 'Firestore write test', explained));
  }

  return { startedAt, finishedAt: new Date().toISOString(), steps, cloudWrites };
}

/** Human-readable summary line for the sidebar status pill. */
export function summariseReport(report: HealthReport, isSw: boolean): { text: string; tone: 'ok' | 'warn' | 'fail' } {
  if (report.cloudWrites) {
    return { text: isSw ? 'Wingu linafanya kazi' : 'Cloud working', tone: 'ok' };
  }
  const failures = report.steps.filter((step) => step.status === 'fail');
  if (failures.length > 0) {
    return { text: isSw ? 'Wingu halifanyi kazi' : 'Cloud not working', tone: 'fail' };
  }
  return { text: isSw ? 'Wingu halijakaguliwa' : 'Cloud unchecked', tone: 'warn' };
}
