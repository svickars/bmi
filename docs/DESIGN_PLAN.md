# BMI — UI Aesthetic Redesign Plan

**Goal:** Beli-adjacent structure and restraint, with BMI personality through red/yellow accents and intentional “splash moments” inspired by flat Big Mac poster art and no-logo billboard campaigns.

**Tone:** Understated daily UI · subtly delightful details · editorial confidence · non-AI

---

## 1. Design north star

### What we’re stealing from each reference

| Reference | Take | Avoid |
|-----------|------|--------|
| **Beli** (feed, lists, leaderboard) | White/cream canvas, generous spacing, serif display type, circular score badges, pill filters, photo-forward cards, thin borders | Copying navy/teal as primary — BMI uses red/yellow |
| **Flat Big Mac poster** (Cosmos) | Horizontal layer stack, geometric abstraction, sesame/bun/patty/cheese/lettuce palette | Literal copy that reads like McDonald’s official art |
| **No-logo billboards** (TBWA) | Macro product photography, bite-shaped crop, zero logo clutter, “you know what this is” confidence | Using McDonald’s trademark photography without license |
| **Beli Midyear Snack** | Shareable recap cards, sticker shadows, bold borders on *special* surfaces only, retro diner energy | Full-app retro styling — keep it to moments |

### One-line principle

> **Beli’s bones. BMI’s flavor. Red and yellow only where it earns attention.**

---

## 2. Design system (foundation)

Implement as `BMI/Design/` or extend `Color+Theme.swift` + new typography/components.

### Color palette

Keep existing tokens; add semantic aliases:

| Token | Hex (approx) | Use |
|-------|----------------|-----|
| `bmiPaper` | `#F5F1E3` | Main background (Beli cream, warmer than current `bmiCream` opacity hack) |
| `bmiSurface` | `#FFFFFF` | Cards, sheets |
| `bmiInk` | `#1A1A1A` | Primary text |
| `bmiMuted` | `#6B6B6B` | Secondary text |
| `bmiRed` | existing | Price, primary CTA, selected chips, chart bars |
| `bmiYellow` | existing | Stars, cheese accent, highlight stats |
| `bmiBrown` | existing | Bun/patty tone, subtle borders |
| `bmiGreen` | existing | “Cheapest” / success only (lettuce nod) |
| `bmiSesame` | `#F7E8C8` | Bun bands in layer illustration |
| `bmiPatty` | `#5C3D2E` | Layer illustration |
| `bmiCheese` | `#FFC72C` | Layer illustration + stat accent |
| `bmiLettuce` | `#3D8B40` | Layer illustration only |

**Rule:** Daily chrome is paper + ink + hairline borders. Red/yellow appear on **prices, CTAs, stars, and splash surfaces** — not on every section header.

### Typography

| Role | Font | Usage |
|------|------|--------|
| **Display** | Serif — e.g. **New York** (iOS system) or bundled **Instrument Serif** / **Fraunces** | Screen titles (“Feed”, “Index Stats”), sign-in headline, share cards |
| **UI** | **SF Pro** (system) | Body, lists, forms, metadata |
| **Data** | SF Pro **Rounded** or tabular nums | Prices, index numbers, stat grids |

**Beli pattern:** serif only for *moments* and top-level titles — not every label.

### Shape & elevation

| Element | Spec |
|---------|------|
| Card radius | 16pt (feed), 20pt (hero/splash) |
| Pill radius | full capsule |
| Borders | 1pt `bmiBrown.opacity(0.15)` on cards (Beli lists) — **not** heavy shadows |
| Shadows | Default: none. Splash/share cards: soft sticker shadow (`y: 4, blur: 12, opacity: 0.08`) |
| Photo radius | 12pt in feed, 16pt on detail hero |

### Core components (build once, reuse everywhere)

1. **`BMIScreenBackground`** — `bmiPaper` fill, ignores safe area
2. **`BMICard`** — white surface + hairline border, optional padding
3. **`BMIPillChip`** — Beli filter style: white bg, border, red fill when selected
4. **`BMIPriceBadge`** — Beli score circle: thin ring, price or index value centered, red text
5. **`BMIStarRating`** — keep stars, tighten spacing, yellow fill
6. **`BMILayerMark`** — SwiftUI `Canvas` or asset: 5–7 horizontal bands (poster abstraction)
7. **`BMIBiteMask`** — optional clip shape for hero photos (campaign nod — subtle, one corner)
8. **`BMISectionHeader`** — serif title + optional red rule underneath
9. **`BMIPrimaryButton`** — full-width red capsule, white label
10. **`BMIShareCard`** — snapshot-ready view for stats/recap (Midyear Snack energy)

---

## 3. Splash moments (priority surfaces)

These are the **designed** beats. Everything else stays quiet.

### A. Sign in (`SignInView`)

**Current:** full red/brown gradient + emoji  
**Target:** cream paper background, centered composition

- Top: `BMILayerMark` (flat poster stack) at ~40% width — **not** emoji
- Title: serif, “The Big Mac Index”
- Tagline: single line, muted SF Pro
- Sign in with Apple (standard)
- Optional: very subtle bite clip on bottom corner of layer mark

*Billboard nod:* confidence without logo — the layers *are* the brand.

### B. First report / post-submit celebration

After first successful public report:

- Full-screen or sheet overlay
- Macro-style **user’s photo** if present, else layer mark
- Copy: “Added to the index.” + location + price in `BMIPriceBadge`
- Single CTA: “View on map” or “Share”
- Dismissible — only shown once (UserDefaults flag)

*Billboard nod:* product-as-hero, no confetti, no generic “success!” illustration.

### C. Feed header (`HomeView`)

**Current:** gradient banner with stats  
**Target:** Beli-clean editorial header

```
The Index                    [search]
─────────────────            (red 2pt rule)
47 reports · 4.2★ · 12 countries
Normalized to CAD, today's dollars
```

- Remove gradient banner from daily feed (or demote to pull-to-reveal / once per session)
- Stats in one muted line; let **cards** carry color

### D. Report detail hero (`ReportDetailView`)

**Target:** billboard composition

- User photo edge-to-edge (if synced) with optional `BMIBiteMask` on trailing edge
- Floating overlay: location name (serif) + `BMIPriceBadge`
- Scroll reveals index comparison on cream card (keep economics block — it’s core product)
- Reactions row: emoji on white, minimal

*This is the highest-impact screen to redesign.*

### E. Index recap / share card (`StatisticsView`)

Beli **Midyear Snack** adapted to BMI:

- Trigger: Stats tab top card or seasonal prompt
- Layout: cream card, **thick border** (brown or red), sticker shadow
- Serif headline: “Your Big Mac Year” / “Index Snapshot”
- 2×2 stat blocks with red/yellow accents
- Optional `BMILayerMark` strip at bottom
- **ShareLink** → exports UIImage (like Beli IG story)

This becomes the marketing asset users post — aligns app ↔ site aesthetic.

### F. Map pin (`MapReportsView`)

**Current:** burger emoji + red pill  
**Target:** Beli map marker energy

- White speech-bubble pin, hairline border
- Red price text inside (bold)
- Tiny yellow star row below (optional)
- Selected state: red border ring

Remove emoji from pin — let price be the icon (no-logo confidence).

---

## 4. Screen-by-screen (daily UI)

### Tab bar (`MainTabView`)

Beli pattern:

- Paper background tab bar
- Center **Report** tab: elevated red circle with white `+` (not hidden tab hack)
- Active tab: red icon + label; inactive: muted gray
- SF Symbols: keep simple (`newspaper`, `map`, `chart.bar`, `person`)

### Feed (`HomeView` + `ReportCardView`)

Beli feed structure:

```
[avatar]  Jordan Lee · Tokyo          [¥890]
          Airport · 2d ago

[──────── photo 16:9 ────────]

Notes: Perfect sauce ratio...

🍔 Big Mac Meal          Japan · Tokyo
```

Changes:

- Card = white, border, no drop shadow
- Photo larger, consistent aspect ratio
- Price moves to **circle badge** top-right (Beli score)
- Review prefixed with **“Notes:”** bold label
- Author row tappable → profile
- Country filter chips → `BMIPillChip` style

### Create report (`CreateReportView`)

**Current:** stock `Form`  
**Target:** scroll of section cards (still native feel)

- Section cards on paper: “Order”, “Price & rating”, “Location”, “Photos”, “Friends”
- Interactive stars prominent (yellow, larger)
- Location type picker as horizontal icon pills
- Submit: sticky bottom `BMIPrimaryButton` “Add to the index”

### Stats (`StatisticsView`)

- Serif navigation title
- Normalization explainer → compact cream card with brown icon (not loud)
- Summary grid → Beli stat cards with colored SF Symbol (keep current logic, refine visuals)
- Charts → red gradient bars, minimal gridlines, white chart cards with borders
- **Share card** at top (splash moment E)

### Profile & social

- Profile header: large avatar circle on cream, serif name, `@username` muted
- Lists for Friends / Notifications / Settings — Beli list density, hairline separators
- Public profile: same header pattern + report feed reusing `ReportCardView`

### Auth onboarding (`UsernameSetupView`)

- Match sign-in: paper bg, serif “Choose your username”
- Green check for availability (keep)
- No gradient

### Settings / legal

- Stay functional (`Form` OK) but wrap in paper background + serif large title
- Delete account stays destructive red text — no splash

---

## 5. Landing page alignment (`docs/`)

After app redesign, update site to match:

| Site element | App counterpart |
|--------------|-----------------|
| Cream paper bg | `bmiPaper` |
| Serif app name | Sign-in title |
| Flat layer graphic | `BMILayerMark` (export SVG/PNG from app component) |
| Red TestFlight pill | `BMIPrimaryButton` |
| Footer | unchanged |

Remove emoji-as-logo on web; use exported layer mark or app icon.

---

## 6. Motion & micro-delights (subtle only)

| Moment | Animation |
|--------|-----------|
| Tab switch | none or 0.15s opacity |
| Map card slide-up | keep current ease |
| Report submit | layer bands stack in (0.4s stagger) on celebration sheet |
| Pull to refresh | custom layer mark rotates slightly (optional) |
| Price badge appear | scale 0.95 → 1.0 spring |

No parallax, no particle confetti, no haptic overload.

---

## 7. Implementation phases

### Phase 1 — Tokens & components (1 PR)
- `BMITypography`, expanded colors, `BMICard`, `BMIPillChip`, `BMIPriceBadge`, `BMIScreenBackground`
- Swap tab bar + global background

### Phase 2 — Feed & cards (1 PR)
- Redesign `ReportCardView`, `HomeView` header
- Map pins

### Phase 3 — Detail & create (1 PR)
- `ReportDetailView` hero
- `CreateReportView` card layout

### Phase 4 — Splash moments (1 PR)
- Sign-in redesign
- First-report celebration
- `BMILayerMark` + optional `BMIBiteMask`

### Phase 5 — Stats share card (1 PR)
- `IndexSnapshotCard` + share-to-image
- Stats tab polish

### Phase 6 — Profile, auth, site (1 PR)
- Profile/public profile headers
- Username setup
- `docs/index.html` sync

---

## 8. Assets to create

| Asset | Format | Notes |
|-------|--------|-------|
| **BMI mark** | SVG + PNG (`BMIMark` asset, `AppIcon.png`) | Sam's flat stripe artwork — favicon, app icon, in-app mark |
| Stripe takeover | SwiftUI `BMIBurgerStripesBackground` | Full-bleed moment backgrounds (sign-in, launch, photo-less heroes) |
| Bite mask | SwiftUI `BMIBiteClipShape` | Asymmetric corner bites on hero clips |
| Share card background | SwiftUI view | Rendered to image for share sheet *(deferred)* |
| App icon | ✅ `AppIcon.png` from BMI mark | 1024×1024 generated from master SVG |

**Legal:** Billboard references are *directional*. All shipped art should be original abstractions or user photos.

---

## 9. What we’re explicitly not doing

- Purple/blue AI startup gradients
- Emoji as the only avatar option (users can pick emoji **or** initials)
- Gradient headers on every screen
- Skeuomorphic burger UI chrome
- Literal McDonald’s logo or campaign asset reproduction
- Beli navy/teal as primary actions
- Over-animation

---

## 10. Success criteria (preview checklist)

When you run on device, it should feel:

- [x] **Beli-adjacent** in feed density, typography hierarchy, and photo prominence
- [x] **Understated** on settings, lists, and forms (paper background via `.bmiFormScreen()`)
- [ ] **Delightful** at sign-in, first report, report detail, and stats share *(first-report celebration deferred)*
- [x] **On-brand** via red price badges, yellow stars, layer mark — not red everywhere
- [x] **Cohesive** with `bmi.bysam.fun` after Phase 6
- [x] **Non-AI** — serif + paper + borders, not template cards with six emoji features

---

## 11. Decisions (confirmed)

| Decision | Choice |
|----------|--------|
| **Serif font** | **New York + San Francisco** — New York for display titles, SF Pro for UI/data |
| **Avatars** | User chooses **emoji OR initials**, plus a **background colour** from preset palette (`AvatarEditorView`) |
| **Feed header** | Editorial paper header — no gradient banner |
| **Bite mask** | **Yes** — subtle corner clip on report hero photos (`BMIBiteClipShape`) |
| **Index recap** | **Deferred** — nice annual/quarterly feature later; not in MVP UI |

These decisions are implemented on branch `cursor/ui-redesign-beli-8bf8`.
