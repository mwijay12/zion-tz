# Muunganisho wa Mfumo & Studio ya Poster (System Connections & Poster Desk)

*Ilisasishwa: 10 Novemba 2026 · Branch: `arena/43a65560-zion-tz`*

Hati hii inajibu maswali mawili:

1. **Je, logic imeunganishwa wapi sasa hivi?** — ramani ya watu (waumini, viongozi, wakaribishaji/ushers, wasimamizi), programu ya wanachama (Flutter), portal ya viongozi (React), na Cloud Firestore.
2. **Super Admin anasaidiwa vipi kutengeneza poster?** — mnyororo kamili kutoka "kiongozi anaandika tukio" hadi "poster inatengenezwa, inatiwa sahihi na kutumwa".

---

## 1. Ramani ya miunganisho (ukaguzi)

| Safu | Mahali | Kazi yake sasa | Hali |
|---|---|---|---|
| **Uthibitisho** | `sayuni-portal/src/services/authService.ts`, `sayuni/lib/core/services/church_auth_service.dart` | Firebase Auth + barua pepe iliyothibitishwa + **custom claim `role`**. Hakuna orodha ya barua pepe inayompa mtu cheo. | Imeunganishwa |
| **Mamlaka ya vyeo** | `functions/index.js` → `setUserRole` / `revokeUserRole` (Admin SDK) | Sehemu **pekee** inayoandika `request.auth.token.role`. Inaandika pia kioo kwenye `members/{uid}` + `audit_logs`. | Imeunganishwa |
| **Sheria za wingu** | `firestore.rules` | Inasoma `request.auth.token.role` moja kwa moja; inakataa maandishi yasiyoruhusiwa. | Imeunganishwa |
| **Orodha ya vyeo** | `types.ts` (portal), `authService.ts`, `functions/index.js` ROLES, `church_role_policy.dart` (app) | Orodha 11 → sasa **12** (imeongezwa `usher`). Majina ya waya ni yaleyale pande zote nne. | Imekamilishwa |
| **Matangazo** | `announcements` (Firestore) | Portal `SecretaryPortal` → `churchSync.addNotice` → `publishAnnouncement` → app inasikiliza `snapshots()` na kuonyesha notification/banner. | Imeunganishwa |
| **Mahubiri** | `sermons` | Portal/app huandika; app husikiliza. | Imeunganishwa |
| **Wageni / "connect card"** | `visitors_registry` | App `syncNewVisitor` huandika wingu; portal `DeaconsPortal` sasa **inasoma pia kutoka wingu** (ilianza kuwa localStorage tu). | Imeunganishwa |
| **Picha ya viongozi** | `church_settings/leadership` | Portal `updateLeadership` na app `syncLeadershipInfo` huandika wingu; pande zote mbili husikiliza na kusasisha picha/majina moja kwa moja. | Imeunganishwa |
| **Matukio / maombi ya poster** | `events` (**mpya**) | Viongozi/wakaribishaji wanaandika kutoka portal **au** app; Super Admin anasoma folio ya moja kwa moja kwenye Studio ya Poster. | Mpya, imeunganishwa |
| **Akaunti za viongozi** | `MembersModule` → `churchRoleService.ts` → `setUserRole` | Kuongeza kiongozi kwenye daftari sasa kunatoa **ruhusa halisi ya Firebase**, si jina kwenye `localStorage` tu. | Imekamilishwa |

### Mapengo yaliyopatikana na kufungwa

| Pengo la awali | Suluhisho |
|---|---|
| `usher` (mkaribishaji) alikuwepo kwenye maandishi ya UI tu, si kwenye vyeo halisi | Role `usher` imeongezwa kwenye portal, Cloud Functions, Firestore rules na `church_role_policy.dart`; wakaribishaji wanaweza kusoma daftari la wageni na kuandika matukio. |
| Kuongeza "kiongozi" kwenye `MembersModule` kuliunda tu kipengee cha `localStorage` — mtu huyo hakuweza kuingia | `churchRoleService.ts` inaita `setUserRole`; ujumbe wazi kama akaunti ya Firebase haipo bado ("ajisajili kwanza kwenye app"). |
| Picha ya viongozi ilihifadhiwa kwenye `localStorage` ya kivinjari kimoja tu | `church_settings/leadership` kwenye Firestore + visikilizaji pande zote mbili. |
| Fomu ya "connect card" kutoka app haikuonekana kwenye portal | `DeaconsPortal` inachanganya rekodi za wingu na za ndani. |
| `MediaContentStudio` ilitumia `TEMPLATES` tuli na `INITIAL_BULLETIN_NOTICES` ya mock — Super Admin hakuona matangazo halisi | Folio ya **live** kutoka Firestore (`events` + `announcements`) yenye vitendo vya kutengeneza poster. |
| Hakukuwa na njia ya kuandika maelezo ya tukio (tarehe, saa, mahali, mstari) popote | Fomu mpya kwenye Portal (`Studio ya Poster & Matukio`), fomu ya "Omba Poster" kwenye `SecretaryPortal`, na skrini ya app `EventRequestScreen`. |

---

## 2. Mnyororo wa poster (jibu la swali lako)

```
KIONGOZI / USHER / KWAYA / JUMUIYA
   └─ anaandika tukio (kichwa, ujumbe, tarehe, saa, mahali, mstari, "omba poster")
        ├─ Portal: Studio ya Poster & Matukio → "A. Andika Tukio"
        ├─ Portal: Ofisi ya Katibu → tangazo + checkbox "Omba Poster"
        └─ App:    Profaili → "Tuma Tukio / Omba Poster"  (EventRequestScreen)
                     │
                     ▼
        Cloud Firestore  →  events/  (au announcements/ yenye posterRequest)
                     │  (realtime, kifaa chochote)
                     ▼
SUPER ADMIN anaingia kwenye Portal → "Studio ya Poster & Matukio"
   └─ "B. Folio ya Matukio & Matangazo (Live)" inaonyesha "Inasubiri Poster"
        └─ Bonyeza "Tengeneza Poster" → maelezo yanaingia kwenye muundo kiotomatiki
             ├─ Chagua rangi (Sanctuary / Burgundy / Mkesha / Emerald / Light)
             ├─ Chagua ukubwa (WhatsApp Status 9:16 au Instagram 1:1)
             ├─ Pakua PNG ya HD (1080×1920 / 1080×1080)  ← tayari kutumwa
             ├─ "Prompt ya Canva" → nakili maagizo yaliyo tayari kubandikwa
             │   kwenye Canva Magic Design (ikiwa unataka kuharibu zaidi huko)
             ├─ "Caption" / "Shiriki WhatsApp" → tuma kwenye makundi mara moja
             └─ "Weka: Imetengenezwa" → hali inarudi Firestore (`posterStatus: 'ready'`)
                                       → viongozi walioandika wanaona ✓ Imetengenezwa
```

**Kwa hiyo:** huna haja ya kumsubiri mtu akutumie maelezo kwa WhatsApp. Ukikabidhi viongozi wanaandika wenyewe kwenye mfumo; wewe unaingia tu, unaona folio, unabonyeza mara moja, poster iko tayari (PNG au prompt ya Canva), unaituma, na mfumo unawaambia kuwa imekamilika.

> **Canva au PNG?** Zote mbili zinapatikana. PNG inatengenezwa **ndani ya mfumo** (canvas, bila API key, bila internet, hakuna gharama). "Prompt ya Canva" ni maagizo yaliyoandaliwa tayari (kichwa, ujumbe, tarehe, rangi, caption) ya kubandika kwenye Canva Magic Design ikiwa unataka muundo mwingine. Hatujaunganisha Canva API kwa sababu inahitaji OAuth/Connect akaunti ya kulipia — hiyo iko kwenye orodha ya baadaye.

---

## 3. Modeli ya data

### `events/{eventId}` (mpya)
`title`, `description`, `category`, `eventDate`, `eventTime`, `venue`, `themeVerse`, `branch`,
`needsPoster`, `posterStatus: none | requested | ready`, `posterTheme`, `posterFormat`,
`posterCaption`, `posterAuthor`, `posterGeneratedAt`, `requestedBy`, `requestedByRole`,
`requestedByEmail`, `createdBy`, `createdAt`.

### `announcements/{id}` (nyongeza)
`posterRequest`, `posterStatus`, `posterTheme`, `posterAuthor`, `posterGeneratedAt`,
`eventDate`, `eventTime`, `venue`, `themeVerse` — pamoja na sehemu zilizokuwepo (targeting, n.k.).

### `church_settings/leadership`
`bishopName`, `coLeaderName`, `assistantPastor`, `assistantPhone`, `leadershipPhotoUrl`, `updatedAt`.

---

## 4. Vyeo na ruhusa (baada ya kazi hii)

| Cheo (`role`) | Anaweza |
|---|---|
| `super_admin`, `admin` | Kila kitu; kugawa vyeo; kutia sahihi poster; kubadilisha picha ya viongozi |
| `pastor`, `secretary` | Kuchapisha matangazo, kuandika matukio, kutia sahihi poster |
| `deacon`, `treasurer`, `jumuiya_leader`, `choir_leader`, `children_teacher` | Kuandika matukio / kuomba poster, kufungua moduli zao |
| **`usher`** (mpya) | Mapokezi ya wageni (kusoma `visitors_registry`), kuandika matukio na kuomba poster |
| `member`, `guest` | App ya mwanachama; hawaingii kwenye portal |

Sheria: `firestore.rules` → `events` inasomwa na wote, **inaandikwa na `isChurchWorker()`** (pamoja na ushers), na **inasasishwa na `isSecretary() || isAdmin()`** pekee. Hivyo mkaribishaji hawezi kujiwekea "poster imetengenezwa" wala kuchapisha tangazo kwa waumini wote.

---

## 5. Bado inahitajika (kwa ajili ya production)

- **FCM push:** folio/notification zinaonekana app ikiwa wazi na online; kusukuma simu iliyofungwa bado kunahitaji FCM topics.
- **Targeting ya matangazo kwenye rules:** leo `announcements` husomwa na wote na kuchujwa kwenye UI; rules lazima zitekeleze `targetUid` / `targetJumuiya`.
- **Kuhifadhi PNG ya mwisho:** sasa PNG inapakuliwa kwenye kifaa cha Super Admin na kutumwa WhatsApp. Hatua inayofuata ni kuipakia Cloudinary/Firebase Storage na kuhifadhi URL kwenye `events` ili viongozi waipakue wenyewe.
- **Canva API / OAuth:** ikiwa unataka "Export to Canva" moja kwa moja badala ya kunakili prompt.
- **`npm run build` / lint:** zinapita (lint 0 errors, maonyo 12 ya zamani). **`flutter analyze` / `flutter test`** bado zinahitaji kuendeshwa kwenye kompyuta yenye Flutter SDK (sandbox haina).
- **Majaribio ya `firestore.rules`:** hakuna rules-test suite bado; deploy rules mpya baada ya kuyapitia.
- **Rotation za usalama:** `docs/SECURITY_ROTATION.md` bado inasubiri hatua za mkono.

---

## 6. Matumizi ya haraka (Kiswahili)

1. Mpe kila kiongozi akaunti: **Daftari la Waumini → "Akaunti za Viongozi" → + Ongeza**. (Lazima mhusika awe amejisajili kwanza kwenye app.)
2. Waambie waandike matukio: **Studio ya Poster & Matukio → "A. Andika Tukio Jipya"** (au app: Profaili → *Tuma Tukio / Omba Poster*).
3. Wewe (Super Admin): fungua **Studio ya Poster & Matukio**, kwenye **"B. Folio..."** bonyeza **"Tengeneza Poster"**.
4. Chagua rangi/ukubwa → **Pakua Picha ya HD** → **Shiriki WhatsApp** (au **Prompt ya Canva**).
5. Bonyeza **"Weka: Imetengenezwa"** — hali inarudi kwa viongozi wote mara moja.
