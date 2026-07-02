# The Big Mac Index (BMI)

An iOS app inspired by [The Economist's Big Mac Index](https://www.economist.com/big-mac-index) — a crowdsourced tracker where users report the cost, quality, and context of McDonald's Big Mac meals around the world.

## Features

- **Sign in with Apple** — Secure account identity for your reports
- **Report meals** — Log price, star rating, written review, and what you purchased
- **Tag locations** — Auto-detect via GPS or enter manually, with location types (urban, suburban, rural, highway, airport, mall, etc.)
- **Tag friends** — Mention friends who shared the meal
- **Add photos** — Attach up to 5 photos per report
- **Global feed** — Browse all community reports with search and country filters
- **Interactive map** — See reports pinned worldwide with price and rating
- **Currency normalization** — Compare global prices in your device locale currency, or pick a specific currency in Settings
- **Index statistics** — Charts by country, sub-region, and location type
- **Profile** — Your submission history, settings, and sign out

## Requirements

- Xcode 15+
- iOS 17+
- iPhone or iPad
- Apple Developer account (for Sign in with Apple capability)

## Getting Started

1. Clone the repository
2. Open `BMI/BMI.xcodeproj` in Xcode
3. Select your development team under **Signing & Capabilities**
4. Ensure **Sign in with Apple** capability is enabled (uses `BMI/BMI.entitlements`)
5. Build and run on a simulator or device (`⌘R`)

On first launch you'll see the Sign in with Apple screen. After signing in, 15 sample global reports load so you can explore the feed, map, and charts.

In **Debug** builds, a "Continue with Preview Account" button is available for simulator testing without an Apple ID.

## Data Storage & Sync

### Where is data stored today?

All app data is stored **locally on the device** using **SwiftData** (Apple's persistence framework, backed by SQLite). Typical location:

```
Library/Application Support/default.store
```

This includes:

| Data | Storage |
|------|---------|
| Big Mac reports | SwiftData (`BigMacReport`) |
| Photos | SwiftData as binary blobs (`ReportPhoto`) |
| User profile | SwiftData (`UserProfile`) |
| App settings | SwiftData (`AppSettings`) |
| Apple user ID (for session restore) | `UserDefaults` |

**Nothing is uploaded to a server yet.** Each device has its own copy of the data. The sample "community" reports are seeded locally after sign-in for demo purposes.

### What is CloudKit sync?

**CloudKit** is Apple's cloud database service, tied to a user's **iCloud account**. When SwiftData (or Core Data) is configured with a CloudKit container:

- Data syncs automatically across the user's iPhone, iPad, and Mac
- Changes made on one device appear on others signed into the same iCloud account
- Apple handles server infrastructure, conflict resolution, and encryption in transit/at rest
- No custom backend required for basic multi-device sync

CloudKit is **not enabled yet** in BMI. Adding it would look like:

```swift
ModelConfiguration(cloudKitDatabase: .automatic)
```

That would sync the signed-in user's reports and settings across their devices via iCloud. To share data **between different users** (a true global feed), you'd still need either:

- **CloudKit Public Database** — Apple-hosted shared records with per-user write access, or
- **Custom backend** — e.g. Firebase, Supabase, or a REST API with your own auth

### User authentication

| Aspect | Current implementation |
|--------|------------------------|
| Method | **Sign in with Apple** (`AuthenticationServices`) |
| Identity | Apple's opaque `user` identifier stored in `UserProfile.appleUserID` |
| Session | Credential state checked on launch via `ASAuthorizationAppleIDProvider` |
| Profile | Name/email captured on first sign-in; email may be hidden by Apple thereafter |
| Sign out | Clears local session; does not delete SwiftData records |
| Friends | Local demo profiles only — not linked to real Apple IDs yet |

Sign in with Apple provides privacy-friendly auth without managing passwords. The app never sees the user's Apple ID password.

## Currency Normalization

Stats and index comparisons convert all local prices into one **normalization currency**:

- **Default:** Device locale currency (`Locale.current.currency`)
- **Override:** Profile → Currency & Settings → pick any supported currency

Original local prices are always preserved on each report. Normalized values are computed on the fly using bundled approximate exchange rates (offline-friendly). Live rate fetching can be added later.

## Project Structure

```
BMI/
├── BMI.xcodeproj/
└── BMI/
    ├── Models/             # SwiftData models
    ├── Services/           # Auth, location, currency, statistics, seed data
    ├── Views/              # SwiftUI screens
    ├── Extensions/         # Theme colors
    ├── BMI.entitlements    # Sign in with Apple
    └── Assets.xcassets/
```

## Architecture

| Layer | Technology |
|-------|------------|
| UI | SwiftUI |
| Persistence | SwiftData (local; CloudKit-ready) |
| Auth | Sign in with Apple |
| Location | CoreLocation + CLGeocoder |
| Maps | MapKit |
| Charts | Swift Charts |
| Photos | PhotosUI |
| Currency | Bundled exchange rates → normalization at display time |

## Privacy

The app requests:

- **Location (When In Use)** — To tag McDonald's locations and infer country/region
- **Photo Library** — To attach meal photos to reports
- **Sign in with Apple** — To identify your account

## License

MIT
