# Zion Jerusalem Engineering Plan

**Status:** Active recovery plan, prototype -> production
**Baseline:** 20 October 2026
**Companion document:** [README.md](./README.md)
**Scope:** Flutter member application, React leadership portal, Firebase backend, media, reports, certificates, and engagement features.

---

## 1. Executive decision

The project already has a credible product surface: a complete-looking Flutter app, a leadership portal, offline Bible and hymn content, media screens, notes, and a print-based reporting flow. The gap is no longer visual. The gap is **trust**.

The system cannot be released to a real congregation until these are true:

1. Only authorised leaders can read or change church data.
2. A user can see an error when a cloud write fails.
3. "Offline" means the content and audio are actually on the device.
4. Audio keeps playing on the lock screen and survives normal Android background limits.
5. Certificates and official reports are generated from real records, not hardcoded demo values.
6. The church can verify a certificate or report without exposing member data.
7. No API secret is embedded in a client bundle or a public repository.

The correct order is therefore **identity and data integrity -> media and offline reliability -> official documents -> engagement -> polish and launch**. Starting with games or visual polish before authentication would create features on top of a system that cannot safely store data.

**Release rule:** no public launch while any P0 item in this plan is open.

---

## 2. Baseline evidence

### 2.1 What was verified

| Check | Result | Notes |
|---|---|---|
| Portal production build | Passes | `npm run build`; ~973 kB main JS, ~273 kB gzip |
| Portal lint | Passes with 18 warnings | Unused catches, a React purity warning, and hook-dependency concerns |
| Mobile static analysis | Passes | `dart analyze lib` reports no issues |
| Mobile tests | 7/7 pass | `flutter test` |
| Firebase web configuration | Present | Project `zion-mbagala-church`; rules and indexes exist |
| Android Firebase config | Present | `google-services.json`; no signing keystore found |
| Repository state at audit | No Git history | Target remote was empty and public |
| Overall status | Prototype | Not ready for public production use |

### 2.2 What exists but is not production logic

- **Portal login:** local storage and generic role seed users. Automatic super-admin sign-in has been removed, but choosing a role is still not identity verification.
- **Cloud writes:** mostly unauthenticated browser writes against rules that require `request.auth != null`; failures can be swallowed.
- **Portal sync:** a Vite dev server provides in-memory `/api/sync` endpoints. Those endpoints do not exist on a static host.
- **Media upload:** unsigned Cloudinary uploads with a public preset; no server-side validation or signed access model.
- **Offline audio:** the Bible screen records downloaded chapter IDs in SharedPreferences without downloading audio files.
- **Lock-screen playback:** local notification callbacks exist, but there is no Android media session, foreground service, or `AudioHandler`.
- **Video:** links are opened in an external application; no in-app player.
- **Reports:** HTML views sent to `window.print()`; no deterministic PDF or verification record.
- **Certificates:** the demo form is not backed by persisted records, generated serials, a registry, or verification.
- **Engagement:** no quizzes, streaks, challenges, badges, or leaderboards.
- **Notifications:** local only; no FCM token lifecycle or server push.
- **Biometric/session behavior:** no production authentication session model.
- **Encoding:** current text files are UTF-8 clean, but there is no automated encoding or mojibake guard in CI.

### 2.3 What was already corrected in the current working tree

- Hardcoded Cloudinary API key and API secret were removed from portal and mobile upload services.
- Hardcoded Gemini key arrays were removed from the portal TTS service and the mobile wisdom service.
- Portal environment example created at `zion-portal/.env.example`.
- Root `.gitignore` created for dependencies, builds, secrets, APKs, logs, local agent state, and reference prototypes.
- Animated README hero created at `docs/assets/hero.svg`.
- Portal demo users were genericized, automatic super-admin sign-in was removed, and the portal now requires a demo session to render.
- Personal mobile demo emails and passwords were removed. Admin demo sign-in now requires `ADMIN_DEMO_PASSWORD`, and the quick-admin onboarding bypass is gone.
- Firestore rules were changed from a personal-email allowlist to custom-claim checks; profile role escalation and the announcement `authorRole` bypass were closed.
- Documentation rewrite and repository push are part of this delivery.

**Remaining obligation:** removal from source does not un-leak a key. Rotate the Cloudinary key/secret and every Gemini key that was present, then verify that old keys are disabled.

---

## 3. Product definition

### 3.1 Users

| User | Primary needs | Current experience |
|---|---|---|
| Church member | Bible, hymns, sermons, radio, events, prayer, personal notes, spiritual growth | Broad but partly local or unfinished |
| Jumuiya leader | Care follow-up, attendance, reports, announcements | Portal is not safely authenticated |
| Pastor / department head | Sermons, media, reports, certificates, oversight | Print flows and mock data |
| Administrator | Roles, content, media, audit, verification | Demo auth and client-side roles |
| Visitor | Service information, location, contact, prayer | Limited public journey |

### 3.2 Product goals

1. Help a member open the app and reach the Bible, a hymn, or a sermon in under 15 seconds.
2. Make church announcements and events available without a leader needing a developer.
3. Give leaders a single, trustworthy view of care requests, Jumuiya reports, and media.
4. Work usefully on a weak or absent connection.
5. Produce official documents that can be verified by a third party.
6. Encourage daily Word engagement without turning faith into a gambling or pay-to-win system.

### 3.3 Non-goals for the first production release

- Online tithes, offerings, or card payments. Any giving feature needs a separate compliance and security review.
- Live video production and streaming infrastructure. Link to an existing live stream first.
- Public member-to-member chat or pastoral counselling by AI.
- Open social feeds, direct messaging, or unmoderated public testimony.
- AI-generated sermons or authoritative spiritual answers. TTS may read approved text; it must not invent doctrine.
- A full church management suite. Keep the first release focused on communication, care, media, Bible, and reports.

---

## 4. Engineering principles

1. **Security before features.** A feature that writes data without identity is not a feature; it is a liability.
2. **The server owns the truth.** Roles, scores, certificate issuance, upload signatures, and privilege changes belong on the server.
3. **No silent failure.** Every write must surface success, queued state, or a recoverable error.
4. **Offline-first, not offline-labelled.** If the UI says downloaded, the media file must exist and be verifiable.
5. **One source of truth per entity.** Remove duplicate local mocks when the Firestore repository is live.
6. **Least privilege and data minimisation.** Do not collect member data that the church cannot protect or needs.
7. **Swahili first, English where useful.** Copy and content should be reviewed by a fluent church editor.
8. **Accessibility is part of quality.** Large text, contrast, screen-reader labels, and reduced motion are acceptance criteria.
9. **No secret in a client.** Vite variables and Dart defines are visible in the shipped app.
10. **No paid advantage in discipleship.** Points and badges must never be purchasable or tied to giving.

---

## 5. Priority model

| Priority | Meaning | Examples |
|---|---|---|
| P0 | Blocks any real deployment | Authentication, rules, secret rotation, role enforcement, write failures |
| P1 | Required for a trustworthy release | Lock-screen audio, real downloads, PDF reports, certificate registry |
| P2 | Core product value | Bible games, streaks, challenges, complete portal workflows, notifications |
| P3 | Scale and polish | Performance, accessibility, analytics, localization, admin automation |

**Dependency rule:** P0 -> P1 -> P2 -> P3. Workstreams B and D may run in parallel only after P0 authentication and rules tests are passing.

---

## 6. Workstream A: Security, identity, and data integrity (P0)

### A1. Secret containment and rotation

**Why first:** the repository is public and at least one secret was hardcoded. A UI fix cannot compensate for a leaked key.

Tasks:

- [ ] Rotate the Cloudinary API key and API secret in the Cloudinary console.
- [ ] Rotate all Gemini API keys that appeared in `geminiAudioService.ts` or any local copy.
- [ ] Disable old keys after verifying the new configuration.
- [ ] Move privileged Cloudinary operations to a signed-upload Cloud Function.
- [ ] Keep unsigned presets only where intentionally public; restrict preset folder, formats, max size, and moderation.
- [ ] Move Gemini TTS behind a Cloud Function with App Check, per-user rate limits, and a monthly budget cap.
- [ ] Confirm no service-account JSON, keystore, `.env`, or private key is tracked.
- [ ] Add `gitleaks` or equivalent to CI and a local pre-commit hook.
- [ ] Document that `VITE_*` and `--dart-define` values are visible in client artifacts.

**Acceptance**

- A search of tracked files and Git history finds no live secret.
- The portal builds without any secret in its bundle.
- Mobile uploads work with a public, scoped preset or a signed server request.
- TTS is unavailable when no server-side configuration exists, with a clear user message.
- Rotated credentials are recorded in the church password manager, not in the repository.

### A2. Firebase Authentication

**Why second:** every rules decision depends on a trustworthy identity.

Tasks:

- [ ] Enable Firebase Authentication with email/password for leaders.
- [ ] Add Google sign-in only if the church has a Google Workspace or verified identity policy.
- [ ] Remove the localStorage demo session from `zion-portal/src/services/authService.ts`.
- [x] Remove the auto-seeded super-admin session from `zion-portal/src/App.tsx`.
- [ ] Add an auth provider and protected routes; do not render admin screens before claims resolve.
- [ ] Store roles only in Firebase custom claims, never in localStorage or editable Firestore profile fields.
- [ ] Add invite-only account creation through an admin Cloud Function.
- [ ] Add password reset and forced re-authentication for sensitive actions.
- [ ] Require MFA for `super_admin`; recommend it for pastors and finance-adjacent roles.
- [ ] Mobile: initialise Firebase Auth; use anonymous auth only for public features; allow upgrade by email/phone.
- [ ] Restore a Firebase session on app launch; route to onboarding only when unauthenticated.
- [ ] Add a clearly labelled demo mode behind a build-time flag; demo mode must never connect to production Firebase.

**Role model**

| Claim | Access |
|---|---|
| `super_admin` | All content, roles, settings, audit, verification |
| `pastor` | Care, reports, announcements, certificates, media oversight |
| `leader` | Scoped Jumuiya/department data, reports, assigned events |
| `editor` | Content and media drafts; no member or care access |
| `viewer` | Read-only dashboard or reports |
| `member` | Own profile, own notes/bookmarks, public content |
| `anonymous` | Public content and public forms only |

**Acceptance**

- Signing out clears protected data from the UI immediately.
- A member cannot reach an admin route by changing local state or a URL.
- A leader's claim limits Firestore reads and writes to the correct Jumuiya.
- Expired or revoked sessions fail closed.
- Rules tests prove that each role can and cannot perform its matrix of actions.

### A3. Firestore and Storage rules

**Why now:** the current rules require authentication while the current portal does not use it. Fixing only the client would create a false sense of safety.

Tasks:

- [ ] Rewrite rules with deny-by-default and small, tested helper functions.
- [ ] Review and fix the confidentiality-field mismatch (`isPrivate` versus `isConfidential`).
- [ ] Replace boolean flags with one explicit enum such as `visibility: private | pastoral | public`.
- [ ] Restrict `prayer_requests` reads to the owner and authorised pastoral roles.
- [ ] Restrict `visitors_registry` to authorised follow-up leaders; never expose it publicly.
- [ ] Allow public visitor submission only through a rate-limited callable or a separate public form collection with no read access.
- [ ] Split public content from private member data into separate collections.
- [ ] Validate field types, required fields, allowed enum values, and maximum sizes on create and update.
- [ ] Prevent clients from changing `role`, `createdAt`, `createdBy`, `ownerId`, `serial`, or verification fields.
- [ ] Add append-only audit records for sensitive changes.
- [ ] Add Storage rules and App Check.
- [ ] Add emulator rules tests for anonymous, member, leader, pastor, admin, and cross-Jumuiya access.
- [ ] Add rules deployment to CI after tests pass.

**Acceptance**

- Every collection has an explicit read/write policy and a test.
- Anonymous users cannot read member, prayer, visitor, report, or certificate-owner data.
- A leader cannot read another Jumuiya's private records.
- A write with an invalid field or oversized payload is rejected.
- A public testimony cannot be published without moderation.
- Rules tests run locally and in CI.

### A4. Privileged operations and Cloud Functions

Add a TypeScript Cloud Functions codebase (or extend the existing Firebase project with one) for operations that cannot be trusted to a browser:

| Function | Purpose |
|---|---|
| `assignRole` | Validate caller, write custom claim, audit |
| `createUploadSignature` | Sign Cloudinary uploads and restrict folder/size/type |
| `deleteMedia` | Remove Cloudinary asset and Firestore record |
| `synthesizeSpeech` | Server-side Gemini TTS with quota and App Check |
| `submitQuizAttempt` | Score answers server-side; never trust client score |
| `issueCertificate` | Snapshot data, create serial and hash, write registry |
| `verifyCertificate` | Rate-limited public lookup with minimal data |
| `issueOfficialReport` | Snapshot authorised data and generate a tamper-evident record |
| `sendPush` | Fan out FCM messages to opted-in topics or users |
| `cleanupExpiredData` | Retention and orphaned-upload cleanup |

**Acceptance**

- No privileged action is possible by calling Firestore directly from a client.
- Functions reject unauthenticated, unverified, or rate-limited callers.
- Every privileged mutation writes an audit entry.

### A5. Privacy and care data

Tasks:

- [ ] Define what member data is collected and why.
- [ ] Minimise phone numbers, addresses, pastoral notes, and visitor details.
- [ ] Add a privacy notice and consent text in Swahili and English.
- [ ] Add retention periods for visitor follow-up, prayer requests, and pastoral reports.
- [ ] Provide export/delete procedures for member data.
- [ ] Ensure prayer and counselling content is never included in public reports or logs.
- [ ] Restrict screenshots/printing of sensitive views where appropriate; do not rely on UI hiding as security.
- [ ] Define a data breach and key-rotation contact.
- [ ] Review Tanzania data-protection obligations with the church's legal adviser.
- [ ] Define a policy for minors and youth records.

**Acceptance**

- A data inventory exists.
- Sensitive collections have access tests and retention rules.
- No member phone list is visible on a public page.
- The privacy notice matches the data actually collected.

---

## 7. Workstream B: Media, audio, and lock-screen playback (P1)

### B1. Replace the playback architecture

Recommended stack:

- `just_audio` for audio sources, playlists, seeking, and buffering.
- `audio_service` for the media session, notification, lock-screen controls, and headset buttons.
- `audio_session` for focus and interruptions.
- `flutter_local_notifications` only for reminders, not as a substitute for media controls.

Tasks:

- [ ] Introduce one `ChurchAudioHandler` implementing `AudioHandler`.
- [ ] Register it at app startup before the UI needs playback.
- [ ] Publish `MediaItem` title, artist, album, duration, and artwork URI.
- [ ] Implement play, pause, skip, seek, stop, and queue behavior.
- [ ] Handle phone calls, other audio apps, headset unplug, and Bluetooth changes.
- [ ] Keep the notification in sync with the in-app mini-player.
- [ ] Handle expired stream URLs and network errors with a retry action.
- [ ] Add "continue where you left off" for sermons using a local position store.
- [ ] Add a sleep timer and playback speed if the design calls for them.
- [ ] Ensure radio and sermon playback do not fight over a single player accidentally.

### B2. Android and iOS platform configuration

Tasks:

- [ ] Declare a media playback foreground service with `android:foregroundServiceType="mediaPlayback"`.
- [ ] Add `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`, and notification permissions for supported Android versions.
- [ ] Add the `AudioService`/media button receiver declarations required by the selected plugin.
- [ ] Configure notification channels and a small notification icon.
- [ ] Disable battery optimisation guidance where appropriate; do not force users to change system settings silently.
- [ ] Configure iOS background audio mode and Now Playing metadata if iOS is a supported release target.
- [ ] Test Android 10, 12, 13, 14, and the current target in 2026.

**Acceptance**

- Audio continues for at least 30 minutes with the screen locked.
- Lock-screen title/artwork/controls are correct.
- Pause/play works from a Bluetooth headset.
- Force-stopping the app stops playback cleanly; normal backgrounding does not.
- A phone call pauses playback and resumes only when appropriate.

### B3. Real media content and licensing

Tasks:

- [ ] Define a media schema: title, speaker, date, series, language, duration, source type, visibility, transcript, thumbnail, media URL, downloadable flag.
- [ ] Seed sermons from real church content with written permission.
- [ ] Fix the media hub so it does not depend only on custom uploads.
- [ ] Separate public sermons from members-only or leadership-only media.
- [ ] Store audio artwork in an optimised format and cache it.
- [ ] Record asset licences for music, images, and Bible translations.
- [ ] Add moderation and unpublished/draft states for uploads.

### B4. Radio

Tasks:

- [ ] Keep Radio Browser as a discovery source, but cache the last successful station list.
- [ ] Add explicit loading, buffering, offline, and station-unavailable states.
- [ ] Add favourites and recent stations locally.
- [ ] Allow a curated church station list to override unreliable directory results.
- [ ] Do not imply that a third-party station is officially endorsed by the church unless it is.

### B5. Video and live links

Tasks:

- [ ] Choose between direct MP4 playback (`video_player`/`chewie`) and a YouTube embed (`youtube_player_iframe`).
- [ ] Keep external launch as a fallback, not the primary experience.
- [ ] Add a clear "Live" section that links to the church's actual live platform.
- [ ] Do not implement background video playback.
- [ ] Test slow networks and unavailable videos.

### B6. Offline audio downloads

This is part of workstream C, but it is listed here because the media UI depends on it.

- [ ] Replace the SharedPreferences flag with a real download manager.
- [ ] Download to the app documents directory, not a temporary cache.
- [ ] Verify SHA-256 and size before marking an item downloaded.
- [ ] Support pause, resume, cancel, delete, and storage usage.
- [ ] Handle storage-full and permission errors.
- [ ] Reflect download state in the Bible, sermon, and hymn lists.
- [ ] Use a background queue for large downloads after the foreground flow is stable.

**Acceptance**

- Airplane mode playback works after a completed download.
- A interrupted download is never shown as complete.
- Deleting a download frees space and updates the UI.
- The app explains when a stream requires internet.

---

## 8. Workstream C: Offline-first data and sync (P1)

### C1. Replace SharedPreferences as a domain database

SharedPreferences is appropriate for a theme choice or a last-selected tab. It is not appropriate for notes, prayer drafts, download state, quiz history, or sync queues.

Recommended:

- `drift` + SQLite for relational local data, migrations, and testability.
- `flutter_secure_storage` for session tokens or secrets if needed; Firebase Auth already manages its own token persistence.
- Keep `shared_preferences` only for simple settings.

Tasks:

- [ ] Define local tables for the entities the app actually owns: notes, bookmarks, downloads, reading progress, outbox, quiz history, settings.
- [ ] Write a migration from existing SharedPreferences keys.
- [ ] Add repository interfaces so UI widgets do not call Firestore or SharedPreferences directly.
- [ ] Keep Firestore SDK persistence for cached server reads where it is sufficient.
- [ ] Encrypt sensitive local records or exclude them from device backup, as policy requires.
- [ ] Add a local "clear my data" action.

### C2. Outbox and conflict policy

Tasks:

- [ ] Every local mutation writes the entity and an outbox entry in one transaction.
- [ ] Each outbox entry has a client-generated ID, entity type, payload, attempt count, and created time.
- [ ] Sync uses idempotent writes and server timestamps.
- [ ] Define conflict rules:
  - Announcements and official content: server wins; clients cannot overwrite.
  - Member notes/bookmarks: last-write-wins with a version check, or field-level merge.
  - Prayer drafts: owner wins until submitted; submitting creates an immutable request snapshot.
  - Quiz scores: server only.
- [ ] Show "pending sync", "synced", and "failed" states visibly.
- [ ] Add exponential backoff, manual retry, and a dead-letter view for failed writes.
- [ ] Do not silently discard failed user content.

### C3. Remove the development-only sync path

Tasks:

- [ ] Remove production dependence on `vite.config.ts` `/api/sync` endpoints.
- [ ] Make Firestore the only cloud source of truth.
- [ ] Remove or clearly label all mock data services in production routes.
- [ ] Decide Firebase Hosting versus Vercel; the current dev middleware is not a serverless API.
- [ ] If a web server is still required, add a real Cloud Function or a deployed API, not Vite middleware.
- [ ] Add a startup health check that reports configuration problems rather than pretending success.

**Acceptance**

- A production build on a static host can read and write authorised data.
- The app works offline for its declared offline features.
- Reconnecting flushes queued mutations exactly once.
- Two devices editing the same note produce a predictable, documented result.
- A failed write remains visible and retryable.

---

## 9. Workstream D: Reports, certificates, and official documents (P1)

### D1. Real PDF generation

Replace browser print screenshots with a deterministic document pipeline.

Recommended:

- Portal: `@react-pdf/renderer` or `pdfmake` with embedded fonts and a shared template module.
- Mobile: existing `pdf` + `printing` packages, using the same visual specification.
- Store generated PDFs in Cloud Storage only if they must be re-downloaded; otherwise generate on demand.
- Use an A4 layout with page numbers, generation timestamp, church identity, and a verification footer.

Tasks:

- [ ] Define report templates before writing code: attendance, Jumuiya activity, care summary, events, and financial summaries if approved.
- [ ] Remove mojibake and use a bundled font with Swahili diacritics.
- [ ] Include filters, date range, department, Jumuiya, and prepared-by fields.
- [ ] Show totals and clearly label estimates versus confirmed figures.
- [ ] Add a preview screen and an explicit "Issue official report" action.
- [ ] Never label a draft as official.
- [ ] Add page-break tests with long tables.
- [ ] Add accessible HTML preview alongside the PDF.
- [ ] Validate the output in common PDF readers.

**Acceptance**

- The same input produces a consistent PDF.
- Long tables paginate without clipped rows.
- Swahili text renders correctly.
- Sensitive reports are downloadable only by authorised roles.
- A generated report has a record of who issued it and when.

### D2. Certificate registry and verification

Tasks:

- [ ] Remove hardcoded names, dates, and serial numbers from `CertificateStudio.tsx`.
- [ ] Create an issuance form with recipient, course/event, date, signatory, and template.
- [ ] Generate a collision-resistant serial, for example `ZJC-CERT-2026-000123`.
- [ ] Store a certificate registry record with a hash of the canonical certificate data.
- [ ] Generate a QR code that points to the church verification page.
- [ ] Add a public verification page that returns only validity, certificate type, issue date, and a masked or approved name.
- [ ] Support revoked and reissued certificates.
- [ ] Add a PDF download and an optional printed signature image.
- [ ] Rate-limit verification to prevent serial enumeration.
- [ ] Add an admin search for certificates.

**Acceptance**

- A certificate cannot be created by editing HTML in the browser.
- Scanning the QR code verifies a real registry record.
- A revoked certificate shows as invalid.
- The verification page does not expose phone numbers, addresses, or pastoral notes.
- A certificate can be regenerated from the registry if the original PDF is lost.

### D3. Report and document access

- [ ] Store report access in rules and audit logs.
- [ ] Use short-lived signed URLs for private PDFs.
- [ ] Expire public document links.
- [ ] Add a retention and deletion policy for issued documents.
- [ ] Separate "member receipt" documents from internal pastoral reports.

---

## 10. Workstream E: Discipleship engagement and Bible games (P2)

### E1. Product guardrails

The purpose is sustained engagement with Scripture and church life, not manipulation.

- No payment, giving, or purchase may buy points, streaks, or rank.
- No public ranking of prayer requests, care needs, or giving.
- No shaming copy for a broken streak.
- No public profile by default.
- No dark patterns, loot boxes, random paid rewards, or gambling mechanics.
- No direct messaging between minors and unrelated adults.
- Content must be reviewed by a church editor before publication.
- Scores must be server-authoritative.

### E2. Core loops

1. **Daily Word:** read or listen to an assigned passage; mark complete; receive a small, non-monetary reward.
2. **Daily quiz:** five reviewed questions from the current teaching series.
3. **Weekly challenge:** a service, memorisation, prayer, or community action.
4. **Milestones:** badges for consistency and breadth, not only speed.
5. **Community:** optional, moderated group progress; no public personal data by default.

### E3. Suggested data model

| Collection | Purpose | Access |
|---|---|---|
| `gamification_profiles/{uid}` | Points, streak, timezone, privacy, level | Owner can read; server writes |
| `quiz_questions/{id}` | Question, options, explanation, reference, status | Public question text only when published; answer key server-only |
| `daily_quizzes/{date}` | Ordered question set and release window | Public metadata; no answers |
| `quiz_attempts/{id}` | User, quiz, answers, score, timestamps | Owner and authorised leaders |
| `challenges/{id}` | Weekly challenge and rules | Published read |
| `challenge_completions/{id}` | Completion evidence and approval | Owner; leader scoped |
| `badges/{id}` | Badge definitions and criteria | Public read |
| `leaderboard_snapshots/{period}` | Aggregated, opt-in standings | Public only if policy allows |

Avoid storing correct answers in documents readable by the client before submission. Use a callable `submitQuizAttempt` that validates timing, rotates questions, and returns only the score and explanations.

### E4. Mechanics

- [ ] Daily reading streak with one optional "grace day" per month, if approved.
- [ ] Points for reading, quiz completion, challenge completion, and consistent participation.
- [ ] Levels with church-appropriate names and no real-world privilege.
- [ ] Badges for book completion, memorisation, service, generosity awareness, and consistency.
- [ ] Bible games: verse scramble, fill in the blank, book order, character matching, and reference lookup.
- [ ] Weekly challenge with leader approval for service-based actions.
- [ ] Opt-in group leaderboard, defaulting to display name or initial only.
- [ ] Timezone-aware day boundaries, using the member's chosen timezone or the church's timezone.
- [ ] Server rate limits and anomaly detection for impossible completion times.
- [ ] A content calendar owned by the teaching team.

### E5. Anti-cheat and fairness

- [ ] Score on the server, never from a client-supplied score.
- [ ] Sign-in required for scored activity; anonymous users can browse but not rank.
- [ ] Rotate questions and limit answer windows.
- [ ] Hash or hide answer keys.
- [ ] Reject duplicate attempts for the same quiz/day.
- [ ] Detect multiple accounts on a device where reasonable, without invasive tracking.
- [ ] Audit manual leader approvals.
- [ ] Provide an appeal/removal process for wrong content.

### E6. Phased delivery

1. Reading progress and streaks.
2. Daily quiz with server scoring.
3. Badges and weekly challenges.
4. Bible mini-games.
5. Opt-in group leaderboards.
6. Notification reminders and content analytics.

**Acceptance**

- A user cannot edit local storage to gain points.
- A quiz attempt cannot be submitted twice for the same day.
- Answer keys are not readable before submission.
- Leaderboards are empty for users who have not opted in.
- All seeded questions cite a reviewed Bible reference.
- No streak notification is sent outside the user's chosen quiet hours.

---

## 11. Workstream F: Portal and mobile completion (P2/P3)

### F1. Portal information architecture

The portal should become a role-aware operations tool, not a collection of demo cards.

Proposed sections:

- **Dashboard:** real counts, upcoming services, unread care requests, publishing queue.
- **Announcements:** draft, schedule, publish, expiry, audience.
- **Events:** date, venue, registration/RSVP, reminders.
- **Media:** sermons and music, upload progress, rights, publish state.
- **Prayer and care:** private queue, assignment, follow-up status, no public leakage.
- **Members and Jumuiya:** scoped directories, role restrictions, data export.
- **Reports:** templates, filters, PDF issuance, audit.
- **Certificates:** issue, search, verify, revoke.
- **Engagement:** quiz content, challenges, moderation, leaderboard policy.
- **Settings and audit:** roles, integrations, retention, notification policy.

Tasks:

- [ ] Replace mock statistics with Firestore-backed queries and loading/empty/error states.
- [ ] Add pagination and server-side filtering for large lists.
- [ ] Add optimistic UI only where a failed write can be rolled back visibly.
- [ ] Add an unsaved-changes guard.
- [ ] Add role-based navigation and route guards.
- [ ] Add audit views for sensitive actions.
- [ ] Add export and print as secondary actions; PDF is primary.
- [ ] Add responsive layouts for tablet and phone use by leaders.
- [ ] Remove demo credentials and demo banners from production builds.
- [ ] Add accessible focus states, labels, and keyboard navigation.

### F2. Mobile completion

- [ ] Home: next service, daily verse, unread announcements, continue listening.
- [ ] Bible: search, bookmarks, notes, reading plans, real audio download state.
- [ ] Hymns: offline lyrics and audio where licensed.
- [ ] Sermons: in-app playback, download, transcript, series.
- [ ] Radio: favourites, buffering, retry, data-use warning.
- [ ] Events: details, add-to-calendar, reminders.
- [ ] Prayer: private submission, status, no public exposure.
- [ ] Growth: milestones, streaks, quiz history, badges.
- [ ] Profile/settings: language, notification preferences, privacy, clear data.
- [ ] Remove dead buttons and label incomplete features.
- [ ] Add deep links for announcements, sermons, events, and certificates.
- [ ] Add offline and sync status indicators.

### F3. Design system and accessibility

- [ ] Consolidate the navy/gold "sanctuary" language and the warmer portal palette into shared tokens.
- [ ] Use one type scale and one spacing scale.
- [ ] Audit colour contrast for small text and gold-on-navy combinations.
- [ ] Support dynamic text size without clipped buttons.
- [ ] Add semantics labels to icon-only controls.
- [ ] Respect reduced motion for decorative animation.
- [ ] Ensure touch targets are at least 44x44 logical pixels.
- [ ] Avoid glass effects that reduce readability on low-end devices.
- [ ] Test on a small Android phone and a low-RAM device.

### F4. Encoding and content repair

- [ ] Convert all source and docs to UTF-8 without replacement characters.
- [ ] Repair `README.md`, `CHURCH_PROFILE.md`, `STITCH_DESIGN_SYSTEM.md`, portal output strings, and affected mobile strings.
- [ ] Add a CI check for mojibake patterns (`Ã`, `Â`, `â€`, `ðŸ`, `\uFFFD`, `dY"`, `dY>`).
- [ ] Review Swahili copy with a fluent editor.
- [ ] Standardise names such as Jumuiya, Askofu, and Mbunge wa Jumuiya.
- [ ] Verify the bundled Bible translation's licence before public distribution.

---

## 12. Workstream G: Quality, performance, and operations (P3)

### G1. Testing

- [ ] Portal unit tests for auth guards, report filters, and data transforms.
- [ ] Portal component tests for critical forms and empty/error states.
- [ ] Playwright end-to-end tests for login, announcement publishing, report issue, and certificate verification.
- [ ] Firestore emulator rules tests for every role and collection.
- [ ] Mobile unit tests for sync, download state, quiz scoring boundary, and date handling.
- [ ] Mobile widget tests for navigation, offline states, and player controls.
- [ ] Integration tests for auth -> read -> write -> reconnect.
- [ ] A release smoke test on a physical Android device.

Current baseline: 7 Flutter tests, no portal tests, no rules tests. Use `dart analyze lib` in CI if `flutter analyze` is too slow on the first run.

### G2. Performance

Portal:

- [ ] Route-level code splitting and manual vendor chunks for Firebase, PDF, and editor modules.
- [ ] Remove ineffective dynamic imports and dead backup services.
- [ ] Convert hero and gallery images to WebP/AVIF with responsive sizes.
- [ ] Lazy-load below-the-fold content.
- [ ] Target < 350 kB initial gzip JS and LCP < 2.5 s on a mid-range Android phone over 4G.
- [ ] Run Lighthouse and Web Vitals checks in CI or a scheduled job.

Mobile:

- [ ] Parse large Bible JSON off the UI isolate if startup blocks.
- [ ] Use lazy lists and image caching.
- [ ] Compress bundled assets; remove unused artwork.
- [ ] Build an Android App Bundle and measure download size.
- [ ] Measure cold start on a low-end device.
- [ ] Cache network metadata and thumbnails.

### G3. CI/CD and environments

- [ ] Separate Firebase projects for development, staging, and production if the budget allows.
- [ ] Add GitHub Actions for portal build/lint/test, Flutter analyze/test, secret scanning, and rules tests.
- [ ] Protect `main`; require pull requests and passing checks.
- [ ] Deploy Firestore rules and indexes only after emulator tests.
- [ ] Deploy the portal to one hosting target; document the chosen target.
- [ ] Add preview deployments for review.
- [ ] Store deploy credentials in GitHub Secrets or workload identity, never in the repository.
- [ ] Add a rollback procedure for hosting, rules, and Functions.

### G4. Observability and support

- [ ] Firebase Crashlytics for mobile; Sentry or equivalent for portal errors.
- [ ] Log structured errors without prayer content or personal data.
- [ ] Add an error boundary and a recoverable "reload" state in the portal.
- [ ] Add uptime checks for the portal and certificate verification endpoint.
- [ ] Add Firestore backup/export and restore drills.
- [ ] Add cost alerts and a monthly budget cap for Gemini, Cloud Functions, and Cloudinary.
- [ ] Create a support runbook for password resets, publishing mistakes, and certificate revocation.
- [ ] Define who is on call during a service or event.

### G5. Release readiness

- [ ] Privacy policy, terms, and data-safety disclosures.
- [ ] Google Play internal testing and a signed App Bundle.
- [ ] Content and image rights verified.
- [ ] Accessibility review.
- [ ] Swahili copy review.
- [ ] Backup and restore verified.
- [ ] Incident contacts and escalation path.
- [ ] A release checklist signed by the church owner and technical lead.

---

## 13. Target data model

This is a starting contract; field names should be frozen only after the current UI and rules are mapped.

| Entity | Key fields | Sensitivity | Notes |
|---|---|---|---|
| `users` | uid, displayName, email, photo, locale, createdAt | Medium | Auth-linked only |
| `members` | memberId, name, contact, Jumuiya, status | High | Private; scoped reads |
| `jumuiya` | id, name, leaderIds, meeting info | Medium | Public directory only if approved |
| `announcements` | title, body, audience, publishAt, expiresAt, status | Low/Medium | Server-side moderation |
| `events` | title, start, end, venue, registration | Low | Public details |
| `sermons` | title, speaker, series, mediaUrl, downloadAllowed | Low | Rights metadata |
| `media_assets` | cloudinaryId, type, owner, rights, status | Medium | Orphans cleaned |
| `prayer_requests` | ownerId, body, visibility, status, assignedTo | High | Never public by default |
| `visitors` | name, contact, visitDate, followUpStatus | High | Restricted follow-up |
| `reports` | type, period, scope, issuedBy, pdfHash | High | Immutable snapshot |
| `certificates` | serial, recipientId, programme, issuedAt, status, hash | Medium | Public verification subset |
| `certificate_registry` | serial, status, type, issuedAt, hash | Low | Minimal public fields |
| `quiz_questions` | question, options, answerKey, reference, status | Medium | Answer key not public |
| `quiz_attempts` | uid, quizId, score, answers, createdAt | Medium | Server scored |
| `gamification_profiles` | uid, points, streak, badges, privacy | Medium | Owner/leader scoped |
| `challenges` | title, rules, window, evidenceType | Low | Moderated |
| `audit_logs` | actor, action, target, timestamp, diffHash | High | Append-only |

Conventions:

- Use server timestamps for official records.
- Use soft deletes plus a retention job for recoverable content.
- Every write records `createdBy` and `updatedBy`.
- Use version fields for offline conflict detection.
- Avoid duplicating PII into public collections.
- Do not store secrets, tokens, or full payment details.

---

## 14. Delivery sequence

Assumption: one full-stack/portal developer and one Flutter developer, part-time church review. Estimates are working weeks, not calendar promises.

| Phase | Duration | Main work | Exit gate |
|---|---:|---|---|
| 0. Stabilise | 1-2 days | Secrets removed, docs rewritten, repo sanitized, baseline verified | No secret tracked; clean build/test |
| 1. Identity and data | 2 weeks | Firebase Auth, claims, rules, emulator tests, real portal writes | Unauthorised access fails; leaders can publish safely |
| 2. Media and offline | 2-3 weeks | Audio session, downloads, media schema, radio/video, local DB | Lock-screen and airplane-mode tests pass |
| 3. Official documents | 2 weeks | PDF templates, certificate registry, QR verification, audit | A real certificate verifies from a phone |
| 4. Engagement | 2-3 weeks | Reading streaks, daily quiz, challenges, badges, moderation | Server-scored quiz and opt-in leaderboard pass abuse tests |
| 5. Launch readiness | 1-2 weeks | CI, monitoring, accessibility, store release, privacy, support | Release checklist signed |

**Critical path:** Phase 1 -> Phase 2 and Phase 3 in parallel -> Phase 4 -> Phase 5.

**Do not start Phase 4 (engagement) before Phase 1 is complete.** A server-scored quiz on top of unauthenticated data is worse than no quiz.

---

## 15. Definition of done

A feature is done only when all of the following are true:

- It has an owner and a written acceptance test.
- It works for its intended role and fails closed for everyone else.
- Loading, empty, offline, error, and permission-denied states are designed.
- It has automated coverage proportional to risk; security rules have tests.
- It does not expose secrets or unnecessary personal data.
- It works on a low-end Android device and a small screen.
- It has been reviewed for Swahili copy and accessibility.
- It has an audit event if it changes official or sensitive data.
- It has a rollback or recovery path.
- It is documented in the README or an operational runbook.

---

## 16. Immediate next actions

### First 48 hours

1. Rotate every Cloudinary and Gemini credential that was in source.
2. Create a staging Firebase project or confirm that production is not being used for tests.
3. Enable email/password Authentication and create the first real super-admin account.
4. Add the first rules test proving anonymous access is denied.
5. Verify that legacy browser storage cannot restore an old demo super-admin session.

### First week

6. Implement auth state, protected routes, and custom claims.
7. Move portal announcement, event, sermon, and media writes to authenticated repositories.
8. Remove the dev-only sync path from production code paths.
9. Surface write failures instead of catching them silently.
10. Add secret scanning and the existing build/analyze/test checks to CI.

### Second week

11. Complete the rules matrix and emulator suite.
12. Replace the audio player with `audio_service` + `just_audio` and test lock-screen playback.
13. Start the Drift schema and download manager.
14. Freeze the PDF report and certificate templates with the church.
15. Review the Bible and hymn content licences.

---

## 17. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Exposed keys are used before rotation | Financial loss, abuse | Rotate now, set quotas and alerts, scan history |
| Auth migration blocks demo users | Frustration, lost momentum | Build a clearly labelled demo mode; keep production separate |
| Firestore rules break existing screens | Data disappears | Emulator tests, staged rollout, explicit error states |
| Bible translation licence is unclear | Legal takedown risk | Verify licence before public distribution; use public-domain text if needed |
| Audio stops when Android backgrounds the app | Core feature failure | Foreground media service, physical-device tests |
| Large offline downloads fill storage | Crashes, bad reviews | Quotas, progress, delete controls, storage checks |
| Cloudinary/Gemini costs grow | Budget overrun | Server proxy, rate limits, budget alerts |
| Reports expose private data | Trust and legal damage | Server-issued snapshots, scoped access, minimal public verification |
| Quiz answer keys leak | Engagement integrity lost | Server-only answers, callable scoring, rate limits |
| Scope expands before foundations | Unfinished release | Phase gates, feature flags, non-goals |
| Content is inconsistent or untranslated | Low adoption | Named church editor, content calendar, review checklist |
| No one owns production support | Incidents linger | On-call rota, runbook, monitoring, backups |

---

## 18. Open decisions

These need a church owner, not only a developer:

1. Who owns the Firebase, Google Cloud, Cloudinary, and domains accounts?
2. Which Bible translation is licensed for offline distribution?
3. Which certificate types are official, and who may sign them?
4. What member data must be retained, and for how long?
5. Is online giving in scope? If yes, it needs a separate payment-security plan.
6. Is attendance tracking required? If yes, who verifies it and who can see it?
7. Will the app be Android-only for the first release, or is iOS required?
8. Which package name and Play Store account will be used?
9. Who moderates prayer requests, testimonies, quiz content, and leaderboards?
10. What is the monthly budget ceiling for Gemini, Cloud Functions, and media hosting?
11. Should leaderboards be public, group-only, or opt-in only?
12. Which deployment target is authoritative: Firebase Hosting or Vercel?

---

## 19. Change log

| Date | Change |
|---|---|
| 2026-10-20 | Initial production recovery plan; baseline audit; secret removal; repository documentation rewrite |
