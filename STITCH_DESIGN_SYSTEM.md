# STITCH DESIGN SYSTEM: ZION FELLOWSHIP CHURCH
> Extracted directly from Google Stitch Project `11240858800146849531`
> Project Name: **Zion Fellowship Church App**
> Location: Mbagala Kwa Matope, Dar es Salaam, Tanzania
> Leadership: Askofu Mercy Mgala & James Robert

---

## 1. Design Vision & Movement
**Contemporary Warm Minimalism with Organic Tactility**:
- **Sanctuary Atmosphere**: Eliminates clinical stark whites, harsh neon accents, and cold blue tech undertones. Every surface feels illuminated by ambient dawn light, brushed linen, and polished clay.
- **Graceful Elevation**: Content cards float with airy, softened radiuses (16px–24px), organic boundaries, and translucent warm-toned scrims.
- **Spiritual Weight**: Classical, authoritative literary serif headings (`Newsreader`) paired with crisp humanist sans-serif (`Plus Jakarta Sans`) for modern mobile interfaces and scripture reading.
- **Mobile Native Architecture**: Tailored for Flutter, prioritizing thumb-zone ergonomics, tactile micro-interactions, pill chips, and an elevated floating dock.

---

## 2. Color Palette Tokens

### Accent & Brand Colors
- **Royal Sanctuary Violet / Purple**: `#6E39C4` / `#4B53BB` (Deep spiritual reverence, primary CTA buttons, logo stained-glass).
- **Warm Ochre & Sacred Gold**: `#C59B27` / `#B8860B` (Divine highlights, active navigation accents, giving confirmation badges).
- **Sunbaked Terracotta & Clay**: `#C06744` (Communal tags, prayer requests, interactive heart/bookmark toggles).
- **Aged Teak & Sandalwood**: `#8B5E34` (Scripture citations, metadata timestamps, subtle borders).

### Neutral & Surface Hierarchy
- **Deep Espresso Charcoal**: `#1E1B18` / `#332D28` (Ink-on-vellum typography, high-contrast headings, dark floating navigation pill).
- **Canvas Base**: `#FBF9F5` (Warm ivory / cream sanctuary base).
- **Module Panels / Neutral Cards**: `#F5EFEB` (Sand linen secondary container).
- **Elevated Dialogs & Cards**: `#FFFFFF` (Crisp alabaster pure white).
- **Translucent Floating Scrim**: `rgba(251, 249, 245, 0.88)` with `backdrop-filter: blur(20px)`.

---

## 3. Typography Hierarchy

| Style | Font Family | Size | Weight | Line Height | Letter Spacing | Usage |
|---|---|---|---|---|---|---|
| `display-lg` | Newsreader | 40px | 600 | 48px | -0.02em | Hero sermon headings |
| `display-mobile` | Newsreader | 30px | 600 | 38px | -0.015em | Mobile hero greetings |
| `headline-lg` | Newsreader | 28px | 600 | 36px | -0.01em | Major section titles |
| `headline-md` | Newsreader | 22px | 500 | 30px | Normal | Card headings |
| `scripture-quote` | Newsreader | 17px | 400 | 28px | Normal | Holy Bible Swahili / English text |
| `title-lg` | Plus Jakarta Sans | 18px | 600 | 24px | -0.01em | Section sub-headers |
| `body-lg` | Plus Jakarta Sans | 16px | 400 | 26px | Normal | Main paragraphs |
| `body-md` | Plus Jakarta Sans | 14px | 400 | 22px | Normal | Standard UI labels & descriptions |
| `label-lg` | Plus Jakarta Sans | 14px | 600 | 20px | +0.01em | Button CTAs, badge labels |
| `label-md` | Plus Jakarta Sans | 12px | 600 | 16px | +0.02em | Status chips, timestamp indicators |

---

## 4. Components & Micro-Interactions

### A. Floating Bottom Navigation Bar (Mobile Dock)
- Floating island dock hovering 16px above the screen bottom, inset 20px on left/right.
- Container: `rgba(30, 27, 24, 0.94)` (Dark silhouette) or `rgba(255, 255, 255, 0.92)` with `backdrop-filter: blur(20px)`.
- Destinations:
  1. **Nyumbani (Home)**
  2. **Vikundi (Home Cells)**
  3. **Sadaka (Giving)**
  4. **Biblia (Bible & Notes)**

### B. Quick Actions 2x2 Grid
- 16px border-radius sand linen containers (`#F5EFEB`).
- Linear 24px icon in warm violet/charcoal with two-line title & subtitle.

### C. Live Broadcast & Sermon Hero
- 24px border radius, 16:9 ratio, cinematic sanctuary background, red "MUBASHARA" pulse badge, live viewer count ("1.2K wanatazama"), sermon title in Newsreader serif, and primary purple "Tazama Moja kwa Moja" action button.

### D. Home Cell (Jumuiya) Portal Card
- Dedicated group container with meeting time (Ijumaa saa 11:00 jioni), venue, weekly verified offering, leader call button, and instant submission button: "Wasilisha Mahudhurio & Sadaka".

### E. Giving & Tithes (M-Pesa / TigoPesa / Benki)
- Real-time monthly collection transparency, project goal progress bar (Ujenzi wa Hekalu Kwa Matope), 1-tap Lipa Namba copy buttons, preset donation amounts (10k, 25k, 50k, 100k), and instant SMS/M-Pesa confirmation generator.

---

## 5. Screen Inventory from Stitch

1. **Zion Mobile - Karibu & Onboarding** (`6d287b9ddada409582a58e8f542a91c0`)
2. **Zion Mobile - Home Sanctuary & Ibada** (`16bc7b13c3bf46c68b576f7064ff10bc`)
3. **Zion Mobile - Biblia & Daftari la Mahubiri** (`d945b80f4f1e401591b018f1bca51275`)
4. **Zion Mobile - Vikundi vya Nyumbani & Maombi** (`3a018b4cf750491b9fbd9def9f1f57bf`)
5. **Zion Mobile - Sadaka, Zaka & Uwazi wa Fedha** (`d0c6ad5209e448918c46da2640de1906`)
6. **Zion Modern Stained-Glass Cross Logo** (`e7ab67d4ce7f483b8aeef1d28378ce92`)
7. **Bible Hero Ambient Artwork** (`a9e1fc777d2a43e0b78b21fdea872a61`)
8. **Zion Desktop - Pastoral Studio & Mahubiri Upload** (`4d69ca54acde457aa40c5edb45deccb4`)
9. **Zion Desktop - Ofisi ya Katibu Mkuu & Wazee wa Kanisa** (`42d57f545b4949f5bc70db0668ac68e3`)
10. **Zion Desktop - Usimamizi wa Kwaya & Idara za Kanisa** (`3c5478d72c354a3b9ee6190e2eb36c6b`)
