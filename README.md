# HexRun 🏃‍♂️⬡.............

A location-based territory capture game built with Flutter. Run in the real world to capture hexagonal territories on the map!

## Features

- **🗺️ Mapbox Map** - Interactive map with hex territory overlay
- **⬡ H3 Hex Grid** - Uber's H3 geospatial indexing for territory cells
- **📍 GPS Tracking** - Real-time location tracking during runs.
- **🏆 Territory Capture** - Claim hexes by running through them
- **📊 Leaderboard** - Compete with other players by XP and territory count
- **👤 Profile** - Track your stats, level, and run history
- **🔥 Firebase** - Authentication, Firestore database, Cloud Functions

## Tech Stack

| Layer            | Technology                            |
| ---------------- | ------------------------------------- |
| Frontend         | Flutter 3.x + Dart                    |
| State Management | Riverpod                              |
| Routing          | GoRouter                              |
| Map              | Mapbox Maps Flutter                   |
| Geospatial       | H3 Flutter                            |
| Backend          | Firebase (Auth, Firestore, Functions) |
| Location         | Geolocator                            |

## Project Structure

```
hexrun/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── core/
│   │   ├── config/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── theme/
│   │   ├── router/
│   │   ├── utils/
│   │   └── widgets/
│   └── features/
│       ├── auth/
│       ├── gps/
│       ├── territory/
│       ├── map/
│       ├── leaderboard/
│       └── profile/
├── functions/
│   ├── index.js
│   └── package.json
├── firestore.rules
├── pubspec.yaml
└── analysis_options.yaml
```

## Getting Started

### Prerequisites

- Flutter 3.x (Dart 3.x)
- Firebase project with Auth, Firestore, and Functions enabled
- Mapbox account with access token
- Google Maps API key (for H3 Flutter)

### Setup

1. **Install dependencies:**

   ```bash
   cd hexrun
   flutter pub get
   ```

2. **Configure Firebase:**

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

3. **Set up Mapbox:**
   - Get your access token from [mapbox.com](https://account.mapbox.com/)
   - Add it to `lib/core/config/app_config.dart`

4. **Deploy Cloud Functions:**

   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

5. **Deploy Firestore rules:**

   ```bash
   firebase deploy --only firestore:rules
   ```

6. **Run the app:**
   ```bash
   flutter run
   ```

## Game Mechanics

- **Capture:** Run through hexagonal cells to claim them as your territory
- **XP:** Earn 10 XP per hex captured + 5 XP per km distance bonus
- **Levels:** Every 500 XP = 1 level up
- **Contested:** Cells can be contested when multiple players are nearby
- **Leaderboard:** Ranked by total XP

## Architecture

- **Clean Architecture** with feature-first organization
- **Riverpod** for state management
- **Repository pattern** for data access
- **Firebase** as BaaS with Cloud Functions for server logic
- **H3** for geospatial hex grid calculations

## License

MIT
