# Uthibitisho: App ⇄ Portal, Arifa, na PDF

*Imesasishwa: 26 Novemba 2026 · Branch `arena/2dd3a129-zion-tz`*

Nyaraka hii inajibu maswali manne kwa ushahidi unaoweza kuendeshwa, sio kwa madai:

1. [Arifa zinafanya kazi kweli?](#1-arifa)
2. [App na admin portal zinawasiliana kweli?](#2-app--portal)
3. [Link ya admin iko wapi na inafungua nini?](#3-link-ya-admin)
4. [PDF ni vector kweli, sio screenshot?](#4-pdf)

Kila sehemu ina amri unayoweza kuendesha mwenyewe.

```bash
cd sayuni-portal
npm test          # rules + data contract + PDF vector (37 checks)
```

---

## 1. Arifa

### Kilichokuwa kimeharibika

Kengele ya arifa kwenye portal **haikuwa na chanzo chochote**. Kulikuwa na
orodha iliyoandikwa kwa mkono (`INITIAL_NOTIFICATIONS` ndani ya `Header.tsx`)
na arifa tano za kubuni:

- "Sadaka ya Ujenzi Imepokelewa … TSh 250,000 … #MP-9821"
- "Kikao cha Baraza la Wazee …"
- na mengine matatu

Hakuna kitu kilichozalisha arifa hizo, na hakuna kitu kilichozitumia. Kila
kiongozi, kwenye kila kifaa, aliona "5 mpya" kila alipofungua ukurasa — hata
kwenye kivinjari kipya kabisa. Ilionekana kama mfumo unaofanya kazi; haikuwa.

### Kilichofanyika

`src/services/notificationCenter.ts` (mpya) inajenga arifa kutoka kumbukumbu
**halisi** ambazo portal tayari inaandika:

| Chanzo | Arifa inayotolewa | Inafungua |
|---|---|---|
| `announcements` | Tangazo limechapishwa; la dharura linawekwa mbele | Ofisi ya Katibu |
| `events` | Tukio limewasilishwa; ombi la posta linasubiri | Studio ya Poster |
| `sermons` | Mahubiri mapya yamepakiwa | Ofisi ya Askofu |

Kanuni za muundo:

- **Hakuna collection mpya.** Arifa ni mtazamo wa data iliyopo, kwa hivyo
  kengele haiwezi kutofautiana na kumbukumbu halisi.
- **Role-aware.** Kiongozi wa kwaya hapati arifa za orodha ya posta.
- **Read-state inahifadhiwa** (`localStorage`, cut-off timestamp), kwa hivyo
  badge haianzi upya kila reload.
- **Tupu ni jibu halali.** Kama hakuna kilichotokea, kengele inaonyesha
  "Hakuna arifa mpya" — haibuni shughuli.

### Upande wa app: makosa matatu ya arifa yaliyorekebishwa

Arifa za app zilikuwa na makosa ya kimya kimya:

1. **Tangazo lilifika tupu.** Portal inaandika `body` **na** `content`. App
   ilitumia `item['summary'] ?? item['content'] ?? ''`, na `??` inasimama kwenye
   ufunguo wa kwanza uliopo hata kama thamani yake ni string tupu. Sasa
   `_firstNonEmpty()` inaruka thamani tupu: `body → content → summary`.

2. **Dharura zilifika kama kawaida.** Portal inaandika `type: 'urgent'`, app
   iliangalia `isUrgent`/`isHighPriority` — ufunguo ambao portal haiandiki
   kamwe. Kwa hivyo tangazo la dharura lilifika kimyakimya, bila alert ya
   lock-screen. Sasa app inasoma `type` na `priority: 'high'`.

3. **Mabadiliko na ufutaji haukufika.** App ilitumia `Set` ya ids pekee, na
   iliongeza tu. Matokeo:
   - katibu akibadilisha tangazo (venue, dharura), simu iliendelea kuonyesha
     toleo la zamani milele;
   - tangazo likifutwa, simu iliendelea kulionyesha milele.

   Sasa de-duplication inatumia **fingerprint ya maudhui**
   (`_noticeFingerprint`), na `pruneMissingPortalNotices()` inaondoa arifa
   zilizofutwa kwenye wingu — lakini **kamwe** haigusi arifa za ndani (seed),
   na haifanyi kazi kwenye local-cache snapshot (`metadata.isFromCache`), kwa
   hivyo cold start haiwezi kufuta kila kitu.

   Pia: tangazo lililohaririwa halizimui tena simu kwa alert mpya — linabadilika
   kwenye orodha tu, kwa kuwa mwanachama alikwisha lisoma.
   Read-state inahifadhiwa kwenye kifaa, kwa hivyo cold start hairudii arifa za
   zamani.

---

## 2. App ⇄ Portal

### Njia zinazofanya kazi (zilizothibitishwa)

| Kumbukumbu | Portal inaandika | App inasoma | App inaandika | Portal inasoma |
|---|---|---|---|---|
| `announcements` | ✅ | ✅ stream | — | ✅ stream |
| `sermons` | ✅ | ✅ stream | ✅ | ✅ stream |
| `events` | ✅ | ✅ stream | ✅ | ✅ stream |
| `prayer_requests` | — | — | ✅ | ✅ **imeongezwa sasa** |
| `church_settings/leadership` | ✅ | ✅ stream | — | ✅ stream |
| `visitors_registry` | ✅ | — | ✅ | ✅ stream |
| `jumuiya_reports` | ✅ | — | — | ✅ stream |

### Kilichokuwa kimevunjika: maombi ya waumini

Hii ilikuwa mgawanyiko mkubwa zaidi kati ya app na portal.

- App inaandika maombi kwenye `prayer_requests` (na `userId`, `createdAt`).
- PastorsPortal ilisoma "Maombi ya Moja kwa Moja Kutoka kwa Waumini" kutoka
  `churchSync.getPrayers()` — ambayo ni **localStorage** tu.

localStorage ya kivinjari cha askofu haiwezi kamwe kuwa na ombi lililotumwa
kutoka simu ya mwanachama mwingine. Kwa hivyo panel ilionyesha data ya sampuli
wakati maombi halisi yalikaa Firestore bila kusomwa na mtu.

**Sasa:** `FirebaseChurchService.subscribeToPrayerRequests()` inasoma
`prayer_requests` (limit 50, `orderBy createdAt`), na PastorsPortal inaunganisha
matokeo na cache ya ndani. Ikikataliwa na rules (mtumiaji si mchungaji), panel
inasema wazi kwamba inaonyesha kile kilichohifadhiwa kwenye kifaa.

### Ushahidi unaoendeshwa

`scripts/data-contract-test.mjs` inasoma Dart halisi na TypeScript halisi na
kuhakikisha majina ya field yanaendelea kufanana:

```
$ node scripts/data-contract-test.mjs
PASS  announcements: portal write fields the app understands
PASS  announcements: app falls back across body/content/summary
PASS  announcements: urgency survives the trip
PASS  announcements: edits and deletions reach the device
PASS  events: app-submitted event satisfies isValidEvent
PASS  events: portal reads the fields the app writes
PASS  prayer_requests: portal does not rely on localStorage only
PASS  prayer_requests: pastor view is fed from the cloud feed
PASS  sermons: both writers set createdAt
PASS  sermons: rules requirement is satisfiable by the portal
PASS  church_settings/leadership: both sides use the same document id
PASS  ordering: every orderBy field is written by some producer
PASS  portal notifications: no hardcoded seed notification feed
PASS  pdf: exports are vector documents, not screen captures
14/14 checks passed
```

### Kilichobaki kuwa cha ndani (localStorage) kwa makusudi

Hivi ni maeneo ambapo portal bado haijaunganishwa na wingu. Hayajafichwa:

- Hazina (`finances`, `expenses`, `projects`) — nyeti; inahitaji uamuzi wa
  mmiliki kuhusu nani anaruhusiwa kuandika.
- Nyimbo za kwaya (`choir_songs`) — zinaandikwa na app; portal bado inasoma
  cache.
- Vyeti — zinazalishwa na kupakuliwa; hazihifadhiwi Firestore.

---

## 3. Link ya admin

### Ilipokuwa

URL ilikuwa imeandikwa moja kwa moja mahali mawili tofauti:

- `profile_screen.dart` — kitufe "Fungua Tovuti"
- `sayuni_copilot_service.dart` — `_apiEndpoint`

Hakuna kitu kilichounganisha hizi. Badilisha domain, kosa moja linabaki, na
kitufe cha kiongozi kinakufa kimya.

### Ilipo sasa

`lib/core/constants/core_links.dart` (mpya) ni chanzo kimoja:

```dart
CoreLinks.portalBase     // https://sayuni-portal.vercel.app
CoreLinks.portalHome     // …/
CoreLinks.copilotEndpoint// …/api/copilot
CoreLinks.portalHost     // sayuni-portal.vercel.app
```

Inaweza kubadilishwa bila kugusa code:

```bash
flutter build apk --dart-define=PORTAL_BASE_URL=https://preview.example.org
```

Copilot endpoint inatokana na `portalBase` — kwa hivyo build ya preview
inaita API ya preview, sio production. (Hizi mbili zilianza kutofautiana.)

### Kitufe kipya kwenye app

`ChurchAdminScreen` sasa ina kadi ya "Portal ya Viongozi (Admin Portal)":

- inaonyesha **host kamili** ambayo build hii ya APK itafungua — tofauti
  kati ya APK na deployment inaonekana badala ya kuwa siri;
- kitufe "Fungua Portal" kinafungua kwenye browser ya nje;
- ikishindikana, inatoa toast yenye host — hakuna kitufe kinachokufa kimya.

Android manifest tayari ina `<queries>` kwa `https`, kwa hivyo
`canLaunchUrl` inafanya kazi kwenye Android 11+.

---

## 4. PDF

### Jibu fupi

**Ndio, ni vector halisi.** Maandishi yanachaguliwa (selectable), yanatafutwa,
na hayapotei ubora ukiprintiwa. Hakuna `html2canvas`, hakuna `toDataURL()`,
hakuna `window.print()` ya ukurasa wa wavuti.

### Ufafanuzi wa `html2canvas` kwenye bundle

`dist/` ina faili `html2canvas-*.js` (199 kB). Hii **si** code yetu — ni
tegemezi la hiari la `jspdf`, linalopakiwa kwa `import()` **lazy** ndani ya
`doc.html()` pekee, ambayo ni njia ya jspdf ya kupiga picha ya DOM. Sisi
hatuita `.html()` kamwe: PDF zote zinaundwa kwa `.text()`, `.line()`,
`.rect()`.

Kipimo `data-contract-test.mjs` sasa kinahakikisha hakuna huduma inayogusa
`.html()`, kwa hivyo njia ya screenshot haiwezi kuingia kimya kimya baadaye.

### Ushahidi

`scripts/pdf-vector-test.mjs` inaunganisha **source halisi** ya
`officialPdfService.ts` na `certificatePdfService.ts` kwa bundler ya repo,
inaendesha kwenye DOM shim ndogo, inakamata PDF kutoka jsPDF, na kuchunguza
bytes:

```
PASS  bulletin: is a real PDF                        20275 bytes, 2 page(s)
PASS  bulletin: text is selectable vector glyphs     65 Tj/TJ ops, 14 font objects
PASS  bulletin: page is not a screenshot             0 embedded image(s), 0 JPEG stream(s)
PASS  visitors: text is selectable vector glyphs     52 Tj/TJ ops
PASS  groups:   text is selectable vector glyphs     54 Tj/TJ ops
PASS  finance:  text is selectable vector glyphs     159 Tj/TJ ops
PASS  certificate: text is selectable vector glyphs  20 Tj/TJ ops
PASS  overall: documents stay in vector byte range   5 documents, 7 pages, 12796 bytes/page
16/16 checks passed
```

Kipimo cha maana:

| Kipimo | Screenshot | Vector | Kilichoonekana |
|---|---|---|---|
| `/Subtype /Image` | nyingi | 0–2 (logo) | **0** |
| `DCTDecode` (JPEG) | ≥1 | 0 | **0** |
| `Tj` / `TJ` ops | 0 | makumi–mamia | **20–159** |
| Bytes kwa ukurasa | >200 KB | <50 KB | **~13 KB** |

Maandishi halisi ndani ya `certificate.pdf`:

```
CHETI CHA UBATIZO WA MAJI TELE
HATI RASMI YA KANISA
Hati hii inathibitisha kwamba:
ZION JERUSALEM CHURCH
```

### Jinsi inavyoundwa

- `officialPdfService.ts` — A4, `doc.text()` kwa kila mstari, `doc.rect()` kwa
  maboksi, `doc.line()` kwa mistari. Logo (`doc.addImage`) ni picha pekee.
- `certificatePdfService.ts` — A4 landscape, `doc.text()` na vector zote.

Kwa kuwa ni vector, Mchungaji anaweza kuchagua jina la mwanachama kwenye PDF na
kulibandika kwenye barua pepe — jambo ambalo PDF ya screenshot hairuhusu.

---

## 5. Mzunguko wa pili: makosa matatu yaliyobaki kwenye arifa

Baada ya kuunganisha app na portal, ukaguzi wa kina wa mantiki ya arifa
uligundua makosa matatu ambayo yote yalikuwa **kimya** — hakuna error, lakini
matokeo si sahihi.

### 5.1 Kengele ilikuwa na nakala ya matrix ya roles — na zilitofautiana

`notificationCenter.ts` ilikuwa na `TAB_FOR_ROLE` yake mwenyewe, iliyoandikwa
kwa mkono "ili ilingane na `AuthService.TAB_ROLES`". Haikulingana:

| Tab | `AuthService.TAB_ROLES` | `TAB_FOR_ROLE` (zamani) |
|---|---|---|
| `media_studio` | `'all'` (kila role) | roles 9 pekee |

Kwa hivyo `deacon` au `jumuiya_leader` aliyepewa arifa ya ombi la posta
aliruhusiwa na lango moja na kuzuiwa na lango lingine — aliona arifa,
alibonyeza, na hakuna kilichotokea. Sasa `canNavigateTo()` inauliza
`AuthService.canRoleAccessTab()`: chanzo kimoja cha ukweli, hakuna nakala ya
pili ya kudrifti.

Pia: matangazo sasa ni `alwaysVisible` — taarifa ya msiba au ibada ni ya umma,
kwa hivyo mshemasi na mwanakwaya wanaiona hata wasiweze kufungua Ofisi ya
Katibu. Wakibonyeza, inawekwa kama imesomwa; hakuna urambazaji wa uongo.

### 5.2 "Hivi karibuni" ilikuwa uongo kwa kila rekodi mpya

Tangazo lilipochapishwa, `createdAt` ni `serverTimestamp()`. Kwenye *local
echo* ya listener, thamani hiyo bado ni `null` kwa muda mfupi. `relativeTime(0)`
ilirudisha "Hivi karibuni" — kwa hivyo arifa mpya ilionekana kama "Sasa hivi",
kisha ikaruka hadi "Dakika 3 zilizopita" mara server ilipothibitisha.

Sasa `0` inamaanisha "haijathibitishwa": inaonyesha **"Inathibitishwa"** /
"Pending". Ni ukweli unaoonekana, sio uzuri wa uongo.

### 5.3 Kila kitu kilichopangwa kwa `createdAt` kinaweza kutoweka

Hii ni muhimu zaidi, na haijarekebishwa kwa makusudi — inahitaji uamuzi wako.

`orderBy("createdAt", "desc")` **haitoi** nyaraka zisizo na sehemu hiyo;
Firestore inaziondoa kwenye matokeo **bila error yoyote**. Na
`0 G`/`orderBy` ni pamoja na:

| Msomaji | Amri | Nyaraka zinazotoweka |
|---|---|---|
| `subscribeToAnnouncements` | `announcements` + `orderBy createdAt` | matangoza yoyote yaliyoandikwa **kabla ya** `9cd6379` (wakati `publishAnnouncement` ilikuwa haijaongeza `createdAt`) |
| App `church_sync_service` | `announcements` + `orderBy createdAt` | hiyo hiyo |
| `subscribeToSermons` / app | `sermons` + `orderBy createdAt` | mahubiri ya zamani yaliyoandikwa kwa `...sermon` |

Ikiwa kanisa lina matangazo ya awali kwenye Firestore, **hayataonekana kwenye
kengele wala kwenye simu**, hata baada ya rules kuwekwa. Hakuna njia ya
kujua bila kuangalia data halisi.

**Uamuzi unaohitajika** (mmoja):

1. **Backfill** — endesha script mara moja kuongeza `createdAt` kwa nyaraka
   zisizo nazo (ukubwa: `scripts/backfill-createdAt.mjs`, inahitaji
   service account). Safi zaidi.
2. **Acha `orderBy`** — soma collection yote kisha panga kwa upande wa client,
   ukitumia `createdAt ?? publishedAt ?? 0`. Nyepesi, lakini inasoma kila
   rekodi.
3. **Puuza** — ikiwa hakuna data ya zamani (deployment ni mpya). Hatari:
   huwezi kujua bila kuangalia.

Ushauri: chagua (1) ikiwa kuna data yoyote ya zamani; (2) ikiwa hujui.
Sijafanya hili kwa sababu linagusa data ya production, sio code.

### 5.4 Hitilafu iliyogundulika na kutotengenezwa (kwa makusudi)

`NotificationsDataService.markAllAsRead()` inaandika ids za arifa **zote**
kwenye `_readKey`, ikiwa ni pamoja na arifa za viongozi (`targetAudience:
'leaders'`). `markAsRead(id)` ni sawa. Kwa sasa hii haina madhara kwa mwanachama
kwa sababu `filteredAnnouncements` inachuja kabla ya kuonyesha, lakini
`unreadCount` inategemea orodha iliyochujwa — kwa hivyo mwanachama anaweza
"kumaliza kusoma" kitu asichokiona. Hii ni **sahihi kwa bahati**, sio kwa
muundo. Inahitaji uamuzi wa PDPA: kama arifa ya kiongozi ni ya siri, id yake
haipaswi kuhifadhiwa kwenye kifaa cha mwanachama.

---

## Muhtasari wa uthibitisho

| Amri | Matokeo |
|---|---|
| `npm run test:rules` | 7/7 (role contract portal ⇄ rules) |
| `npm run test:contract` | 16/16 (field contract portal ⇄ app + notification targeting) |
| `npm run test:pdf` | 16/16 (vector PDF proof) |
| `npm run lint` | 0 errors, 14 warnings (zilizopo awali) |
| `tsc -b --noEmit` | safi |
| `npm run build` | safi |
| jsdom walk ya moduli 14 | zote `ok`, 0 runtime errors |
| Bell ya arifa | inafungua, "Hakuna arifa mpya", hakuna maandishi ya kubuni |
| Mantiki ya arifa (runtime) | 19/19 (roles, muda, filtering, read-state) |

**Haijathibitishwa:** kanuni za Firestore hazijawekwa wingu bado (kama
ulivyosema, zitasukumwa baadaye). Kwa hivyo uthibitisho wa mwisho wa ruhusa
ni wa kimuundo; `npm run test:rules` inalinganisha majina ya roles, sio
utekelezaji halisi.
