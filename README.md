# The Big Mac Index (BMI)

An iOS app inspired by [The Economist's Big Mac Index](https://www.economist.com/big-mac-index) — a crowdsourced tracker where users report the cost, quality, and context of McDonald's Big Mac meals around the world.

## Features

- **Report meals** — Log price, star rating, written review, and what you purchased (Big Mac, meal, fries, etc.)
- **Tag locations** — Auto-detect via GPS or enter manually, with location types: urban, suburban, rural, highway, airport, mall, downtown, tourist, train station
- **Tag friends** — Mention friends who shared the meal
- **Add photos** — Attach up to 5 photos per report
- **Global feed** — Browse all community reports with search and country filters
- **Interactive map** — See reports pinned worldwide with price and rating
- **Index statistics** — Visualize average Big Mac prices by country, sub-region, and location type, plus rating distribution
- **Profile** — View your submission history and friend network

## Requirements

- Xcode 15+
- iOS 17+
- iPhone or iPad

## Getting Started

1. Clone the repository
2. Open `BMI/BMI.xcodeproj` in Xcode
3. Select your development team under **Signing & Capabilities**
4. Build and run on a simulator or device (`⌘R`)

The app ships with sample seed data (15 global reports) on first launch so you can explore the feed, map, and charts immediately.

## Project Structure

```
BMI/
├── BMI.xcodeproj/          # Xcode project
└── BMI/
    ├── Models/             # SwiftData models (BigMacReport, UserProfile, etc.)
    ├── Services/           # Location, statistics, seed data
    ├── Views/              # SwiftUI screens and components
    ├── Extensions/         # Theme colors
    └── Assets.xcassets/    # App icon and accent color
```

## Architecture

| Layer | Technology |
|-------|------------|
| UI | SwiftUI |
| Persistence | SwiftData |
| Location | CoreLocation + CLGeocoder |
| Maps | MapKit |
| Charts | Swift Charts |
| Photos | PhotosUI |

## Creating a Report

Tap the **Report** tab (center + button) to open the submission form:

1. Select purchased items
2. Enter price and currency (auto-filled from country when using GPS)
3. Rate quality (1–5 stars)
4. Use **Use Current Location** or enter location details manually
5. Pick a location type
6. Add photos and a review
7. Tag friends (optional)
8. Tap **Submit**

## Statistics

The **Stats** tab aggregates all Big Mac variant reports and shows:

- Total reports, average rating, countries tracked
- Cheapest and priciest countries
- Bar charts by country, sub-region, or location type
- Rating distribution histogram

## Privacy

The app requests:

- **Location (When In Use)** — To tag McDonald's locations and infer country/region
- **Photo Library** — To attach meal photos to reports

All data is stored locally on device via SwiftData. A future backend sync layer (CloudKit or custom API) can be added for true multi-user aggregation.

## License

MIT
