# FIREBASE SETUP — KWA MLIKILI (owner, local)

Phase 1 ya `docs/STRATEGY_AND_PHASES.md`: **mamlaka ya kweli inatoka Firebase Auth, si kwenye simu.**
Faili zote za upande wa server zimo hapa tayari; unabaki na hatua hizi za console/CLI.

Update ya mwisho: 2026-10-27 · Project: `zion-mbagala-church` (`.firebaserc`)

---

## 1. Kwa nini mambo haya yamebadilika

Kabla ya Phase 1 role ilisomwa kutoka `SharedPreferences` (`auth_user_role`). Yeyeye
aliye fungua DevTools au `localStorage` angeweza kuweka `admin`. Sasa:

```
simu (Flutter)                      server (uweka wewe)
──────────────                      ───────────────────
login → Firebase Auth  ───────────► ID token (inasainiwa na Firebase Auth)
getIdTokenResult(true)                    │
      │                                   ▼
      │                       request.auth.token.role   ← haiwezi kubadilishwa na client
      ▼                                   │
ChurchRolePolicy.can(...)                 ▼
(hii ni UI tu)                 firestore.rules / functions/index.js
```

Kanuni: **`profiles/<uid>.role` na `prefs` haviamuriwi kamwe.** Role peye inayoamini
ni `request.auth.token.role`, na hiyo inaandikwa peke na `admin.auth().setCustomUserClaims()`
ndani ya `functions/index.js`.

| Nini | Nani anaweza kukibadilisha |
|---|---|
| `prefs: auth_role_v2`, `auth_role_source` | kifaa chako peke (haingizi mamlaka yoyote) |
| `profiles/<uid>` | mtumiaji mwenyewe (bila `role`, bila `isVerifiedMember`) |
| `members/<uid>` | **functions / Console tu** (`allow write: if false`) |
| `role_grants/*`, `audit_logs/*` | **functions tu** (append-only, client haiwezi kuandika) |
| Custom claims (`role`, `branch`, `memberId`) | **`functions/setUserRole`** (admin) au Admin SDK |

---

## 2. Faili zilizoandikwa kwa ajili hii

| Faili | Kazi |
|---|---|
| `functions/index.js` | `setUserRole`, `revokeUserRole`, `myClaims` + trigger `members/{userId}` → claims |
| `functions/package.json` | Node 22, `firebase-admin ^14.5.0`, `firebase-functions ^7.4.0` |
| `functions/.env.example` | `ZION_REGION` (nakili kuwa `.env`) |
| `firestore.rules` | role kutoka token; `role_grants`/`audit_logs`/`members` server-only |
| `firebase.json` | hosting `sayuni-portal/dist`, functions source, cache + security headers |
| `.firebaserc` | default project |
| `sayuni/lib/core/services/church_role_policy.dart` | roles + permission matrix (source of truth ya UI) |
| `sayuni/lib/core/services/church_auth_service.dart` | claims → role, `RoleSource`, login/logout |
| `sayuni/lib/core/services/church_role_grant_service.dart` | client ya callable functions |

---

## 3. Hatua za local (muda takriban 25 min)

### 0) Pre-reqs
```bash
node -v              # lazima iwe 22.x
npm i -g firebase-tools
firebase login
firebase projects:list | grep zion
```
> **Blaze (pay-as-you-go) inahitajika** kwa Cloud Functions. Plans za bure (Spark) hairuhusu functions.

### 1) Auth providers
Console → **Build → Authentication → Get started → Sign-in method**:
- **Email/Password** → Enabled
- **Google** → Enabled (chagua email ya kanisa kama support email)

### 2) Kuunda akaunti ya kwanza ya admin
Console → Authentication → **Add user**:
- email: `admin@zionjerusalem.org` (au email yako ya kweli)
- password: 14+ chars, tofauti na ile ya demo

### 3) Deploy rules
```bash
cd <repo>
firebase deploy --only firestore:rules
```

### 4) Deploy functions
```bash
cd functions && npm install && cp .env.example .env && cd ..
firebase deploy --only functions
```
Kosa la region (`africa-south1` haipatikani kwenye project yako)?
1. `functions/.env` → `ZION_REGION=us-central1`
2. build upya: `flutter build web --release --dart-define=FUNCTIONS_REGION=us-central1`
   (`ChurchRoleGrantService.region` inasoma `--dart-define=FUNCTIONS_REGION`)
3. `firebase deploy --only functions`

### 5) Bootstrap: admin wa kwanza (`super_admin`)
Hakuna admin bado, kwa hivyo `setUserRole` haiwezi kuitwa. Chagua **moja**:

**A) Njia rahisi — Console + trigger (inayopendekezwa)**
1. Console → Firestore → Start database (**production mode**, region `eur3` au `us-central1`)
2. Unda collection `members`, document ID = **UID** ya admin (UID unaipata kwenye Authentication → Users → UID)
3. Fields: `role` (string) = `super_admin`, `branch` = `Mbagala Kwa Matope (HQ)`
4. Trigger `mirrorMemberDocumentIntoClaims` itaenda ndani ya sekunde ~20: itaweka claims, kuandika `audit_logs`, na kuandika `previousRole` kwenye document.

**B) Njia ya CLI (hakikisha)**
```bash
node -e "const admin=require('firebase-admin');admin.initializeApp();admin.auth().setCustomUserClaims(process.argv[2],JSON.parse(process.argv[1])).then(()=>console.log('claims OK'))" '{"role":"super_admin","branch":"Mbagala Kwa Matope (HQ)"}' <UID>
```
(Hii inahitaji `GOOGLE_APPLICATION_CREDENTIALS` au `gcloud auth application-default login`.)

**C) Emulator ( bila mtandao)**
```bash
firebase emulators:start --only functions,firestore,auth
```

### 6) Thibitisha
1. Fungua programu → login na email hiyo → Profile → **Admin Dashboard**.
2. Juu unaona: `Mamlaka imethibitishwa na Firebase` ✅ (si `Mamlaka ya kifaa hiki`).
3. Terminal:
```bash
curl -s -X POST "https://africa-south1-zion-mbagala-church.cloudfunctions.net/myClaims" -H "Content-Type: application/json" -H "Authorization: Bearer <ID_TOKEN>" -d '{"data":{}}'
```
Unatarajia `{"result":{"role":"super_admin", ...}}`.
4. Firestore → `role_grants` na `audit_logs` lazima ziwe na rows.

### 7) Kila siku (baada ya admin 1 kuwepo)
Admin Dashboard → **Ongeza Barua Pepe ya Admin (Grant Role)**:
- programu inapiga `setUserRole` kwanza → snackbar **kijani `✔`** = role iko kwenye Firebase.
- snackbar **manjano `⚠`** = build ya majaribio, imehifadhiwa kwenye kifaa peke.
- snackbar **nyekundu `✕`** = server imekataa; hakuna kitu kilicho wekwa. (Hakuna "fake success".)

---

## 4. Role halali (ziwe sawa kila mahali)

`wireName` (claim) · jina la Kiswahili · ranking · mamlaka kuu

| claim | jina | rank | mamlaka kuu |
|---|---|---|---|
| `guest` | Mgeni wa Heshima | 0 | maombelo, kujisajili |
| `member` | Muumini wa Sayuni | 10 | + giving history yake |
| `jumuiya_leader` | Kiongozi wa Jumuiya | 20 | + jumuiya reports |
| `choir_leader` | Kiongozi wa Kwaya | 20 | + kwaya media |
| `children_teacher` | Mwalimu wa Watoto | 20 | + sunday school content |
| `treasurer` | Mehani wa Kanisa | 30 | + kurekodu mapato, report za fedha |
| `deacon` | Mzee wa Kanisa | 40 | + visitors registry |
| `secretary` | **Katibu wa Kanisa** | 50 | + members, mali, minutes, announcements, mapato |
| `pastor` | Mchungaji | 60 | + media ya mahubiri, pastoral prayers, kuidhinisha matumizi |
| `admin` | Msimamizi Mkuu | 70 | + settings, kugawa role (si `super_admin`) |
| `super_admin` | Msimamizi wa Mfumo | 80 | yote |

Tatu lazima zibaki zinazo endana: `church_role_policy.dart` · `firestore.rules` · `functions/index.js`.

---

## 5. Bootstrap allowance — na jinsi ya ku izima

Kwa sasa `church_auth_service.dart` ina:

```dart
static const Set<String> _bootstrapOwnerEmails = {'admin@zionjerusalem.org'};
```

Sababu: kabla ya functions kudeploy, kungoja claims tu kungefanya **preview yote isifanye kazi**
(na kila refresh ingemtoa nje). Account iliyo orodha hii hupewa role ya device **na**
lebo `roleSourceLabel` ina onyesha `Mamlaka ya kifaa hiki — haijathibitishwa`.

**Ukisha maliza hatua 5–6 za juu, ifunge:**
```dart
static const Set<String> _bootstrapOwnerEmails = <String>{};
```
`dart analyze` → build mpya. Kisha kila mamlaka itatoka claims peke yake.

---

## 6. Mapungufu niliyobaki kuona (kwa hiari)

| Sura | Hali |
|---|---|
| `firebase_options.dart:41` — `ios.appId` ni appId ya **Android** | ⚠ sahihisha Console (iOS app) unapoweza; web/Android hazihudumii |
| `visitors_registry` / `prayer_requests` `allow create` bila login | Phase 2 (PDPA) — lazima consent + rate limit kwanza |
| App Check | Phase 3 (lina weka usalama dhidi ya abuse ya functions) |
| `firebase hosting` ya `sayuni-portal` | Portal bado ina localStorage; Phase 9 |
| GitHub PAT | Phase 3 — zisha token jipya (hii ilivuja kwenye git remote) |

---

## 7. PDPA/audit uthibitisho (hadi sasa)

- `role_grants` + `audit_logs` hazirishi client kuandika (`functions` tu) → hakuna kufuta alama.
- Kila grant ina `grantedBy`, `previousRole`, `newRole`, `reason`, `at`.
- `members/<uid>` ina `sourceOfTruth: 'firebase_auth_custom_claims'` — inaeleza kwamba
  document hii ni nakili ya ripoti, si chanzo cha mamlaka.
- Kuondoa mtumiaji: `revokeUserRole` (role → `member`) ; kisha Console → Delete account.
  Cloud-side erasure ya data zote = Phase 2.
