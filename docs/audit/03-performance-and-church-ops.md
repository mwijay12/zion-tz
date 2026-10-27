# Audit 03 — Kasi (performance) na Uendeshaji wa Kanisa (church ops)

Tarehe: 2026-10-27 · vipimo vyote nilivipima mwenyewe (python/`stat`) kwenye `sayuni/build/web` ya build mpya.
Alama: **P1** critical · **P2** high · **P3** medium · **P4** low.

---

## 1 · Uzito wa bundle (vipimo halisi)

| Artifact | Ukubwa |
|---|---|
| `main.dart.js` | **3,939,509 B** (md5 `dbf89c27ee297a5f914020b0c2a89226`, deterministic) |
| `canvaskit/canvaskit.wasm` | 6,751,354 B |
| `canvaskit/chromium/canvaskit.wasm` | 5,372,643 B |
| `skwasm.wasm` | 3,223,359 B |
| `assets/NOTICES` | 1,864,248 B |
| `sqlite3.wasm` | 706,316 B |
| **`build/web` jumla** | **≈ 58.9 MB** |

Bible JSON zinapakindwa kama web assets: `bible/web.json` 5.1 MB · `kjv.json` 5.1 MB ·
`full_version.json` 4.8 MB · `agano_jipya.json` 1.6 MB ≈ **16.6 MB**.

`web/index.html` **haina preload hints** (`rg preload web/index.html` = 0) — kivinjari huanza kupakia
`canvaskit.wasm` baada ya `main.dart.js` tu, hivyo boot ni sequential badala ya parallel.

## 2 · Assets — ukweli vs. ucashfu

- Jumla: **162 faili, 41,697,555 B**.
- Zisizotumika kwenye kodi: **4 faili = 1,031,911 B (2.0%)** — `app_icon.jpg` 642,716 · `3d_branches.png` 355,843 ·
  `bible_hero.png` 23,045 · `bible_index.json` 10,307.
- ❗ **Sahihisho:** ukaguzi wa awali ulisema "138/162 (~27 MB) hazitumiki". **Si kweli** — kipimo halisi ni 2%.
  Kwa hivya Phase ya performance haitakuwa "kufuta assets", bali **kugawanya Bible JSON** (16.6 MB ndiyo mzigo halisi).

## 3 · P2 · Mantiki ya UI inayong'oya frame

| Mahali | Tatizo | Suluhisho |
|---|---|---|
| `features/bible/services/bible_service.dart:30,55,58,77` | `rootBundle.loadString` + `json.decode` ya faili zima kwenye **UI isolate** | `compute()`/isolate + index ndogo ya chapter, lazy per-book |
| `features/bible/presentation/bible_screen.dart:383-399` | inapakia tafsiri **mbili** + nyimbi kwa wakati mmoja | pakia moja; nyingine on-demand |
| `features/media/presentation/media_hub_screen.dart:189-200` | `where()`/`sort` ndani ya `build()` — kila rebuild | memoise kwenye `_filtered` getter |
| `features/search/universal_search_sheet.dart:335-375,:667` | utafauti kwenye kila keypress | 250 ms debounce + `ListView.builder` |
| 9 × bare `Image.network`, hakuna `cacheWidth` | picha kubwa zinapakia ukubwa wote, hakuna cache | `cached_network_image` + `memCacheWidth` |
| `core/theme/app_typography.dart:32-83` | `google_fonts` mtandaoni — offline = font fallback | bundle TTF assets |
| `features/radio/services/radio_browser_service.dart` | orodha kamili ya vituo bila pagination | `limit`/`offset` + search-as-you-type |
| `main.dart:18-101` | 9 awaited inits kabla ya `runApp` (Angalia Audit 02 L1-3) | boot gate + lazy services |
| `main.dart:57-62` SQLite | `sqlite3.wasm` 706 KB + open DB ambayo **hakuna anayeitumia** | ondoa/ lazy |

## 4 · Uendeshaji wa kanisa — mapengo makubwa (hii ndiyo sehemu ya "mali & mapato kwa Katibu")

### 4.1 Hakuna data model ya kanisa kwenye cloud
`rg` kwenye `firestore.rules` na `lib`: collection zilizopo ni `announcements`, `sermons`, `choir_songs`,
`visitors_registry`, `sunday_school_content`, `prayer_requests`, `jumuiya_reports`, `church_settings`, `profiles`.
**Hakuna kabisa:** `members`, `attendance`, `income`/`mapato`, `expenses`, `assets`/`mali`, `receipts`,
`minutes`/mikutano, `projects`, `audit_logs`.

### 4.2 Fedha ziko kwenye kifaa tu
`features/giving/services/giving_service.dart` huandika `zion_giving_records` kwenye **prefs za kifaa hicho**.
Maana yake: Mapato ya Kanisa hayamo popote katika cloud, hayashirikiwi na Mehani/Katibu, na vatapote kwa
"clear data" au kubadilisha simu. `amount` ni `double` (Angalia Audit 02 L2-3).

### 4.3 Portal: data ya uongo
`sayuni-portal/src/App.tsx:39-43` — `finances`, `expenses`, `projects` viko kwenye `useState` vilivyojaa kutoka
mock `INITIAL_*`; hakuna persistence. `FinanceModule.tsx:54-110` — shilingi float, ID `fin-${Date.now().slice(-4)}`.
`authService.ts:17,31,48,124` — jukumu kutoka `email.includes('admin')` + mock login. Kwa Katibu, hii ni dashboard
ya kuonyesha tu, siyo zana.

### 4.4 Hakuna ripoti wala export
`PDFService` (`core/services/pdf_service.dart`) iko lakini **0 call sites**; CSV hapo kamwe. Katibu hawezi
kutoa: ripoti ya mapato ya mwezi, rejista ya mali, taarifa ya mkutano, wala vibari vya udhibiti.

### 4.5 Mali za kanisa (asset register) haipo kabisa
Hakuna dhana ya: kinu, mfumo/spea, bango, magari, nyumba za kanisa, mikopo, matengenezo, mgawo wa branch,
mlezi wa kodi, wala depreciation. Hata `church_admin_screen.dart` (1531 lines) haishughulikii mali.

### 4.6 Mahudhuriano mengine ya kiutendeshaji
- **Uhudhuria (attendance)** haupo kwenye app — jumuiya counts pekee, na hivyo hazihifadhiwi cloud.
- **Vibari (receipts)** hakuna namba isiyobadilika; hakuna "mgawo wa Juma kwanza / asjari".
- **Mikutano na maazimio (minutes/resolutions)** — haipo; Katibu anaihifadhi wapi? sasa hapa.

---

## 5 · Mpango wa data unaopendekezwa (kwa kina tazama Phase 6)

```
members/{memberId}            uid?, fullName, phone, gender, dob, branch, jumuiya,
                              departments[], baptized, joinedAt, status, consent{...}
attendance/{yyyy-mm-dd}       serviceType, branch, men, women, children, visitors, countedBy, photoUrl?
income_records/{id}           receiptNo (immutable), category(tithe|offering|thanksgiving|building|evangelism|
                              welfare|asjari|other), amountCents:int, currency='TZS', method(cash|m-pesa|bank),
                              ref, memberId?, branch, recordedBy, recordedAt, fiscalYear, reversesId?
expense_records/{id}          voucherNo, category, amountCents, payee, approvedBy[], recordedAt, receiptImageUrl
assets/{assetId}              name, class(fixed|movable|vehicle|property|equipment), acquiredAt, costCents,
                              custodian(userId), branch, condition, maintenance[], disposedAt?
receipt_sequences/{yyyy}      prefix, nextValue            // atomic counter → namba za vibari
minutes/{yyyy-mm-dd}          type(exec|board|congregation), attendees[], agenda, resolutions[], approvedBy
audit_logs/{id}               actor, actorRole, action, path, before, after, at
```

Sheria za muundo: `amountCents` daima integer; hakuna `double` fedha; hakuna update ya `receiptNo`;
kila mabadiliko ya fedha huandika `audit_logs` na `reversesId` (siyo kufuta rekodi); kila rekodi ya PII ina
`branch` ili rules ziweza kudhibiti "Katibu wa branch gani".
