# The Big Mac Index (BMI)

An iOS app inspired by [The Economist's Big Mac Index](https://www.economist.com/big-mac-index) — a crowdsourced tracker where users report the cost, quality, and context of McDonald's Big Mac meals around the world.

## Features

- **Sign in with Apple** — Secure account identity for your reports
- **Global public index** — Reports sync to CloudKit's public database for real multi-user data
- **Live exchange rates** — Frankfurter API for current and historical FX on each report date
- **Today's dollars** — US CPI inflation adjustment so a meal logged today still compares fairly years later
- **Real friend linking** — Search by username, send/accept friend requests via CloudKit, tag friends in reports
- **Report meals** — Price, rating, review, photos (local), location type, GPS tagging
- **Feed, map, and stats** — Browse and visualize the global index with normalized comparisons

## Requirements

- Xcode 15+
- iOS 17+
- Apple Developer account with **Sign in with Apple** and **CloudKit** enabled
- iCloud signed in on device/simulator for public sync

## Getting Started

1. Open `BMI/BMI.xcodeproj` in Xcode
2. Set your development team under **Signing & Capabilities**
3. Enable capabilities (entitlements included):
   - Sign in with Apple
   - iCloud → CloudKit → container `iCloud.com.bigmacindex.bmi`
4. In [CloudKit Dashboard](https://icloud.developer.apple.com/), deploy schema record types:
   - `PublicUser`
   - `PublicReport`
   - `FriendConnection`
   (Fields match `CloudKitSchema.swift`)
5. Build and run (`⌘R`)

Debug builds include a preview account for simulator testing without Apple ID.

## Architecture

### Data layers

| Layer | Purpose |
|-------|---------|
| **SwiftData (local)** | Offline cache, photos, settings, friend links |
| **CloudKit Public DB** | Shared global reports, public profiles, friend requests |
| **Frankfurter API** | Live + historical exchange rates |
| **Bundled US CPI-U** | Inflation adjustment for "today's dollars" |

### How pricing normalization works

When someone submits a ¥890 Big Mac in Tokyo:

1. **Historical FX** — Frankfurter converts ¥890 → USD using the rate on the report date
2. **Snapshot stored** — `usdAtReportDate` saved on the report (and uploaded to CloudKit)
3. **Today's dollars** — When viewing later, US CPI adjusts that USD for inflation
4. **Display currency** — Adjusted USD converts to the viewer's locale or chosen currency using live rates

This means a $10 Big Mac logged today will show its inflation-adjusted equivalent when someone views the index a year from now — apples-to-apples across time and country.

### Multi-user public data

Each signed-in user registers a `PublicUser` record (username, display name). Reports upload as `PublicReport` records. All clients fetch the public database to build the global feed and statistics.

Photos remain local for now (CloudKit asset upload can be added later).

### Friend linking

1. Register a unique username (from Sign in with Apple profile)
2. Search friends by username in the public database
3. Send a `FriendConnection` request via CloudKit
4. Recipient accepts in **Profile → Friends**
5. Accepted friends appear in the report tagging picker

## Project Structure

```
BMI/
├── BMI.xcodeproj/
└── BMI/
    ├── Models/          # SwiftData models
    ├── Services/        # Auth, CloudKit sync, FX, inflation, stats
    ├── Views/           # SwiftUI screens
    ├── BMI.entitlements
    └── Assets.xcassets/
```

## Settings

**Profile → Currency & Sync Settings**

- **Use Device Locale** — Default comparison currency from iPhone region
- **Express in Today's Dollars** — CPI inflation adjustment (recommended ON)
- **Sync with CloudKit** — Toggle public index participation
- **Sync Now** — Manual refresh of global data

## Privacy

- Location (When In Use) — Tag McDonald's locations
- Photo Library — Attach meal photos (stored locally)
- Sign in with Apple — Account identity
- iCloud / CloudKit — Public report metadata sync

## License

MIT
