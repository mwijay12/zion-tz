# Audit 01 — Usalama (Security), PDPA na Firebase

Tarehe: 2026-10-27 · Kazi: `sayuni/` (82 files, 33,835 LOC), `sayuni-portal/`, `firestore.rules`, `firebase.json`
Kila kitu hapa kina **file:line** nilichothibitisha mwenyewe kwa `rg`/`sed` kwenye kodi ya sasa (HEAD `3752a55`).
Alama: **S1** = critical, **S2** = high, **S3** = medium, **S4** = low.

---

## S1-1 · Jukumu (role) halina chanzo halali — kila kitu ni SharedPreferences pekee

| Ushahada | Maelezo |
|---|---|
| `core/services/church_auth_service.dart:78-85` | `init()` inasoma `prefs.getString('auth_user_role')` na kuweka `_role = admin` |
| `:173-175` | `_grantedAdminEmails = {'admin@zionjerusalem.org'}` — hardcoded allowlist |
| `:210-212` | `signInWithGoogle()` anampa `admin` mtu yeyote aliye kwenye allowlist hiyo |
| `:337-363` | `loginAsLeader(role)` — `_role = ChurchUserRole.admin` bila authentication yoyote |
| `:180-189` | `grantAdminEmail()` inaandika `granted_admin_emails` kwenye prefs |
| `features/profile/presentation/church_admin_screen.dart:908` | UI ya "Gawa Mamlaka (Grant)" inaita `grantAdminEmail` |

**Kwa nini ni S1:** hakuna muhula kati ya "mtu huyu ni admin" na kitambulisho halali (Firebase UID). Kifaa chochote
kinaweza kuwa admin kwa kubadilisha pref, na `granted_admin_emails` **haiuliswi tena kamwe** (`init()` haisomi) —
kwa hivyo "grant" ya admin inadhamiri kufaulu kwenye screen lakini inapotea baada ya restart. Hii ni fake-success
ndani ya usalama.

## S1-2 · Firestore rules zinasimamwa kwenye custom claims ambazo hakuna kinazoweka

| Ushahada | Maelezo |
|---|---|
| `firestore.rules:50-57` | `getUserRole()`/`isAdmin()`/`isSecretary()` zote zinasoma `request.auth.token.role` |
| `sayuni/lib` (`rg setCustomUserClaims`) | **0** matokeo |
| `functions/` | **hakuna directory hiyo kabisa** |
| `sayuni/lib` (`rg signInAnonymously`) | 0 matokeo · `FirebaseAuth` inatumika mara 2 tu |

**Matokeo:** `isSecretary()`, `isPastor()`, `isDeacon()` **haviwezi kuwa true kamwe** — kwa hivyo
`visitors_registry` (PII), `prayer_requests` (pastoral), `jumuiya_reports` (fedha za jumuiya) havipatikani na
viongozi hata wakiwa wamesaini. Rules nzuri, lakini zimevunjwa kimuundo: kanisa haliwezi kutumia cloud.

## S2-1 · Njia ya kuingia admin bila Firebase inabaki wazi (demo fallback)

`church_auth_service.dart:265-291` — baada ya `signInWithEmailAndPassword` kushindwa, fallback inakubali
`ADMIN_DEMO_PASSWORD` (`String.fromEnvironment`, mstari 270) ikiwa `cleanUser` iko kwenye allowlist.
Bila `--dart-define` hiyo fallback haifanyi kazi, lakini ipo kwenye binary ya release na inaweza kuwashwa na
mtu anayejua jina la variable. Inapaswa kuwa ndani ya `kDebugMode` pekee.

Ndiyo maana `loginAsLeader` inaitwa kutoka `features/auth/presentation/onboarding_auth_screen.dart:959`,
ingawa kitengo chake kimefungwa na `if (_isDemo)` (`:25`, `:739`) ambapo
`_isDemo = kDebugMode || bool.fromEnvironment('DEMO_MODE')`. Binary ya release haionyeshi — lakini
`DEMO_MODE=true` inatosha kuiwasha tena. Hii ni "build-flag-dependent privilege", siyo ukaguzi wa kweli.

## S2-2 · PII inaweza kuandikwa na mtu yeyote yeyote (huna authentication)

| Ushahada | Tatizo |
|---|---|
| `firestore.rules:124-131` | `visitors_registry`: `allow create: if isValidVisitor(...)` — bila `isSignedIn()` |
| `firestore.rules:149-152` | `prayer_requests`: `allow create` bila authentication |
| `firestore.rules:110-113` | `announcements`: `allow read: if true` (sawa) lakini hakuna ukaguzi wa kina cha `branch` |

`isValidVisitor` inakubali `phone.size() >= 7` pekee. Hivyo bot inaweza kujaza rejista ya wageni (majina,
simu, makazi, mahitaji ya welfare) — ambayo ndiyo data nyeti zaidi katika kanisa. PDPA inahitaji udhibiti wa
fikiaji na usahihi (sura ya 5 na 6 ya PDPA 2022).

## S2-3 · `privacy_policy_screen.dart` inapingana na kodi

| Ushahada | Kinachosemwa | Kinachotokea kweli |
|---|---|---|
| `features/profile/presentation/privacy_policy_screen.dart:277,348` | "TLS/HTTPS encrypted" | `AndroidManifest.xml:34` `usesCleartextTraffic="true"`; sync service inatumia `http://` |
| `:278,349` | "Supabase" | Supabase ipo (`supabase_database_service.dart`) lakini **haitumiki** kwenye njia kuu; Cloudinary/Firebase/Gemini **haitajwi kamwe** |
| `:284,355,360` | "kufuta akaunti = kufuta data zote" | `deleteAccount()` (`church_auth_service.dart:305-334`) inafuta prefs za **kifaa hiki tu** — hakuna Firestore/auth delete |

Hii ndiyo hatari kubwa ya PDPA: **mawasiliano ya uwazi (transparency) siyo ya kweli**, na haki ya kufuta
(erasure, Second Schedule / sura ya 7) haitimizwi kwa upande wa cloud.

## S2-4 · Usafirishaji na siri

| Ushahada | Maelezo |
|---|---|
| `android/app/src/main/AndroidManifest.xml:34` | `android:usesCleartextTraffic="true"` — HTTP ikiwa wazi kwa domain zote |
| `core/services/church_sync_service.dart:333,453,566` | POST za `http://localhost:5173` **hazijazungushiwa `kDebugMode`**; timer (`:73`) ndiyo iliyolindwa tu |
| `sayuni-portal/vite.config.ts:19` | `Access-Control-Allow-Origin: *` kwenye `/api/sync/*` isiyo na authentication |
| `sayuni-portal/src/services/geminiAudioService.ts:24` | Gemini API key inakwenda kwenye browser bundle |
| `core/services/spiritual_wisdom_service.dart:34` | Gemini key kupitia `String.fromEnvironment` (sawa, ila inaweza kuwa empty → runtime failure) |
| `core/services/cloudinary_media_service.dart:126-128` | Cloud name/preset kupitia `--dart-define`; unsigned preset = hardcoded `zion-fellowship`-style fallback (config katika kodi) |
| `firebase_options.dart:38` | iOS `appId` inarudia ile ya Android — Firebase iOS config siyo sahihi |
| git remote | Token `github_pat_…` inavyoonekana kwenye remote URL ya zamani — inapaswa kubadilishwa (rotate) |

POST za localhost kushindwa kwa kimya ni "waste + cleartext attempt", siyo leak kubwa — lakini mchanganyiko wa
`usesCleartextTraffic` na CORS `*` ndiyo unaoacha mlango wazi kwa mtandao usio salama (hotel/public Wi-Fi).

## S3 · Vitu vya ngazi za chini

1. **`granted_admin_emails` inaandikwa tu, haisomiki** (`church_auth_service.dart:184-186` vs `init()` `:73-106`).
2. **Hakuna audit log** — hakuna kitengo cha `audit_logs`; `rg audit` kwenye `lib` = 0. Kanisa haliwezi kuonyesha
   "nani alibadilisha nini, lini" (fundamental ya fedha na PDPA).
3. **Hakuna consent record** — onboarding (`onboarding_auth_screen.dart`) hachukui idhini ya PDPA wala kuhifadhi
   `consentAt`/`consentVersion`.
4. **Hakuna data-subject access request** njia — "Omba nakala ya data yangu" haipo.
5. **`firestore.indexes.json`** haijashughulikia collection mpya za mapato/mali (Phase 6 zitahitaji).
6. **`firebase.json:3`** `public: "zion-portal/dist"` — folda halipo; portal iko `sayuni-portal/`. Hosting deploy itashindwa.
7. **Hakuna Firebase App Check** wala rate limit — API za kanisa wazi kwa abuse.

---

## Ndoto ya mwisho (target state) — ili Phase 1 na 2 zijenge juu yake

```
Firebase Auth (email/password + Google)  ──UID──►  ID token claims { role, branch, memberId }
                                                   ▲
                                      functions/setUserRole (Admin SDK, admin-only)
                                                   │
Firestore rules  ── reads request.auth.token.role ─┘        (S1-2 inafungwa hapa)
UI (Flutter)   ── ChurchRolePolicy.can(x) ── source: cloud | device | demo
```

Mamlaka yote mawili: **UI** (kifaa) na **rules** (cloud). UI inaweza kudhurufika na mtu mwenye uwezo wa pref —
kwa hivyo rules ndizo lazima zizuie. Phase 1 inazaweka zote mbili kwa pamoja.
