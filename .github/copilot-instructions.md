# AI Coding Guidelines for Énekeskönyv App

## Project Overview
This is a Flutter app for Hungarian Reformed hymn books (21-es kék and 48-as fekete énekeskönyv). The app displays hymns with musical scores (SVG) and text, supports offline usage, and includes search, favorites, and sharing functionality.

## Architecture & Data Flow

### Core Components
- **HomePage** (`lib/home/home_page.dart`): Main screen with hymn list, search access, and cues
- **SongPage** (`lib/song/song_page.dart`): Displays individual hymns with scores and navigation
- **SearchPage** (`lib/search_page.dart`): Text search and jump-to-song functionality
- **CuesPage** (`lib/cues/cues_page.dart`): Manages favorite verses and custom lists
- **SettingsProvider** (`lib/settings_provider.dart`): Centralized state management using Provider

### Data Structure
- Hymn data: `assets/enekeskonyv.json` (loaded into global `songBooks` map)
- Scores: SVG files in `assets/ref21/` and `assets/ref48/` directories
- Settings: Persisted via SharedPreferences
- Cues: JSON-encoded lists stored in SharedPreferences

### Key Patterns
- **Book identification**: Use `Book.blue` (21-es) and `Book.black` (48-as) enums
- **Verse IDs**: Format `"book.song.verse"` (e.g., `"48.1.0"` for 48th book, song 1, verse 1)
- **Theme colors**: Blue for 21-es book, amber for 48-as book
- **Navigation**: Always use `MaterialPageRoute` with proper context
- **State management**: Access settings via `Provider.of<SettingsProvider>(context)` (use listen: false when outside the widget tree)

## Development Workflow

### Building & Running
```bash
flutter pub get
flutter run
```

### Testing
```bash
flutter test integration_test/integration_test.dart
```

### Wakelock
The app enables wakelock globally in `main.dart` to prevent screen sleep during hymn viewing.

## Code Conventions

### Hungarian Language
- All user-facing strings are in Hungarian
- Use Hungarian variable names for domain concepts (e.g., `enekeskonyv`, `versszak`)
- Error messages and UI text should be culturally appropriate

### Platform-Specific UI
- Use `Platform.isIOS` checks for Cupertino widgets
- iOS gets segmented controls, Android gets radio buttons
- iOS uses bouncing scroll physics

### Settings Management
- All settings changes go through `SettingsProvider` methods
- Use `notifyListeners()` after state changes
- Persist via `setPref()` helper method
- Access current settings via `Provider.of<SettingsProvider>(context)`, use listen: false when outside the widget tree

### Navigation & Deep Linking
- Handle app links in `HomePage.initDeepLinks()`
- Parse verse IDs using `parseVerseId()` utility
- Validate verse existence before navigation

### Search & Filtering
- Remove diacritics using `removeDiacritics()` from diacritic package
- Search is case-insensitive and ignores non-letter characters
- Jump mode: Parse "song.verse" format (e.g., "150,3")

### Score Display
- Three modes: `ScoreDisplay.all`, `ScoreDisplay.first`, `ScoreDisplay.none`
- SVG scores loaded dynamically based on book and song
- Scores can be toggled independently of text

### Error Handling
- Use `showError()` method for consistent error reporting
- Errors include email reporting functionality
- Graceful fallbacks for missing data

## File Organization
- `lib/main.dart`: App entry point and theme setup
- `lib/home/`: Home page components
- `lib/song/`: Song display and navigation
- `lib/cues/`: Favorites and list management
- `lib/utils.dart`: Data parsing utilities
- `assets/`: Static data and SVG scores

## Dependencies
- `provider`: State management
- `shared_preferences`: Data persistence
- `flutter_svg`: Score rendering
- `wakelock_plus`: Screen keep-alive
- `app_links`: Deep linking support
- `diacritic`: Text normalization

## Testing Approach
- Integration tests cover end-to-end navigation flows
- Test key interactions: song selection, verse navigation, settings changes
- Verify UI state after navigation and user actions</content>
<parameter name="filePath">c:\GitHub\enekeskonyv_app\.github\copilot-instructions.md