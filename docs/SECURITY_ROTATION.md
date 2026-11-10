# Security Rotation Checklist — Manual Steps (Cannot Be Done From Code)

> **Why this file exists:** Removing a leaked secret from source code does
> NOT un-leak it. The repository is public and Git history is permanent.
> Every credential below must be rotated in its provider console and the
> old value disabled. Code fixes in this repo stop *new* exposure; only
> rotation stops *old* exposure.

Last reviewed: 2026-11-09 (demo phase — not production)

---

## 1. Firebase Auth passwords (URGENT — was hardcoded in source)

The password `Zion2026Admin!` was committed in `authService.ts` and
`firebaseChurchService.ts` (now removed). Anyone who cloned the repo
knows it.

- [ ] Firebase Console → Authentication → Users: **reset the password**
      for every account that used it (`katibu@`, `pastor@`, `admin@`,
      and any personal Gmail admin accounts).
- [ ] Confirm **Email/Password** provider requires verified email for
      privileged roles (portal + rules now enforce `email_verified`).
- [ ] Confirm the first `super_admin` claim was set via
      `functions/setUserRole` (or the one-time `members/<uid>` mirror),
      not by editing a profile document.
- [ ] Deploy the updated rules: `firebase deploy --only firestore:rules`
- [ ] Deploy functions: `firebase deploy --only functions`
      (region `africa-south1`; if rejected, set `ZION_REGION=us-central1`
      in `functions/.env` AND update `ChurchRoleGrantService.region`).

## 2. Cloudinary

Hardcoded Cloudinary key/secret were removed from source earlier, but
must still be rotated.

- [ ] Cloudinary Console → Settings → API Keys: **rotate key + secret**,
      disable the old pair.
- [ ] Restrict the unsigned preset (`zion_unsigned`): folder, allowed
      formats, max file size, and moderation. Anyone can upload with an
      unsigned preset — scope it down.
- [ ] Production: move uploads behind a signed-upload Cloud Function.

## 3. Gemini / Google AI Studio keys

Keys that appeared in `geminiAudioService.ts` (and any local copies)
must be rotated.

- [ ] Google AI Studio / Cloud Console: delete old keys, create new ones
      with quota caps + API restrictions.
- [ ] Browser TTS keys (`VITE_GEMINI_TTS_KEYS`) are visible in the bundle
      by design — treat them as public, cap their quota, rotate often.
- [ ] Production: proxy TTS through a Cloud Function with App Check.

## 4. Copilot provider keys (Groq / Inception Mercury)

These live only in Vercel env vars (`GROQ_API_KEY`, `MERCURY_KEYS`) —
never in git. The endpoint is unauthenticated, so quota abuse is possible.

- [ ] Vercel → Project → Settings → Environment Variables: verify keys
      are set there and nowhere else.
- [ ] Set provider-side monthly budget caps.
- [ ] Optional: set `COPILOT_API_KEY` in Vercel and send it as
      `x-copilot-key` from the app (requires an app update first).

## 5. GitHub

- [ ] Docs mention a GitHub PAT that leaked via a git remote URL.
      Revoke it and issue a new one with least privilege.
- [ ] If APK signing secrets are added (see `build-apk.yml`), store them
      ONLY as GitHub Secrets (`ANDROID_KEYSTORE_BASE64`, etc.).

## 6. Verify

- [ ] `git log --all -p -S "Zion2026Admin"` shows the old commit — that
      is expected and permanent. Rotation (step 1) is what protects you.
- [ ] Search tracked files for secrets:
      `git grep -n -i -E "api[_-]?key|secret|password" -- . ':!*.lock'`
- [ ] Confirm no `.env`, `key.properties`, `*.jks`, service-account JSON,
      or private key is tracked: `git ls-files | grep -E "\.env$|\.jks|key\.properties|service-account"`

---

## Demo-phase note

This is a **demo, not production**. Do not put real member data
(names, phones, prayer requests, visitor records, giving records) into
Firebase or the portal until steps 1–3 are done and rules tests pass.
Demo mode (`VITE_DEMO_MODE` / `DEMO_MODE=true`) must never connect to
production Firebase with real data.
