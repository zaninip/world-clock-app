# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code for issues
flutter analyze

# Build APK for Android
flutter build apk

# Build for iOS
flutter build ios
```

## API Configuration

This app uses the GeoNames API for city search and timezone detection. The username `world_clock_app` is configured in:
- `lib/services/city_service.dart` (city search)
- `lib/services/location_service.dart` (timezone lookup)

## Architecture Overview

**State Management**: The app uses StatefulWidget with setState for state management. The main state is in `_WorldClockPageState` (lib/main.dart).

**Data Flow**:
1. On launch, `_loadInitialTime()` checks for saved favorites; if none, loads local timezone
2. City selection via search triggers `_onCitySelected()` which sets a "transient" city (not yet saved)
3. Favorites are managed through toggle action which persists to SharedPreferences

**Key Concepts**:
- **Transient City**: A city selected from search but not saved as favorite. Displayed separately from the favorites PageView.
- **Favorites Paging**: Up to 5 favorites displayed in a horizontal PageView with dot indicators
- **Fallback Timezone**: UTC/Greenwich Time when geolocation fails or is denied

**Services Layer** (`lib/services/`):
- `CityService`: GeoNames API search with in-memory caching
- `FavoritesService`: SharedPreferences persistence for favorite cities (max 5)
- `LocationService`: Device geolocation + GeoNames timezone lookup

**Custom Painting**: The analog clock (`lib/widgets/world_clock.dart`) uses `CustomPainter` with:
- Roman numerals positioned via trigonometry
- Three hands (hours, minutes, seconds) with shadow effects
- Vintage styling with gradient background and bronze border
