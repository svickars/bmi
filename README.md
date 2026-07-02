# The Big Mac Index (BMI)

An iOS app inspired by [The Economist's Big Mac Index](https://www.economist.com/big-mac-index) — a crowdsourced tracker where users report the cost, quality, and context of McDonald's Big Mac meals around the world.

## Features

- **Sign in with Apple** with unique username registration
- **CloudKit public index** — reports, photos, profiles, and friend links sync globally
- **Live exchange rates** — Frankfurter API (current + historical per report date)
- **Today's dollars** — US CPI-U inflation adjustment (live via FRED when API key configured)
- **Friend linking** — search by username, accept requests, push notifications for incoming requests
- **Meal reporting** — price, rating, review, photos, location type, GPS, friend tags
- **Feed, map, stats** — normalized global comparisons

## Requirements

- Xcode 15+, iOS 17+
- Apple Developer account (Sign in with Apple, CloudKit, Push Notifications)
- iCloud signed in on device/simulator

## Getting Started

1. Open `BMI/BMI.xcodeproj`
2. Enable capabilities: Sign in with Apple, iCloud (CloudKit), Push Notifications
3. CloudKit container: `iCloud.com.bigmacindex.bmi`
4. Deploy CloudKit schema record types in [CloudKit Dashboard](https://icloud.developer.apple.com/):
   - `PublicUser` (includes `normalizedUsername`)
   - `PublicReport` (includes `photoCount`)
   - `PublicReportPhoto` (includes `imageAsset` CKAsset)
   - `FriendConnection`
5. Optional: add your [FRED API key](https://fred.stlouisfed.org/docs/api/api_key.html) to `Info.plist` as `FRED_API_KEY` for live CPI data
6. Build and run

## Architecture

| Layer | Technology |
|-------|------------|
| Local cache | SwiftData |
| Global sync | CloudKit Public Database |
| Photos | CKAsset on `PublicReportPhoto` records (JPEG compressed) |
| FX | Frankfurter API |
| Inflation | FRED CPI-U (live) + bundled fallback |
| Friend push | CloudKit subscriptions + APNs |
| Auth | Sign in with Apple + unique username |

## Key flows

### Photo sync
Reports upload metadata to `PublicReport`. Each photo becomes a `PublicReportPhoto` with a compressed JPEG `CKAsset`. Other users download photos during public sync.

### Username uniqueness
After Sign in with Apple, users choose a username checked against CloudKit `normalizedUsername` before joining the public index.

### Friend request notifications
CloudKit query subscriptions notify recipients when a pending friend request arrives. The app syncs connections and posts a local notification.

### Today's dollars
1. Historical FX converts local price → USD at report date (`usdAtReportDate`)
2. CPI inflation adjusts USD to today's purchasing power
3. Live FX converts to viewer's comparison currency

## Settings

Profile → Currency & Sync Settings:
- Device locale vs custom comparison currency
- Today's dollars toggle
- CloudKit sync toggle + manual sync
- Data source info (Frankfurter, FRED/bundled CPI)

## Privacy

- Location, Photo Library, Sign in with Apple, iCloud/CloudKit, Push Notifications

## License

MIT
