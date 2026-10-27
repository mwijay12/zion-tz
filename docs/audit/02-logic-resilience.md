# Audit 02 — mantiki na uvumivu (logic resilience) ya kila sehemu

Tarehe: 2026-10-27 · `sayuni/lib` · HEAD `3752a55`
Alama: **L1** critical · **L2** high · **L3** medium · **L4** low.

---

## L1-1 · Makosa yanamezwa kimya kimya (110 catch sites)

`rg -n "catch \(" sayuni/lib \| wc -l` = **110**, ambapo:
- **44** ni `catch (_)` — hakuna hata debugPrint;
- **28** zina mwili mtupu (`catch (_) {}`).

Mifano iliyothibitishwa katika njia za kila siku:

| Mahali | Athari |
|---|---|
| `core/services/church_sync_service.dart:136`, `:182`, `:297`, `:346` | Cloud/portal sync ikishindwa, mtumiaji anaona "kama imefanyika" |
| `features/media/presentation/media_hub_screen.dart` (rails) | Library inaoneza empty badala ya "imeshindikana" |

Hii ni aina moja ya uongo: **user anadhani kitu kimefanya kazi yake**. Muktadha wa Cloudinary (2026-10-27)
ulikuwa tatizo lileile — `null` iligeuzwa kuwa "limepakiwa kikamilifu".

**Kanuni mpya (Phase 4):** kila `catch` lazima (a) `debugPrint`, na (b) ikiwa iko kwenye njia ya mtumiaji,
(с) weka hali ya kosa inayoonekana + **Jaribu Tena**. `catch (_)` isibaki popote katika services.

## L1-2 · Loader inaweza kuzungusha milele

- **16** `CircularProgressIndicator` sites · **0** `FutureBuilder` (kila kitu ni `setState` manual).
- `features/radio/presentation/online_radio_screen.dart`: tano `_isLoading*` flags; hakuna chip ya kosa wala Retry.
- `package:http` timeouts: `cloudinary_media_service.dart` ina timeout (imekamilika 2026-10-27), lakini
  `church_sync_service.dart`, `radio_browser_service.dart`, `supabase_database_service.dart` hutumia `http.get/post`
  **bila `.timeout(...)`** → connection isiyokamilika = spinner ya milele.

**Kanuni (Phase 4):** kila network call = `.timeout()` + kosa la mtumiaji; kila loader = deadline ya juu;
hakuna spinner isiyo na njia ya nje.

## L1-3 · `main.dart` — matukio 9 ya `await` kabla ya `runApp`

`main.dart:18-101`: Firebase → language → theme → SQLite → auth → notifications → audio (×3) → sync,
yote `await` mfululizo, kila kimoja kimezungushiwa `try/catch` kinachotupa `debugPrint` tu.

Athari: boot ndefu (hasa web, ambapo `sqlite3.wasm` 706 KB na Firebase JS zepakindwa), na kushindwa
kojenera **hakuna** aliyeko karibu kuona — app inaendelea hata kama auth haijaanzishwa (`_isInitialized=false`
bado `runApp` inaitwa), hivyo UI inaonyesha default profile (`Muumini wa Sayuni`, `ZJC-2026-8894`) kwa kila mtu.

**Kanuni (Phase 7/10):** weka tu `ensureInitialized` + Firebase + theme + auth kabla ya `runApp`;
audio/notifications/sync/SQLite ziwe lazy au post-frame. Onyesha `BootGate` yenye kosa wazi ikiwa auth imeshindwa.

## L2-1 · Keys za SharedPreferences hazina mmiliki mmoja

| Key | Watumiaji | Hatari |
|---|---|---|
| `zion_prayer_requests` | `core/services/church_sync_service.dart` **na** `features/jumuiya/services/jumuiya_service.dart` | **schema mgongano** — services mbili zinaandika mfumo tofauti wa JSON kwenye key moja; wa mwisho kuandika anaharibu wa kwanza |
| `zion_admin_uploaded_media` + `flutter.zion_admin_uploaded_media` | `church_sync_service.dart:327-328` | nakala mbili za data moja; `flutter.` prefix ni artifact ya `SharedPreferences` platform channel |
| `zion_portal_visitors` + `flutter.zion_portal_visitors` | `church_sync_service.dart:561-562` | kama hapo juu |
| `granted_admin_emails` | `church_auth_service.dart:184-198` | **inaandikwa tu, haisomiki** |

**Kanuni (Phase 5):** faili moja (`core/storage/prefs_keys.dart`) = chanzo cha key zote, type-safe
repository kwa kila set, na **schema migration** (`schemaVersion`) ili data ya zamani isipotee.

## L2-2 · Vitambulisho vinavyoweza kugongana (double-tap = data loss)

`rg "millisecondsSinceEpoch" sayuni/lib` → **14** tovuti za kuunda ID kwa wakati, mfano
`admin_media_upload_sheet.dart:318` (`admin-<epoch>`), giving records, expenses. Mbili za sekunde moja
= kitambulisho kimoja → `list.removeWhere((e) => e['id'] == id)` (`church_sync_service.dart:323`)
inafuta rekodi ya kwanza. Kwa fedha (Phase 6) hii ni hatari ya kiusalama.

**Kanuni:** `core/utils/uid.dart` — `uuid + timestamp`; namba za risiti haziundwi kwa `Date.now()`.

## L2-3 · Fedha kama `double`

`features/giving/services/giving_service.dart` / model yake: `amount` ni **`double`**. Shillingi zinahifadhiwa
kama float → makosa ya `0.1 + 0.2` kwenye jumla za ripoti za Katibu/Mehani.

**Kanuni (Phase 6):** kila kiasi = **integer cents** (`amountCents`), `double` haifanyi kazi yoyote ya kihifadhi.

## L2-4 · `mounted` / lifecycle

Screens kubwa (`profile_screen.dart` 1984, `media_hub_screen.dart` 1926, `bible_screen.dart` 1897,
`church_admin_screen.dart` 1531) zina `async` + `setState`; sehemu zina `if (!mounted) return` (nzuri, mfano
`admin_media_upload_sheet.dart:147,207,219`), lakini hakuna ukaguzi uliokwama kila mahali, na `Timer`/
`StreamSubscription` zote hazifungwi katika kila `dispose()`. Mfano mzuri uliopo: `_ticker?.cancel()`
(`admin_media_upload_sheet.dart:135`) — hii ndiyo mfano wa kufuata.

## L3 · Mantiki iliyovunjwa / isiyotumika

| Kitu | Ushahada | Hali |
|---|---|---|
| `core/services/pdf_service.dart` (`PDFService`) | 0 call sites | iliyoachwa (orphan) — Phase 9 itaitumia ripoti za Katibu |
| CSV export | hakuna | Katibu hawezi kutoa ripoti |
| Attendance kwenye app | hakuna (jumuiya counts tu) | Phase 6 |
| `DatabaseService()` | `main.dart:59`, `church_sync_service.dart:27`, `database_service.dart:7`, `supabase_database_service.dart:14` — lakini hakuna insert/query | SQLite inafunguliwa kila boot bila kutumika (wasteful, na `sqlite3.wasm` 706 KB) |
| `deleteAccount()` | `church_auth_service.dart:305-334` | inafuta prefs za kifaa; cloud data inabaki → PDPA erasure incomplete |
| Firestore `announcements` stream | `church_sync_service.dart:85-99` | inategemea rules ambazo zinasoma claims zisizopo (Angalia Audit 01 S1-2) → stream inaweza kurudisha `permission-denied` kimya kimya |

## L4 · Ushahada wa ziada usiothibitishwa kwa ukamilifu

Yafuatayo yametoka kwenye ukaguzi wa pili (sub-agent) ambao **sijauathibisha mmoja mmoja** kwa sasa —
tumiwa kwa tahadhari na Phase husika inayare-check kabla ya kubadilisha:

- 110/44/28 catch counts (nimezirudia kwa `rg`, sawa).
- `bible_service.dart:30,55,58,77` `rootBundle.loadString` + `json.decode` kwenye UI isolate, na
  `bible_screen.dart:383-399` inapakia tafsiri mbili + nyimbi kwa pamoja.
- `media_hub_screen.dart:189-200` filtering ndani ya `build()`; `universal_search_sheet.dart:335-375,:667`
  debounce hafifu.
- 9 bare `Image.network`, **hakuna** `cached_network_image` wala `cacheWidth`.
- `core/theme/app_typography.dart:32-83` `google_fonts` inapakia mtandaoni (FOUT/offline failure).
- `radio_browser_service.dart` hakuna pagination/offset (stoza kubwa ya vituo).
- Portal: `sayuni-portal/src/App.tsx:39-43` finances/expenses/projects kwenye `useState` kutoka mock
  `INITIAL_*` (hakuna persistence — refresh yafuta); `FinanceModule.tsx:54-110` float + `fin-${Date.now().slice(-4)}`;
  `authService.ts:17,31,48,124` role kutoka `email.includes('admin')` na mock login.

> Kumbuka: kile cha "assets 138/162 (~27 MB) hazitumiki" kilikuwa **si kweli** — kipimo changu: 4 faili /
> 1,031,911 B / 2.0% ya 41,697,555 B. Tazama Audit 03.
