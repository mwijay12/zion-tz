# FIREBASE SETUP — KWA MLIKILI (owner, local)

Phase 1 ya `docs/STRATEGY_AND_PHASES.md`: **mamlaka ya kweli inatoka Firebase Auth, si kwenye simu.**
Faili zote za upande wa server zimo hapa tayari; unabaki na hatua hizi za console/CLI.

Update ya mwisho: 2026-11-01 · Project: `zion-mbagala-church` (`.firebaserc`)

> **Hali ya sasa (2026-11-01):** Firebase Auth (Email/Password) imewashwa; Firestore rules
> na indexes zimepandishwa; super_admin wa kwanza `mwijaydavie@gmail.com`
> (UID `299b1c648f76361f3c223c1c`) ameundwa na claims `role=super_admin`,
> `branch=Mbagala Kwa Matope (HQ)`. Cloud Functions bado hazijapanda — project iko
> Spark; Blaze inahitajika. Bootstrap email allowlist imefungwa.

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
- **Email/Password** → Enabled (tayari imewashwa kupitia `firebase.json`)
- **Google** → imecheleweshwa; kitufe cha Google kwenye app kimefichwa hadi OAuth halisi (Phase 3)

### 2) Akaunti ya kwanza ya admin
Tayari imeundwa: `mwijaydavie@gmail.com` (UID `299b1c648f76361f3c223c1c`) na claims
`role=super_admin`, `branch=Mbagala Kwa Matope (HQ)`. Badilisha password ya muda mara moja:
Console → Authentication → Users → **Reset password**.

### 3) Deploy rules
```bash
cd <repo>
firebase deploy --only firestore:rules,firestore:indexes
```
Tayari imepandishwa; rudia kila unapobadilisha `firestore.rules`.

### 4) Deploy functions
**Bado imezuiwa:** project iko Spark. Upgrade hadi Blaze kwanza:
https://console.firebase.google.com/project/zion-mbagala-church/usage/details
Kisha:
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
Tayari imefanyika kwa `firebase auth:import` + `customAttributes` (haitegemei functions).
Kumbuka: `STANDARD_SCRYPT` inahitaji `--mem-cost=16384` (si `14`).

Kwa akaunti nyingine baada ya Blaze, tumia `functions/setUserRole`; kwa dharura unaweza
kurudia `auth:import` na `customAttributes` ya `role` + `branch`.

### 6) Thibitisha
1. Fungua programu → login na `mwijaydavie@gmail.com` → Profile → **Admin Dashboard**.
2. Juu unaona: `Mamlaka imethibitishwa na Firebase` ✅ (si `Mamlaka ya kifaa hiki`).
3. Hakikisha claims:
```bash
firebase auth:export users.json --project zion-mbagala-church
```
Angalia `customAttributes` ya user: `{"role":"super_admin","branch":"Mbagala Kwa Matope (HQ)"}`.
4. `role_grants` na `audit_logs` hazitakuwa na rows bado — functions hazijapanda (Blaze).

### 7) Kila siku (baada ya admin 1 kuwepo)
Admin Dashboard → **Ongeza Barua Pepe ya Admin (Grant Role)**:
- programu inapiga `setUserRole` → snackbar **kijani `✔`** = role iko kwenye Firebase.
- snackbar **manjano `⚠`** = build ya majaribio, imehifadhiwa kwenye kifaa peke.
- snackbar **nyekundu `✕`** = server imekataa; hakuna kitu kilicho wekwa. (Hakuna "fake success".)
- **Sasa:** `setUserRole` haipatikani hadi Blaze; grant role itashindikana kwa `⚠`/`✕`.

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

## 5. Bootstrap allowance — imefungwa

`church_auth_service.dart` sasa ina:

```dart
static const Set<String> _bootstrapOwnerEmails = <String>{};
```

Hakuna email inayopewa role ya kifaa. Kila mamlaka inatoka `request.auth.token.role`.
Akaunti ya kwanza iliumbwa kwa `auth:import` + `customAttributes` (tazama §3.5).

---

## 6. Mapungufu niliyobaki kuona (kwa hiari)

| Sura | Hali |
|---|---|
| `firebase_options.dart:41` — `ios.appId` ni appId ya **Android** | ⚠ sahihisha Console (iOS app) unapoweza; web/Android hazihudumii |
| `visitors_registry` / `prayer_requests` `allow create` bila login | ✅ Phase 2: consent ya wageni inahitajika; maombi ya sala hayabebwi kwenye `userId` ya mtu mwingine; maombi hayasomwi na umma |
| App Check | Phase 3 (lina weka usalama dhidi ya abuse ya functions) |
| `firebase hosting` ya `sayuni-portal` | Sasa inasoma custom claims; role switcher ya majaribio imeondolewa; iko live |
| GitHub PAT | Phase 3 — zisha token jipya (hii ilivuja kwenye git remote) |

---

## 7. PDPA/audit uthibitisho (hadi sasa)

- `role_grants` + `audit_logs` hazirishi client kuandika (`functions` tu) → hakuna kufuta alama.
  **Bado hazina rows** kwa sababu functions hazijapanda (Blaze).
- Kila grant ina `grantedBy`, `previousRole`, `newRole`, `reason`, `at`.
- `members/<uid>` ina `sourceOfTruth: 'firebase_auth_custom_claims'` — inaeleza kwamba
  document hii ni nakili ya ripoti, si chanzo cha mamlaka.
- Kuondoa mtumiaji: `revokeUserRole` (role → `member`) ; kisha Console → Delete account.
  Cloud-side erasure ya data zote = `functions/deleteMyData` (angalia §8).

---

## 8. PDPA (Phase 2) — unachotakiwa kufanya mwenyewe

### 8.1 Pakia kanuni + functions
Rules tayari zimepandishwa. Functions bado zinahitaji Blaze:
```bash
firebase deploy --only firestore:rules
# baada ya Blaze:
firebase deploy --only functions
```
Bila functions, programu bado inafanya kazi zake, lakini:
- idhini hajibikani kwenye `consent_records` (inakaa kwenye kifaa peke yake);
- "Pakia nakala ya data yangu" hatolei data ya wingu (inasema wazi "functions bado hazijapakiwa");
- "Futa akaunti" hufuta kifaa peke yake na inakuambia ukweli huo.

### 8.2 uthibitisho (baada ya deploy)
1. Ingia kama mwenye akaunti ya mgeni → Wasifu → *Haki zangu za PDPA* → chagua → **Nakubali idhini hii**
   (snackbar inatakiwa kusema "rekodi imetumwa kwenye wingu").
2. Console → Firestore → `consent_records` → lazima uone document yenye `uid`, `version: "2026.2"`,
   `purposes[]`, `acceptedAt`, `method`. Jaribu kufuta document hiyo kwenye app — kanuni zinakataa
   (`update, delete: if false`).
3. *Tengeneza nakala ya data* → JSON ina `dataController`, `consentRecords`, `deviceData`, `cloudData`,
   `processors`. Nakili inakopiwa kwenye clipboard (hakuna faili kwenye web).
4. *Futa akaunti* → Console → Authentication → user haipo tena; `audit_logs` ina `pdpa.erasure`.

### 8.3 Maamuzi ya kanisa (record-keeping)
- **Washirika (processors)** ambao lazima ukubali: Google (Firebase Auth + Firestore), Cloudinary,
  radio-browser.info (orodha za redio peke yake), Google Gemini (portal ya wasimamizi), na
  Lipa Namba (Vodacom/MiGAi/Airtel/CRDB). Orodha hii ndiyo inayoonekana kwa waumini (§7 ya faragha).
- **DPO / simu ya faragha**: weka namba halisi kwenye `ChurchProfile` na ukurasa wa faragha
  (sasa kuna `privacy@zionjerusalem.org` peke yake).
- **Usihifadhi PIN**: malipo yanakwenda moja kwa moja kwa Lipa Namba; hakuna kitu kwenye Firestore.
- **Utunzaji (retention)**: rekodi za fedha (aseli/michango/mapato/matumizi) hazifutwi na `deleteMyData`
  — sheria ya mapato na ukaguzi wa kanisa. Mtumiaji anaelekezwa hivyo kabla ya kuthibitisha.
