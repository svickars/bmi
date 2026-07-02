# BMI — Mac Setup Checklist

Use this checklist when you're back on your Mac to build, run on your iPhone, and ship to TestFlight.

**Repo:** https://github.com/svickars/bmi  
**Bundle ID:** `com.bigmacindex.bmi`  
**CloudKit container:** `iCloud.com.bigmacindex.bmi`  
**Marketing site:** https://bmi.bysam.fun  
**GitHub Pages source:** `/docs` on `main`

---

## Phase 1 — Code on your Mac

- [ ] Install **Xcode 15+**
- [ ] Clone: `git clone https://github.com/svickars/bmi.git && cd bmi`
- [ ] Check out `main` (merge [PR #1](https://github.com/svickars/bmi/pull/1) if not merged yet)
- [ ] Open **`BMI/BMI.xcodeproj`**

---

## Phase 2 — Apple Developer Portal

Portal: https://developer.apple.com/account

- [ ] **Identifiers → App IDs** → register **`com.bigmacindex.bmi`** if missing
- [ ] Enable capabilities on the App ID:
  - [ ] Sign in with Apple
  - [ ] iCloud (include CloudKit)
  - [ ] Push Notifications
- [ ] Confirm iCloud container **`iCloud.com.bigmacindex.bmi`** is linked to the App ID
- [ ] **Identifiers → App IDs → Sign in with Apple** — no separate Services ID needed for native-only sign-in
- [ ] Register your iPhone (Xcode usually auto-registers on first run)

> **Expo → native note:** There is no EAS. Signing is handled in Xcode with your Apple Developer Team.

---

## Phase 3 — Xcode signing & capabilities

Target **BMI** → **Signing & Capabilities**:

- [ ] Select your **Team** (`DEVELOPMENT_TEAM` is blank in the repo until you set it)
- [ ] Bundle identifier: **`com.bigmacindex.bmi`**
- [ ] Capabilities present (should match `BMI/BMI.entitlements`):
  - [ ] Sign in with Apple
  - [ ] iCloud → CloudKit → `iCloud.com.bigmacindex.bmi`
  - [ ] Push Notifications
  - [ ] **Associated Domains** → `applinks:bmi.bysam.fun`
- [ ] Build for **iPhone Simulator** once to verify compile

---

## Phase 4 — CloudKit Dashboard

Portal: https://icloud.developer.apple.com/ → container **`iCloud.com.bigmacindex.bmi`**

Work in **Development** first. Promote to **Production** before App Store / external TestFlight.

### Record types & indexes

| Record type | Queryable / sortable fields |
|-------------|----------------------------|
| `PublicUser` | `normalizedUsername` (Queryable) |
| `PublicReport` | `createdAt` (Sortable), **`authorAppleUserID` (Queryable)** |
| `PublicReportPhoto` | `reportID` (Queryable) |
| `FriendConnection` | `fromAppleUserID`, `toAppleUserID`, `status` (Queryable) |
| `UserNotification` | `recipientAppleUserID` (Queryable), `createdAt` (Sortable) |
| `ReportReaction` | `reportID` (Queryable) |

- [ ] Create all record types with fields matching `BMI/BMI/Services/CloudKitSchema.swift`
- [ ] Set indexes above
- [ ] **Deploy Schema to Development**
- [ ] After testing, **Deploy to Production**

---

## Phase 5 — Universal links (Associated Domains)

The app handles:

- `https://bmi.bysam.fun/report/{report-uuid}`
- `https://bmi.bysam.fun/u/{username}`

Hosted files (in repo `docs/`):

- [ ] `docs/.well-known/apple-app-site-association`
- [ ] Replace **`TEAMID`** in that file with your 10-character Apple Team ID (Xcode → target → Signing → Team → click (i) or Membership details)
- [ ] Verify AASA is live: `curl -I https://bmi.bysam.fun/.well-known/apple-app-site-association`  
  Should return **200** over HTTPS (GitHub Pages serves it as `application/json` in most cases; Apple accepts this)

---

## Phase 6 — GitHub Pages + Porkbun DNS

### GitHub

- [ ] Merge latest code to **`main`**
- [ ] Repo **Settings → Pages**
  - Source: **Deploy from a branch**
  - Branch: **`main`** / folder **`/docs`**
- [ ] **Custom domain:** `bmi.bysam.fun` (GitHub adds this to `docs/CNAME` — already in repo)
- [ ] Wait for DNS check → GitHub shows **DNS check successful** + HTTPS enabled (can take up to 24h)
- [ ] Confirm site loads: https://bmi.bysam.fun

### Porkbun (bysam.fun)

Log in at https://porkbun.com → **Domain Management** → **bysam.fun** → **DNS**

Add a **CNAME** record for the subdomain:

| Type | Host | Answer | TTL |
|------|------|--------|-----|
| CNAME | `bmi` | `svickars.github.io` | 600 (or default) |

- [ ] Save record
- [ ] Do **not** add a conflicting A record on `bmi` — CNAME only
- [ ] Optional: root `bysam.fun` can stay on Porkbun parking or point elsewhere for your portfolio later

> **Why `svickars.github.io`?** Project Pages for `svickars/bmi` with a custom subdomain CNAME to `username.github.io` (not `username.github.io/bmi`).

### After DNS propagates

- [ ] https://bmi.bysam.fun — landing page
- [ ] https://bmi.bysam.fun/privacy.html — privacy policy
- [ ] https://bmi.bysam.fun/support.html — support
- [ ] https://bmi.bysam.fun/u/demo — web fallback (opens app if installed)
- [ ] https://bmi.bysam.fun/report/{uuid} — report web fallback

---

## Phase 7 — Optional FRED API key

- [ ] Get key: https://fred.stlouisfed.org/docs/api/api_key.html
- [ ] Set in **`BMI/BMI/Info.plist`** → `FRED_API_KEY`
- [ ] Do **not** commit a real key to git (use local-only override or xcconfig)

Without a key, bundled US CPI fallback still works.

---

## Phase 8 — Run on your iPhone (fastest preview)

- [ ] Sign into **iCloud** on the iPhone (Settings → Apple ID → iCloud)
- [ ] Connect iPhone via USB → select device in Xcode → **Run** (⌘R)
- [ ] Trust developer cert: Settings → General → VPN & Device Management
- [ ] Allow **Location**, **Photos**, **Notifications** when prompted
- [ ] Flow: Sign in with Apple → choose username → create a public report → Profile → **Sync Now**

### Smoke test

- [ ] Feed shows synced community reports
- [ ] Tap author name → public profile page
- [ ] Share button on report → link `https://bmi.bysam.fun/report/...`
- [ ] Second Apple ID / device: add friend, tag, react → Notifications inbox
- [ ] Push notification tap opens the report (physical device recommended)
- [ ] Settings → Delete Account (test on a throwaway Apple ID first)

---

## Phase 9 — TestFlight

- [ ] **App Store Connect** → **My Apps** → **+** New App  
  - Platform: iOS  
  - Name: **The Big Mac Index**  
  - Bundle ID: `com.bigmacindex.bmi`  
  - SKU: e.g. `bmi-ios`
- [ ] **Privacy Policy URL:** https://bmi.bysam.fun/privacy.html  
- [ ] **Support URL:** https://bmi.bysam.fun/support.html  
- [ ] **Marketing URL:** https://bmi.bysam.fun  
- [ ] Xcode → **Product → Archive** → **Distribute App** → App Store Connect
- [ ] App Store Connect → **TestFlight** → add internal testers
- [ ] Promote CloudKit schema to **Production** before external testers
- [ ] For **external** TestFlight / App Store: complete App Privacy questionnaire, screenshots, 1024×1024 icon

See **`docs/APP_STORE.md`** for copy-paste metadata templates.

---

## Phase 10 — App Store review prep

- [ ] **App icon** — add 1024×1024 PNG to `Assets.xcassets/AppIcon` (starter icon included in repo)
- [ ] **Account deletion** — Settings → Delete Account (implemented in app)
- [ ] **Sign in with Apple** — if users can create accounts, deletion must be offered in-app ✓
- [ ] Revoking Sign in with Apple: users can also revoke in iOS Settings → Apple ID → Sign in with Apple
- [ ] Export compliance: standard HTTPS-only networking → typically "No" for custom encryption
- [ ] Age rating questionnaire in App Store Connect
- [ ] Screenshots: 6.7" and 6.5" iPhone (Feed, Map, Report, Stats, Profile)

---

## Phase 11 — GitHub repo housekeeping

- [ ] Merge feature branch → `main`
- [ ] Enable GitHub Pages from `/docs` (Phase 6)
- [ ] Add repo description + topics: `ios`, `swiftui`, `cloudkit`, `big-mac-index`
- [ ] Optional: branch protection on `main`

---

## Expo vs native quick reference

| Expo / EAS | Native BMI |
|------------|------------|
| `eas build` | Xcode **Archive** → Upload |
| `eas submit` | App Store Connect / Transporter |
| Expo push tokens | CloudKit subscriptions + APNs |
| `app.json` permissions | `Info.plist` usage descriptions |
| OTA updates | TestFlight / App Store releases |

---

## Troubleshooting

| Problem | Likely fix |
|---------|------------|
| CloudKit errors on sync | Schema not deployed, or missing queryable indexes |
| Username registration fails | `normalizedUsername` not queryable on `PublicUser` |
| Push never arrives | Physical device, iCloud signed in, notifications allowed, Development APNs entitlements |
| Universal link opens Safari only | AASA not reachable, wrong Team ID in AASA, Associated Domains capability missing, reinstall app after entitlement change |
| GitHub Pages 404 on `/report/...` | DNS not propagated yet, or Pages not enabled on `/docs` |
| Porkbun DNS not resolving | Wait 5–30 min; confirm CNAME `bmi` → `svickars.github.io` with no trailing dot issues |

---

## Support links (live after Phase 6)

- Home: https://bmi.bysam.fun  
- Privacy: https://bmi.bysam.fun/privacy.html  
- Support: https://bmi.bysam.fun/support.html  
