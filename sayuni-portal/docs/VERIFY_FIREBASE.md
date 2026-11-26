# Verifying that Firebase actually works

*Last updated: 26 November 2026*

## TL;DR

1. In the portal, sign in with a **real** Firebase account and press **Kagua Wingu** at the bottom of the sidebar. It writes one throwaway document to `health_probe/`, reports each precondition, and deletes it again.
2. Locally, run `npm test` — it checks that `firestore.rules` and the portal's role gates agree.
3. Deploy the rules before relying on the probe: `firebase deploy --only firestore:rules`.

If step 1 says *"Firebase inafanya kazi kwa akaunti hii"*, then notices, sermons, jumuiya reports and poster requests will reach the cloud. If it says otherwise, the panel lists exactly which precondition failed.

---

## Why a probe and not a status badge

The sidebar used to show **"Firebase Sync Active"** permanently. It was decoration: it looked identical whether the signed-in account could write anything or not. Meanwhile several writes failed silently — `churchSync.addSermon()` swallowed the Firestore error with a `console.warn`, so a pastor published a sermon, watched the dialog close, and had no idea the church never received it.

The probe answers the only question that matters: *can this account write right now?* It checks each step separately because each has a different fix:

| Step | Failure means | Fix |
|---|---|---|
| Firebase project | Build points at an unexpected project | Check `.firebaserc` / `firebaseConfig` |
| Signed-in account | Demo session, or signed out | Sign in with a real Firebase account |
| Email verification | `email_verified` is false in the token | Open the verification email, sign in again |
| Role in the token | No `role` custom claim yet | Super Admin grants the role in **Daftari la Waumini** |
| Server-side role | `myClaims` callable unreachable | Deploy functions to `africa-south1` |
| Firestore write test | Rules rejected the write | Read the raw code in the panel |

The probe document contains only `uid`, `email`, `clientAt`, `createdAt`. It is never readable by any client (`allow read, list: if false`) and only its owner may delete it.

---

## Deploying the rules (required for the probe)

`firestore.rules` now includes a `health_probe` block. Until the rules are deployed, the probe will report `permission-denied` even on a perfectly healthy project — because the default rule denies everything not explicitly allowed.

```bash
firebase login
firebase use zion-mbagala-church
firebase deploy --only firestore:rules
```

Deploying rules is safe to re-run; it replaces the rule set atomically.

## Deploying the functions (needed for role grants and the server-side check)

```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

Functions must live in `africa-south1` — that is what `churchRoleService.ts` and `cloudHealthService.ts` call. A mismatch here is the usual cause of `internal` errors on "grant role".

---

## Local verification

### `npm test` — rules ⇄ portal contract

```bash
cd sayuni-portal && npm test
```

This reads the real `firestore.rules` and `AuthService.TAB_ROLES`, then asserts:

- every role the portal lets into a module may perform that module's write;
- deleting a choir song is admin-only in **both** the rules and the UI;
- `health_probe` is write-own-only and never readable;
- no collection is world-writable.

It is a static analysis, not an emulator. It catches role drift — the class of bug that caused real silent failures here — but it cannot evaluate arbitrary rule logic.

### Full rules emulator (needs Java)

The Firestore emulator is the only way to execute the rules for real. It requires a JDK, which the Arena sandbox does not have, so it must be run on a machine with Java:

```bash
# once
npm i -g firebase-tools

# in the repo root, with a JDK installed
firebase emulators:start --only firestore

# then, from the portal package
npm i -D @firebase/rules-unit-testing
```

The scenarios worth asserting first:

| Actor | Action | Expected |
|---|---|---|
| verified secretary | create announcement | allow |
| treasurer | create announcement | deny (UI hides the Office, rules agree) |
| verified pastor | create sermon | allow |
| unverified leader | write anything | deny |
| any user | read `health_probe` | deny |
| owner | delete own probe | allow |
| other user | delete someone's probe | deny |

---

## Known gaps (still not Firebase-verified)

- **Member registry is local-only.** `Daftari la Waumini` writes to `localStorage` and mirrors leader *roles* to Firebase, but member records themselves are not persisted to Firestore. Two devices will not see the same roster yet.
- **Choir songs are local-only.** `saveSongs()` writes `localStorage` and posts to the dev-only `/api/sync/choir-songs` bridge; it does not write `choir_songs` in Firestore.
- **Finance, jumuiya groups and certificates** are local-only, as documented in the root README.
- **No rules tests run in CI.** `npm test` is the contract check only; the emulator suite above should be added to CI when a Java-capable runner is available.
