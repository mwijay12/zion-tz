/**
 * Turns Firebase failures into something a church leader can act on.
 *
 * The portal used to surface raw messages like
 * `FirebaseError: [code=permission-denied]: Missing or insufficient permissions`
 * (or nothing at all). A Katibu has no way to tell whether that means "you
 * are not signed in", "your email is unverified", "your role is not granted",
 * or "the church rules rejected this field". Each of those needs a different
 * action, so they are separated here.
 */

export interface ExplainedError {
  /** Stable identifier for callers that want to branch on the cause. */
  kind: 'auth' | 'unverified' | 'role' | 'validation' | 'network' | 'functions' | 'quota' | 'unknown';
  /** Short, non-technical headline. */
  titleSw: string;
  titleEn: string;
  /** What the leader should actually do next. */
  hintSw: string;
  hintEn: string;
  /** Original message, for the technical details disclosure only. */
  raw: string;
}

function codesOf(error: unknown): string[] {
  const value = error as { code?: unknown; message?: unknown };
  const code = typeof value?.code === 'string' ? value.code : '';
  const message = typeof value?.message === 'string' ? value.message : '';
  return [code, message];
}

export function explainFirebaseError(error: unknown): ExplainedError {
  const [code, message] = codesOf(error);
  const joined = `${code} ${message}`.toLowerCase();
  const raw = message || code || String(error);

  const build = (
    kind: ExplainedError['kind'],
    titleSw: string,
    titleEn: string,
    hintSw: string,
    hintEn: string
  ): ExplainedError => ({ kind, titleSw, titleEn, hintSw, hintEn, raw });

  if (joined.includes('unauthenticated') || joined.includes('admin-restricted') || joined.includes('requires-recent-login')) {
    return build(
      'auth',
      'Haujaingia kwa akaunti halisi',
      'Not signed in to a real account',
      'Ingia kwa barua pepe na neno la siri la akaunti yako ya Firebase. Demo (demo@sayuni.local) haiwezi kuandika wingu.',
      'Sign in with your real Firebase email and password. The demo account (demo@sayuni.local) cannot write to the cloud.'
    );
  }

  if (joined.includes('permission-denied') || joined.includes('missing or insufficient permissions')) {
    return build(
      'role',
      'Sheria za kanisa zimekataa ombi hili',
      'The church security rules rejected this',
      'Sababu zinazowezekana: (1) barua pepe haijathibitishwa, (2) wadhifa wako haujagawiwa kwenye Firebase, au (3) wadhifa wako hauruhusiwi kuandika aina hii ya taarifa. Fungua "Kagua Muunganisho wa Wingu" hapa chini kwa maelezo kamili.',
      'Likely causes: (1) your email is not verified, (2) your role claim was never granted in Firebase, or (3) your role may not write this kind of record. Run "Check cloud connection" below for the full picture.'
    );
  }

  if (joined.includes('email-not-verified') || joined.includes('unverified')) {
    return build(
      'unverified',
      'Barua pepe haijathibitishwa',
      'Email not verified',
      'Bonyeza kiungo cha uthibitisho kwenye barua pepe yako, kisha ingia tena. Firebase hukataa maandishi yote ya viongozi bila uthibitisho.',
      'Open the verification link in your inbox, then sign in again. Firebase refuses every leader write without verification.'
    );
  }

  if (joined.includes('invalid-argument') || joined.includes('failed-precondition') || joined.includes('invalid data')) {
    return build(
      'validation',
      'Taarifa hazikubaliwa',
      'The record was rejected',
      'Sheria za usalama zinakagua urefu na aina ya kila sehemu (mfano kichwa 1–300 herufi, maelezo 1–10,000). Kagua sehemu ndefu au tupu kisha ujaribu tena.',
      'The rules validate field length and type (e.g. title 1–300 chars, body 1–10,000). Check for empty or overlong fields and try again.'
    );
  }

  if (joined.includes('unavailable') || joined.includes('network') || joined.includes('offline') || joined.includes('deadline')) {
    return build(
      'network',
      'Mtandao haupatikani',
      'No connection to Firebase',
      'Taarifa imehifadhiwa kwenye kifaa hiki. Ichapishaji tena mtandao ukirudi — kifaa hiki hakituma kiotomatiki.',
      'The record is saved on this device. Publish again once you are back online — this device does not queue it automatically.'
    );
  }

  if (joined.includes('internal') || joined.includes('not-found') || joined.includes('functions/')) {
    return build(
      'functions',
      'Huduma ya seva haijajibu',
      'The server function did not respond',
      'Cloud Function inaweza kuwa haijasambazwa (deploy) kwenye mkoa africa-south1, au akaunti hii haipo kwenye Firebase Auth. Mhusika anapaswa kujisajili kwenye app kwanza.',
      'The Cloud Function may not be deployed in africa-south1, or this person has no Firebase Auth account yet. They must sign up in the member app first.'
    );
  }

  if (joined.includes('resource-exhausted') || joined.includes('quota') || joined.includes('too-many-requests')) {
    return build(
      'quota',
      'Majaribio mengi mno',
      'Too many attempts',
      'Subiri dakika chache kisha ujaribu tena.',
      'Wait a few minutes and try again.'
    );
  }

  return build(
    'unknown',
    'Imeshindikana kwa sababu isiyojulikana',
    'Failed for an unknown reason',
    'Kagua muunganisho wako kisha ujaribu tena. Kama itaendelea, tumia "Kagua Muunganisho wa Wingu" na uwasilishe maelezo ya kiufundi kwa msimamizi.',
    'Check your connection and retry. If it persists, run "Check cloud connection" and pass the technical details to the administrator.'
  );
}

/** One-line message for a toast or banner, in the active language. */
export function describeFirebaseError(error: unknown, isSw: boolean): string {
  const explained = explainFirebaseError(error);
  return isSw
    ? `${explained.titleSw}. ${explained.hintSw}`
    : `${explained.titleEn}. ${explained.hintEn}`;
}
