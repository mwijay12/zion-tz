# Demo credentials — Admin / Leadership Portal

*Ilisasishwa: 10 Novemba 2026*

## 🔑 Kuingia (demo)

| Sehemu | Thamani |
|---|---|
| **Barua pepe** | `demo@sayuni.local` |
| **Neno la siri** | `SayuniDemo2026` |
| **Wadhifa** | Chagua kwenye `Role when typing credentials` (default: **Super Admin**) |

AU bonyeza tu **"📝 Jaza fomu"** kwenye ukurasa wa kuingia, kisha **"Ingia Portal"**; au tumia vitufe vya haraka **👑 Super Admin**, **✝️ Askofu Mercy**, **📜 Katibu Mkuu**.

**Mahali pa kuingia:** https://sayuni-portal.vercel.app (production) · preview ya branch inatengenezwa kiotomatiki kila `git push`.

Katika `npm run dev` demo mode **inawaka yenyewe** (`import.meta.env.DEV`). Katika build iliyowekwa wingu (Vercel) inawaka kwa `VITE_DEMO_MODE=true` — nimekiweka kwenye Vercel project `sayuni-portal` kwa `production`, `preview`, na `development`.

## ⚠️ Maana ya demo (soma kabla ya kutumia)

- **SI akaunti ya Firebase.** Pair hii inakaguliwa kwenye browser tu; haijawahi kutumwa kwa Firebase Auth wala kuhifadhiwa kwenye server.
- Session ina `isDemo: true`. Ndiyo maana juu ya portal kuna **bendera ya njano** "HII NI DEMO YA NDANI TU".
- **Haiandiki Cloud Firestore.** `FirebaseChurchService.requireAuth()` inakataa maandishi yote bila akaunti halisi ya Firebase; `publishEvent`, `publishAnnouncement`, `markEventPosterReady`, kugawa vyeo n.k. vinakataliwa na ujumbe wazi.
- Data yote ni **sampuli / mock** kutoka `src/data/mockData.ts` na `localStorage` ya kivinjari hicho. Ukifunga kivinjari au kutumia kifaa kingine, hutaiona tena.
- **Usitumie data halisi ya wanachama** wala kusambaza kama toleo la uzalishaji.

## Kwa nini credentials ziko wazi kwenye ukurasa wa kuingia?

Kwa sababu **hazitoi ruhusa yoyote ya wingu**. Hazipaswi kufichwa kama siri; kuficha kungefanya watu wadhani ni akaunti halisi. Ulinzi halisi unakaa kwenye:

1. Firebase Auth + barua pepe iliyothibitishwa + custom claim `role` (`functions/setUserRole`), na
2. `firestore.rules` (inayosoma `request.auth.token.role` moja kwa moja), na
3. `requireAuth()` kwenye kila maandishi ya portal.

Akaunti halisi za viongozi hutolewa na Super Admin kupitia **Daftari la Waumini → Akaunti za Viongozi** (inaita Cloud Function `setUserRole`). Mhusika lazima awe amejisajili kwanza kwenye app.

## Kuzima demo kwenye production

Weka `VITE_DEMO_MODE=false` (au futa variable) kwenye *Vercel → sayuni-portal → Settings → Environment Variables*, kisha redeploy. `npm run dev` bado itaonyesha demo kwa ajili ya maendeleo ya ndani.

## Faili husika

| Faili | Kazi |
|---|---|
| `sayuni-portal/src/services/authService.ts` | `DEMO_CREDENTIALS`, `DEMO_MODE_ENABLED`, `isDemoCredentialPair()`, `loginAsDemo()` |
| `sayuni-portal/src/components/AuthModal.tsx` | Kadi ya credentials, "Jaza fomu", "Nakili", chaguo la wadhifa, vitufe vya haraka |
| `sayuni-portal/src/App.tsx` | Bendera ya njano `isDemo` juu ya portal |
| `sayuni-portal/.env.example` | `VITE_DEMO_MODE` (maelezo ya usanidi) |
