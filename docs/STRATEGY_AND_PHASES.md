# Sayuni / Zion Jerusalem — Mkakati wa Kuimarisha App (10 Phases)

Tarehe: 2026-10-27 · Msingi: `docs/audit/01..03` (ushahada wa file:line) · HEAD `3752a55`
Lengo la mmiliki: **"fast, digital, safe, bila friction — hata kwa PDPA, maana hii ni ya kanisa;
kumanage mali za kanisa na mapato kwa Katibu; Firebase iwe well (setup ya mwisho nitaifanya locally)."**

Jinsi ya kutumia: kila Phase inakamilika yenyewe (build mpya → push → link mpya ya Cloudflare).
Mmiliki anasema **"next"** ndipo Phase inayofuata huanza.

---

## A · Kanuni zisizobadilika (guiding principles)

| # | Kanuni | Maana yake kwa uamuzi |
|---|---|---|
| K1 | **Ukweli kuliko uzuri** | Hakuna toast ya majani ikiwa kitu hakikufanyika. Kosa huonekana kwa Kiswahili + **Jaribu Tena**. |
| K2 | **Cloud ndiyo chanzo, kifaa ni cache** | Data ambayo Kanisa (siyo mtu mmoja) anahitaji haiishi kwenye SharedPreferences. |
| K3 | **Fedha = integer cents** | `amountCents:int`, TZS. Hakuna `double`, hakuna `Date.now()` ID. |
| K4 | **Rekodi hazifutwi** | Makosa ya fedha hurekebishwa kwa `reversesId`, sio `delete`. Kila kitendo → `audit_logs`. |
| K5 | **PDPA ni default, sio page** | Idhini (consent) huhifadhiwa; data ndogo iwezekanavyo; fikiaji/marekebisho/kufuta hufanyika kweli. |
| K6 | **Usalama haupaswi kuongeza msuguano** | Msimamizi anatumia simu yake kawaida; mamlaka yatolewa na mfumo, siyo kila siku kuingia tena. |
| K7 | **Usivunje vilivyopo** | Bible, navigation, audio (background/lock-screen), Cloudinary uploads, theme moja (Sayuni Blue + light/dark) — hakikishwa kila Phase. |
| K8 | **Ongeza polepole, kipime** | Kila Phase ina `Acceptance test` inayoweza kuonekana. Hakuna "nimefanya" bila ushahada (HTTP 200 + md5). |
| K9 | **Msimamizi wa nyumba (Firebase console) ni mmiliki** | Mimi naandaa kodi + rules + functions + orodha ya hatua (`docs/FIREBASE_SETUP_OWNER.md`); kazi za console unazifanya wewe. |

---

## B · Rejista ya mashimo (severity-ranked hole register)

Namba fupi: `S#` = security/PDPA/Firebase, `L#` = mantiki, `P#` = performance/ops. Maelezo kamwe: audit docs.

| ID | Shimo | Ukubwa | Phase |
|---|---|---|---|
| S1-1 | Jukumu (admin/leader) linatoka prefs pekee; `loginAsLeader` hupa admin bila auth (`church_auth_service.dart:337`) | S1 | 1 |
| S1-2 | Rules zinasoma `auth.token.role` (`firestore.rules:51,52,57`) lakini `setCustomUserClaims` = 0, hakuna `functions/` | S1 | 1 |
| S2-2 | `visitors_registry`/`prayer_requests` `allow create` bila sign-in (PII) | S2 | 2 |
| S2-3 | `privacy_policy_screen.dart:277-284,348-360` inasema Supabase+TLS, haitaji Cloudinary/Firebase/Gemini; `deleteAccount()` inafuta prefs tu | S2 | 2 |
| S2-4 | `usesCleartextTraffic=true` (`AndroidManifest.xml:34`); localhost POST (`church_sync_service.dart:333,453,566`) hazijalindwa `kDebugMode`; portal CORS `*`; Gemini key kwenye browser | S2 | 3 |
| S2-1 | Demo paths zinaweza kuwashwa kwa `--dart-define` kwenye release | S2 | 3 |
| L1-1 | 110 catch, 44 `catch (_)`, 28 tupu — makosa yanamezwa | L1 | 4 |
| L1-2 | 16 spinners, 0 timeouts kwenye sync/radio/supabase = loading ya milele | L1 | 4 |
| S3-1 | Hakuna `audit_logs`, hakuna consent record, hakuna data-subject access | S3 | 2 |
| L2-1 | `zion_prayer_requests` inashirikiwa services mbili (schema collision); `flutter.` duplicates; `granted_admin_emails` write-only | L2 | 5 |
| L2-2 | 14 × IDs kutoka `millisecondsSinceEpoch` → mgongano wa double-tap | L2 | 5 |
| L2-3 | `amount` ni `double` (fedha) | L2 | 6 |
| **OPS-1** | **Hakuna mapato (income) kwenye cloud** — `zion_giving_records` prefs tu | **S1** | 6 |
| **OPS-2** | **Hakuna mali za kanisa (asset register) kabisa** | **S1** | 6 |
| OPS-3 | Hakuna members directory, attendance, vibari/receipt numbers, mikutano/maazimio | S2 | 6 |
| P2-1 | Bible JSON 16.6 MB + `json.decode` kwenye UI isolate; tafsiri 2 kwa mpigo | P2 | 7 |
| P2-2 | `web/index.html` hakuna preload; boot ndefu (9 awaits) | P2 | 7 |
| P3 | `Image.network` bila cache, `google_fonts` mtandaoni, filter ndani ya `build()` | P3 | 7 |
| OPS-4 | `PDFService` 0 call sites; hakuna CSV → Katibu hana ripoti | S2 | 8 |
| OPS-5 | Portal finances/expenses/projects `useState` kutoka mock; role = `email.includes('admin')` | S2 | 9 |
| QA-1 | Hakuna dev/prod config, hakuna smoke test, hakuna error reporting | S3 | 10 |

---

## C · Phases 1–10

Kila Phase: **Lengo · Kazi · Faili · Jaribio la kukubali (acceptance test) · Kazi za mmiliki · Ushahada wa kumaliza.**

---

### PHASE 1 — Misingi ya utambulisho: Auth, Majukumu & Firestore claims
**Lengo:** "nani" na "je, anaweza nini" viwe na chanzo kimoja halali; rules ziweze kufanya kazi.
**Hali:** ✅ IMEKAMILIKA (code + rules + functions + docs). Kazi ya console imebaki kwa mmiliki →
`docs/FIREBASE_SETUP_OWNER.md`. Dashboard sasa huonyesha banner ya chanzo cha mamlaka
(`roleBadge` + `roleSourceLabel`), na kitufe cha Media Hub kimehamishiwa kwenye
`canUi(ChurchPermission.uploadSermonMedia)`.
**Kazi**
1. `core/services/church_role_policy.dart` **(mpya)**: `ChurchRole` kamili (guest, member, jumuiyaLeader,
   choirLeader, childrenTeacher, deacon, treasurer, secretary, pastor, admin, superAdmin), `RoleSource`
   (`cloud | device | demo`), permission matrix (`canUploadMedia`, `canManageFinance`, `canManageAssets`,
   `canManageMembers`, `canGrantRoles`, …) — ramani 1:1 na `firestore.rules`.
2. `church_auth_service.dart`: anza kwa Firebase session (`currentUser` + `getIdTokenResult().claims['role']`);
   claims **daima** hushinda cache; kama Firebase haijapangwa, role inabaki `device`/`demo` na UI huonyesha
   chanzo; njia za kujipa mamlaka (loginAsLeader, demo password, grantAdminEmail, signInWithGoogle→admin)
   zifungwe nje ya `kDebugMode`.
3. `functions/index.js` + `functions/package.json` **(mpya)**: `setUserRole` (callable, admin tu, Admin SDK
   `setCustomUserClaims`) + `onMemberCreate` huweka claims kutoka `members/{uid}`.
4. `firestore.rules`: `requireClaim()` imara; `role_grants`/`audit_logs` = server-only (`allow write: if false`);
   maelezo ya wazi kuhusu claims.
5. `firebase.json`: `public` sahihi (`sayuni-portal/dist`) + headers za cache.
**Faili:** `church_role_policy.dart`, `church_auth_service.dart`, `onboarding_auth_screen.dart`,
`church_admin_screen.dart`, `firestore.rules`, `firebase.json`, `functions/*`, `docs/FIREBASE_SETUP_OWNER.md`
**Acceptance test:** release web build: hakuna kitufe kinachoweza kupa admin bila Firebase session;
`setUserRole('katibu@…','secretary')` → Firestore read ya `visitors_registry` inafaulu (ilikuwa `permission-denied`).
**Kazi zako:** `firebase login`, `apps:create` (auth user), `deploy --only functions,firestore:rules` → orodha kamili
ipo `docs/FIREBASE_SETUP_OWNER.md`.
**Ushahada:** `dart analyze` 0 errors + build mpya + link + HTTP 200 `/` & `/main.dart.js` + md5 sawa.

---

### PHASE 2 — PDPA 2022: idhini, kufikia, kufuta, na ukweli wa faragha
**Lengo:** kanisa liwe legal bila kuongeza msuguano kwa waumini.
**Kazi:** consent record (`consent{version,at,channels[]}` kwenye `members`); kituo cha **Consent** (PDPA
swahili/English) kwenye onboarding; **DSAR** — "Pakia nakala ya data yangu" (JSON export ya data yake) na
"Futa akaunti yangu" inayofuta **cloud** (Function `deleteMyData`) siyo prefs tu; `privacy_policy_screen.dart`
ikae ukweli: Cloudinary (media hosting), Firebase/Google (auth+db), Gemini (AI maswali), radio-browser (vituo)
+ kila mmoja anachohifadhi na kwa nini + simu za kuwasiliana; visasihishwi data nyeti (kama `welfareNeeds`)
kitengo cha public.
**Acceptance test:** "Pakia nakala" inatoa JSON yenye data yangu; "Futa" → `members/{id}` haipo baada ya 60 s
(au kazi ya mmiliki imeorodheshwa); maandishi ya faragha yanalingana na `rg` ya services.
**Kazi zako:** kubali kuwa Cloudinary/Firebase processor + kuweka namba ya simu ya Data Protection Officer.

**✅ IMEKAMILIKA (2026-10-27):**
- `core/services/pdpa_service.dart` — register ya idhini (append-only, kwenye kifaa), purposes 5:
  `membership`, `contact`, `prayer`, `giving`, `media` (lazima: membership + giving), `withdrawAll()`,
  `exportJson()` (DSAR), `dataInventory` (SW + EN) na `mirrorActiveToCloud()` → Firestore `consent_records`.
- `features/profile/presentation/pdpa_rights_screen.dart` — kituo kimoja cha haki: **Idhini · Kufikia ·
  Washirika · Kufuta**; hujitokeza kwenye onboarding (`maybeAsk`) na kwenye Wasifu; hakuna kitu kilichojazwa
  peke yake (rekodi huandikwa tu mtu akibofya).
- `privacy_policy_screen.dart` toleo **2026.2**: Supabase/RLS uongo umeondolewa; §6 inasema ukweli wa kufuta
  (rekodi za fedha hazifutwi — sheria ya mapato); §7 (washirika) inazalishwa na `dataInventory` yenyewe.
- `firestore.rules` (270 mistari): `consent_records` append-only + `isValidConsent`; wageni wanahitaji
  `consent == true`; `prayer_requests` haionekani tena ulimwengoni; `isValidPrayerRequest` imeimarika
  (`.size()` kwenye field isipo ilikataza kuandika).
- `functions/index.js`: `exportMyData` (PDPA access) na `deleteMyData` (PDPA erasure, audit `pdpa.access` /
  `pdpa.erasure`, hauruhusu kujifuta wenyewe kwa role kuu).
- Stub ya Supabase imefutwa (`supabase_database_service.dart`) — haukufanyia mtandao kamwe.
- **Ushahada:** `dart analyze lib` = 0 errors / 0 warnings · build mpya ya `web/release` · HTTP 200 kwenye `/`
  na `/main.dart.js` · md5 ya faili iliyohudumishwa = md5 ya faili ya ndani.

**Bado kwa mmiliki:** `firebase deploy --only functions,firestore:rules` · kukubali Cloudinary/Firebase/Gemini/
radio-browser kama washirika · kuweka namba halisi ya DPO · (`consent_records` haihitaji index — ni create-only).

---

### PHASE 3 — Siri, usafirishaji na mipaka ya build (secrets & transport)
**Lengo:** hakuna HTTP wazi, hakuna key kwenye bundle, hakuna demo backdoor kwenye release.
**Kazi:** `usesCleartextTraffic` → `false` (na `network_security_config` inayoruhusu `localhost`/`10.0.2.2`
debug-only); gate kila `http://localhost:5173` call kwa `kDebugMode` (dev-bridge helper); Gemini key iondole
kwenye browser bundle (`geminiAudioService.ts`) ikimeurukia kwenye Function proxy; Cloudinary config iwe
`--dart-define`/remote config isiyo na fallback ya cloud nyingine; portal `/api/sync/*` ipewe shared-secret
header na CORS ibaki `localhost` pekee; ondoa `ADMIN_DEMO_PASSWORD` fallback kwenye release; **rotate GitHub
token** iliyonekana kwenye remote.
**Acceptance test:** `grep -r "http://" build/web/main.dart.js` (release) haitoi localhost bridge; Android release
install haipiti cleartext; portal haikubali POST isiyo na secret.

---

### PHASE 4 — Uvumivu: makosa yanayoonekana, hakuna kuzungusha milele
**Kazi:** kanuni ya catch (debugPrint + user-facing error + Retry) kwenye services zote; timeouts kote
(`sync`, `radio`, `supabase`, `bible`); `ErrorState`/`RetryButton` ya design system moja; `mounted` guards +
`Timer`/`StreamSubscription` cleanup kila `dispose()`; hakuna spinner isiyo na deadline; "offline banner"
badala ya empty screens.
**Acceptance test:** zima intaneti → kila rail ina kosa + Jaribu Tena, hakuna spinner ya >15 s; `catch (_)` = 0
kwenye `lib/core/services`.

---

### PHASE 5 — Chanzo kimoja cha data ya ndani (single source of truth)
**Kazi:** `core/storage/app_prefs.dart` — keys zote, readers/writers walio wazi, schema version +
migration; tatua `zion_prayer_requests` collision (jumuiya vs sync), ondoa `flutter.` duplicates kwa
kuweka `reader` yenye fallback ya key ya zamani; `granted_admin_emails` isebaki (Phase 1 imeshafanya) —
badala yake `role` claims; `core/utils/uid.dart` (`uuid+ts`) inayobadilisha tovuti 14 za epoch-ID.
**Acceptance test:** data ya zamani (uploads, prayers, visitors) inasomeka baada ya upgrade kwenye simu
ileile; hakuna key inayoandikwa na files mbili; hakuna `millisecondsSinceEpoch` ID.

---

### PHASE 6 — ❤️ Mapato, Mali na Utawala kwa Katibu (church-ops data model)
**Lengo:** Kanisa lipate uwezo wa kweli wa kusimamia fedha na mali — cloud, role-safe, PDPA-safe.
**Kazi**
1. Firestore schema (Audit 03 §5): `members`, `attendance`, `income_records`, `expense_records`, `assets`,
   `receipt_sequences`, `minutes`, `audit_logs` + `firestore.indexes.json`.
2. Rules kwa jukumu: Mwanachama (yeye tu), Katibu (members/minutes/read-all-ledger), Mehani (fedha
   create/update-reverse), Kasisi/Admin (yote + approve), kikomo cha `branch`.
3. `core/money.dart`: `Money` (cents, TZS formatting `1,250,000/-`), parsing, rounding, totals.
4. Repositories + Firestore writes: `income_service.dart`, `expense_service.dart`, `asset_service.dart`,
   `member_service.dart`, `attendance_service.dart`, `minutes_service.dart`.
5. UI (design system ileile, Kiswahili): **Dashibodi ya Katibu**, **Mapato** (toleo la kila Juma, asjari,
   building, welfare + mwezi/mwaka), **Matumizi** (voucher + idhini 2), **Rejista ya Mali** (hali, mlezi,
   matengenezo), **Mahudhuriano**, **Mikutano & Maazimio**. Mehani anapokea idhini ndani ya app.
6. Vibari: `receiptNo` kutoka `receipt_sequences` (atomic) — mfano `ZJC/TITH/2026/000123`; hakuna edit/delete.
**Acceptance test:** Mehani anaingia → anaona tu fedha; Katibu anaongeza mapato → yanatokea kwenye ripoti ya
mwezi na portal; double-tap haionei rekodi mbili; vibari havibadiliki; `audit_logs` ina kila kitendo.
**Kazi zako:** `firebase deploy --only firestore` (indexes + rules), kisha `setUserRole` kwa Katibu na Mehani.

---

### PHASE 7 — Kasi: boot, Bible na picha
**Kazi:** `web/index.html` + preload hints; ondoa SQLite isiyotumika (`main.dart:57-62`, `sqlite3.wasm` 706 KB);
Bible JSON ipunguzwe (index ndogo + per-book lazy chunks) na `json.decode` iende kwenye isolate; tafsiri moja
kwa wakati; `cached_network_image` + `cacheWidth`; fonts bundled; list builders + debounced search; memoise
media filters; ondoa 4 ya assets zisizotumika (1.03 MB).
**Acceptance test:** `build/web` jumla imepungua (lengo ≤ 45 MB), `main.dart.js` hapai; first screen < 3 s kwenye
4G simulated; hakuna jank wakati wa kusogeza Bible.

---

### PHASE 8 — Ripoti za Katibu: CSV + PDF
**Kazi:** `export_service.dart` (CSV sanifu kwa Excel TZ); PDF kwa `pdf_service.dart` (orphan sasa):
Ripoti ya Mapato/Matumizi ya mwezi/mwaka wa fedha, Rejista ya Mali, Taarifa ya Mkutano, Ledger ya Vibari —
yenye logo, tarehe, `generatedBy`, na signature za Mchungaji/Katibu/Mehani; share/save kwenye kifaa.
**Acceptance test:** PDF ya mwezi inafunguka na jumla zinalingana na `sum(amountCents)`; CSV inafunguka
kwenye Excel bila korofi.

---

### PHASE 9 — Portal ya Kanisa iwe halisi (state + role + persistence)
**Kazi:** `sayuni-portal` ihifadhi data (Firestore au `sayuni-portal/server` DB) badala ya `useState` mock
(`App.tsx:39-43`); `authService.ts` ikubali role kutoka Firebase session (siyo `email.includes('admin')`);
`FinanceModule.tsx` iende kwenye cents na namba za vibari za `receipt_sequences`; `/api/sync/*` secret +
CORS sahihi; portal ionyeshe **sawa** na app (single source of truth), ikiwemo mali na mapato.
**Acceptance test:** data imeandikwa kwenye portal → inaonekana kwenye app baada ya refresh; role ya uongo
haiwezi kuingia dashboard ya fedha.

---

### PHASE 10 — Kuganda, Ubora na Uandikishaji (hardening, QA, release)
**Kazi:** `--dart-define` configs za dev/prod (`AppConfig.fromEnvironment`); smoke-test suite (auth, uploads,
Bible, audio, mapato); `flutter analyze` + `dart format` katika kila delivery; Crash/error reporting
(Firebase Crashlytics) ikiwa ni salama kwa PDPA; docs: `docs/OPERATIONS.md` (jinsi ya kusimamia kila siku),
`docs/DATA_MODEL.md` (kamili), `docs/PDPA_CHECKLIST.md`; `README` + `PLAN.md` zimesasishwa.
**Acceptance test:** `flutter test` inapita; dev↔prod hazichanganyiki; mkondoni mwa mmiliki wa Firebase umeanza
kufanyika kwa mafanikio (angalia `FIREBASE_SETUP_OWNER.md` checkboxes).

---

## D · Mpangilio wa kazi na utegemezi

```
1 Auth/roles/claims ──┬─► 2 PDPA (inahitaji auth + delete function)
                      ├─► 3 Secrets/transport
                      └─► 6 Church-ops model ──┬─► 8 Reports/CSV/PDF
4 Resilience ─────────►┘                        └─► 9 Portal persistence
5 Storage single-source ──────────────────────────► 6
7 Performance (huru, baada ya 4) ─► 10 Hardening/QA (mwisho)
```

Phases 4/5/7 zinaenda sambamba na 2/3 — lakini kwa sababu ya "next" moja baada ya nyingine,
mpangilio wa namba juu ni ndio tutakaoufuata.

## E · Mambo yasiyoguswa (K7)
Audio (background/lock-screen/NowPlaying), Cloudinary uploads, Bible navigation, tafsiri, theme moja
(Sayuni Blue, light/dark), Swahili UI, Cloudflare preview workflow — hakikishwa kila Phase kabla ya delivery.

## F · Orodha ya makubali yaliyobaki kwa mmiliki
1. Kazi za Firebase console (Phase 1/6/10) → `docs/FIREBASE_SETUP_OWNER.md`.
2. Kubali test-upload ya kweli kwenye Cloudinary `zion-fellowship` (nitajiuliza kabla).
3. Cloudinary presets + CORS kwa domain ya mwisho ya portal.
4. Rotate GitHub PAT + weka token nje ya git remote URL.
5. Jina na namba ya simu ya **Data Protection Coordinator** wa kanisa (kwa faragha page).
