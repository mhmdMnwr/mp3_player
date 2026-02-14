# mp3_player

MP3 player built with Flutter using:
- `bloc` (`Cubit`) for state management
- `just_audio` for playback
- `sqflite` for local persistence
- `file_picker` + `flutter_media_metadata` for importing local songs and artwork

This README explains setup, architecture, data/logic internals, and complete project data flow.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation & Run](#installation--run)
- [Project Structure](#project-structure)
- [1) High-Level Architecture](#1-high-level-architecture)
- [2) Data Layer (Detailed)](#2-data-layer-detailed)
- [3) State Layer (Detailed)](#3-state-layer-detailed)
- [4) How the Player Works Internally (Detailed Runtime)](#4-how-the-player-works-internally-detailed-runtime)
- [5) Brief Explanation of Other Important Files](#5-brief-explanation-of-other-important-files)
- [6) End-to-End Project Data Flow](#6-end-to-end-project-data-flow)
- [7) Notes and Extension Ideas](#7-notes-and-extension-ideas)
- [8) Dark Mode Toggle Feature (Detailed)](#8-dark-mode-toggle-feature-detailed)

---

## Features

- Import local `.mp3` files (single or multiple) from device storage.
- Extract and save embedded artwork from metadata.
- Persist library in local SQLite database.
- Play/pause/seek/next/previous with real-time progress updates.
- Mark/unmark songs as favorites.
- Open favorites quickly from bottom navigation or long-press on favorite button.
- Keep page UI in one shared shell (`IndexedStack`) for smoother tab switching.
- **Dark mode / light mode toggle** with smooth animated icon transition.

---

## Tech Stack

- Flutter (Dart)
- `bloc` (`Cubit`)
- `flutter_bloc`
- `just_audio`
- `sqflite`
- `file_picker`
- `flutter_media_metadata`
- `path_provider`
- `google_nav_bar`

---

## Prerequisites

Before running the project, make sure you have:

- Flutter SDK installed and added to PATH
- A configured Android/iOS emulator or physical device
- Required platform toolchains (`flutter doctor` should be clean enough to run your target)

---

## Installation & Run

1. Clone the repository.
2. Install dependencies:

```bash
flutter pub get
```

3. Run static analysis:

```bash
flutter analyze
```

4. Run app:

```bash
flutter run
```

5. Build debug APK (optional):

```bash
flutter build apk --debug
```

---

## Project Structure

```text
lib/
  core/
    data/
      model/audio_model.dart
      repo/audio_repo.dart
      service/local_storage.dart
    layout/main_layout.dart
    logic/
      player_cubit.dart
      player_state.dart
      theme_cubit.dart
    theme/
      app_colors.dart
      app_theme.dart
  features/
    player/presentation/
      player_page.dart
      widgets/
    all_audio/presentation/
      all_audio_page.dart
      widgets/
    favorite/presentation/
      favorite_page.dart
  main.dart
```

---

## 1) High-Level Architecture

The app is structured around one shared shell layout (`MainLayout`) that keeps a single `PlayerCubit` instance alive and switches tab content internally with `IndexedStack`.

Main layers:
- **Core Data** (`lib/core/data/...`): model + local DB service + repo abstraction
- **Core Logic** (`lib/core/logic/...`): `PlayerState` + `PlayerCubit`
- **Core Layout** (`lib/core/layout/main_layout.dart`): app shell, app bar, bottom navigation, tab switching
- **Feature UI** (`lib/features/.../presentation/...`): Player, All Audios, Favorites pages/widgets

---

## 2) Data Layer (Detailed)

### 2.1 `AudioModel`
File: `lib/core/data/model/audio_model.dart`

Represents one song in app memory.

Fields:
- `id`: DB row id (as `String` in app layer)
- `title`: song title
- `artist`: artist name
- `imagePath`: either asset path (`assets/...`) or local file path for extracted artwork
- `duration`: currently stored as a display string (e.g. `--:--`)
- `filePath`: absolute path to the song file on device
- `isFavorite`: favorite flag

Functions:
- `copyWith(...)`: immutable update helper used heavily by cubit to update favorite status and other fields without mutating objects.


### 2.2 `LocalStorageService`
File: `lib/core/data/service/local_storage.dart`

This class is the direct `sqflite` gateway.

Private constants:
- `_databaseName = audio_library.db`
- `_databaseVersion = 1`
- `_tableName = audios`
- `_defaultImagePath = assets/images/podcast.png`

Private field:
- `_database`: cached open DB instance (lazy-initialized)

Functions:

1. `Future<Database> get database`
- Returns already opened DB if available.
- Otherwise opens DB via `_initDatabase()` and caches it.

2. `Future<Database> _initDatabase()`
- Uses `getDatabasesPath()` + `path.join` to build DB file path.
- Opens DB with versioning.
- Creates table on first launch:
  - `id INTEGER PRIMARY KEY AUTOINCREMENT`
  - `title TEXT`
  - `artist TEXT`
  - `image_path TEXT`
  - `duration TEXT`
  - `file_path TEXT UNIQUE`
  - `is_favorite INTEGER DEFAULT 0`

3. `Future<void> storeAudiosFromLocalFiles(List<AudioModel> audios)`
- Batch inserts all songs.
- Normalizes empty `imagePath` to default artwork.
- Uses `ConflictAlgorithm.replace` (same `file_path` replaces previous row).

4. `Future<List<AudioModel>> getAllSongs()`
- Reads all rows ordered by title (case-insensitive).
- Maps each DB row to `AudioModel` via `_mapToAudioModel`.

5. `Future<List<AudioModel>> getFavoriteSongs()`
- Reads only rows where `is_favorite = 1`.
- Ordered by title.
- Returns mapped `AudioModel` list.

6. `Future<void> setSongFavorite({required String songId, required bool isFavorite})`
- Converts `songId` from string to integer.
- Updates `is_favorite` for that row.
- Persists favorite toggle.

7. `AudioModel _mapToAudioModel(Map<String, Object?> row)`
- Handles row-to-model mapping.
- Normalizes old/empty image path to default artwork.
- Converts `is_favorite` int to bool.


### 2.3 `AudioRepo` + `AudioRepoImpl`
File: `lib/core/data/repo/audio_repo.dart`

`AudioRepo` is an abstraction boundary between logic and storage.

Interface methods:
- `storeAudiosFromLocalFiles(...)`
- `getAllSongs()`
- `getFavoriteSongs()`
- `setSongFavorite(...)`

`AudioRepoImpl`:
- Delegates to `LocalStorageService`.
- Wraps each operation in `try/catch` and throws contextual exceptions.
- Keeps `PlayerCubit` storage-agnostic.

---

## 3) State Layer (Detailed)

### 3.1 `PlayerState`
File: `lib/core/logic/player_state.dart`

`PlayerState` is immutable and represents full playback + library UI state.

Fields:
- `status`: `initial | loading | loaded | error`
- `songs`: main full library list
- `favoriteSongs`: cached filtered favorites list
- `currentIndex`: pointer to currently selected song in `songs`
- `isPlaying`: playback flag
- `position`: current playback position (`Duration`)
- `duration`: current song total duration (`Duration`)
- `errorMessage`: optional error text

Computed getters:
- `currentSong`:
  - Returns `songs[currentIndex]` when index is valid
  - Returns `null` when list is empty or index is invalid
- `hasSongs`: shorthand for `songs.isNotEmpty`

`copyWith(...)` behavior:
- Creates a new state with selected overrides.
- Supports `clearErrorMessage` to reset errors explicitly.


### 3.2 `PlayerCubit`
File: `lib/core/logic/player_cubit.dart`

`PlayerCubit` is the app's playback and library orchestrator.

#### Construction and lifetime

Factory:
- `factory PlayerCubit({required AudioRepo audioRepo})`
- Uses static `_instance` (singleton-style within app runtime).

Internal resources:
- `_audioRepo`: data source abstraction
- `_audioPlayer`: `just_audio` player
- Stream subscriptions:
  - `_audioPlayerStateSubscription`
  - `_positionSubscription`
  - `_durationSubscription`
- `_loadedSongIndex`: tracks which song source is currently loaded into player to avoid redundant `setFilePath`.

Constructor logic (`PlayerCubit._internal`):
1. Listen to player state stream:
   - If processing is completed, auto-calls `next()`.
   - Syncs `state.isPlaying` with the actual player `playing` flag.
2. Listen to `positionStream` and emit updated playback position.
3. Listen to `durationStream` and emit song duration (fallback `Duration.zero`).

---

### 3.3 Cubit Functions (Every Function Explained)

1. `loadSongs({String? selectedSongId, bool autoPlay = false})`
- Sets state to loading.
- Loads all songs via repo.
- Resolves selected index:
  - Default `0`
  - If `selectedSongId` exists in list, selects that index.
- Emits loaded state with:
  - `songs`
  - `favoriteSongs` (filtered from songs)
  - `currentIndex`
  - Reset play/position/duration defaults
- Clears `_loadedSongIndex` so correct source is loaded.
- Calls `_setCurrentSongSource()` if list not empty.
- If `autoPlay`, calls `play()`.
- On any exception: emits error state.

2. `storeAudiosFromLocalFiles(List<AudioModel> audios)`
- Persists imported songs to DB through repo.
- Calls `loadSongs()` to refresh in-memory state from DB.
- On error: emits error state.

3. `loadFavoriteSongs()`
- Sets loading status.
- Fetches favorites only via repo.
- Emits loaded state with updated `favoriteSongs`.
- Does not replace full `songs` list.
- On error: emits error state.

4. `toggleCurrentSongFavorite()`
- Reads `currentSong`; exits if null.
- Inverts favorite flag.
- Persists with `setSongFavorite(songId, isFavorite)`.
- Rebuilds `songs` list immutably, replacing only current song.
- Recomputes `favoriteSongs` from updated `songs`.
- Emits updated state.
- On error: emits error state.

5. `play()`
- Exits if no songs.
- Ensures audio source is loaded for current index.
- Calls `just_audio.play()`.
- Emits `isPlaying: true`.
- On error: emits error state and marks `isPlaying: false`.

6. `pause()`
- Exits if no songs.
- Calls `just_audio.pause()`.
- Emits `isPlaying: false`.

7. `seek(Duration position)`
- Exits if no songs.
- Calls `just_audio.seek(position)`.

8. `playPause()`
- Exits if no songs.
- Toggles: if playing => `pause()`, else => `play()`.

9. `selectSongById(String songId, {bool autoPlay = false})`
- Finds song index in `songs`.
- Exits if not found.
- Emits state with new `currentIndex` and target `isPlaying`.
- Forces source reload by resetting `_loadedSongIndex`.
- Loads source + seeks to start.
- Plays or pauses based on `autoPlay`.

10. `next()`
- Exits if no songs.
- Computes circular next index.
- Emits state with next index and `isPlaying: true`.
- Reloads source, seeks to start, plays.

11. `previous()`
- Exits if no songs.
- Computes circular previous index.
- Emits state with previous index and `isPlaying: true`.
- Reloads source, seeks to start, plays.

12. `_setCurrentSongSource()` (private)
- Reads `currentSong`; exits if null.
- If current index already loaded, exits early.
- Else calls `setFilePath(currentSong.filePath)`.
- Caches `_loadedSongIndex`.

13. `disposePlayer()`
- Cancels all stream subscriptions.
- Disposes `just_audio` player.
- Closes cubit.
- Resets static singleton `_instance`.

---

## 4) How the Player Works Internally (Detailed Runtime)

### Startup sequence
1. `main.dart` loads `MainLayout`.
2. `MainLayout.initState()` creates shared `PlayerCubit`.
3. Cubit subscriptions begin syncing `isPlaying`, `position`, `duration`.
4. `loadSongs()` pulls songs from SQLite.
5. First/current song source is prepared for playback.

### Playback sequence
1. User taps play in `PlayerPage`.
2. UI calls `playerCubit.play()`.
3. Cubit ensures source is loaded and starts `just_audio`.
4. Position and duration updates stream into state continuously.
5. Slider reads state and sends seeks back to cubit.

### End-of-track behavior
- `just_audio` processing state listener catches `completed` and calls `next()` automatically.

### Song selection from lists
1. User taps a song in All Audios or Favorites list.
2. Page calls `selectSongById(..., autoPlay: true)`.
3. Cubit loads selected source, seeks zero, plays.
4. Layout switches tab back to Playing view.

### Favorite behavior
1. Player favorite button tap -> `toggleCurrentSongFavorite()`.
2. Cubit updates DB and in-memory `songs` / `favoriteSongs`.
3. Favorites tab reads from `favoriteSongs`.
4. Entering Favorites tab triggers `loadFavoriteSongs()` refresh from DB.
5. Long-press on favorite button opens Favorites tab through the same bottom-nav tab logic.

---

## 5) Brief Explanation of Other Important Files

### `lib/main.dart`
- App entry point.
- Applies `AppTheme.lightTheme`.
- Uses `MainLayout` as `home`.

### `lib/core/layout/main_layout.dart`
- Shared shell for entire app (app bar + bottom navigation + body).
- Owns tab index (`_currentIndex`).
- Uses `IndexedStack` to keep tab widgets alive.
- Hosts and shares one `PlayerCubit` and one stream subscription.
- Handles special tab behavior:
  - Favorites tab loads favorites before showing.
  - Long-press favorite button maps to `_onTabChanged(2)`.

### `lib/features/player/presentation/player_page.dart`
- UI for current song, info, slider, controls.
- Fully driven by `PlayerState` and `PlayerCubit` passed from layout.

### `lib/features/player/presentation/widgets/audio_info.dart`
- Displays title/artist + favorite button.
- Tap: toggles favorite state callback.
- Long-press: opens favorites callback.

### `lib/features/player/presentation/widgets/audio_slider.dart`
- Displays and controls playback position.
- Receives state durations and emits seek events.

### `lib/features/all_audio/presentation/all_audio_page.dart`
- Handles local MP3 import.
- Extracts artwork from metadata (or uses fallback image).
- Persists imported songs through cubit/repo.
- Displays songs via shared list widget.

### `lib/features/all_audio/presentation/widgets/all_audio_list.dart`
- Reusable song list UI (used by All Audios and Favorites).
- Handles loading/error/empty/content states.

### `lib/features/favorite/presentation/favorite_page.dart`
- Reuses shared list widget.
- Builds a state projection where `songs = favoriteSongs`.
- Song tap plays selected song and returns to playing tab.

### `lib/features/player/presentation/widgets/bottom_navagationbar.dart`
- Styled `google_nav_bar` wrapper.
- Emits selected tab index to `MainLayout`.

### `lib/core/theme/app_colors.dart` and `lib/core/theme/app_theme.dart`
- `app_colors.dart` defines `AppColorsExtension` (a `ThemeExtension<AppColorsExtension>`) with two static palettes (`light` and `dark`). Also provides a `BuildContext` extension (`context.colors`) for quick access.
- `app_theme.dart` builds both `lightTheme` and `darkTheme` ThemeData objects using a shared `_buildTheme` factory, attaching the `AppColorsExtension` via `extensions: [colors]`.

---

## 6) End-to-End Project Data Flow

### Flow A: App Launch
`main.dart` → `MainLayout` → create `PlayerCubit` → `loadSongs()` → `AudioRepo` → `LocalStorageService` (SQLite) → emit `PlayerState.loaded` → UI renders Player.

### Flow B: Add Songs
`AllAudioPage` file picker + metadata extraction → create `AudioModel` list → `PlayerCubit.storeAudiosFromLocalFiles()` → repo/service insert batch into DB → `loadSongs()` refresh → state update → All Audios/Player reflect new list.

### Flow C: Play Song
UI action (`play`, `next`, `previous`, list tap) → cubit methods → `just_audio` actions (`setFilePath`, `play`, `seek`) → stream updates (`position`, `duration`, `isPlaying`) → UI rebuild.

### Flow D: Favorite Management
Favorite button tap in Player → `toggleCurrentSongFavorite()` → DB `is_favorite` update + in-memory update → favorites list refreshed in state.

### Flow E: Open Favorites
Bottom nav Favorites tab OR favorite-button long press → `MainLayout._onTabChanged(2)` → `loadFavoriteSongs()` → repo/service DB query (`is_favorite = 1`) → `FavoritePage` shows filtered list.

### Flow F: Toggle Dark / Light Mode
User taps the sun/moon icon in the AppBar → `ThemeCubit.toggleTheme()` → emits new `ThemeMode` → `BlocBuilder<ThemeCubit, ThemeMode>` in `main.dart` rebuilds `MaterialApp` with the new `themeMode` → Flutter automatically switches between `AppTheme.lightTheme` and `AppTheme.darkTheme` → all widgets that read `context.colors` re-render with the new palette.

---

## 7) Notes and Extension Ideas

- `duration` in `AudioModel` is display text; if needed, store raw milliseconds for richer filtering/sorting.
- For very large libraries, pagination or lazy loading can be added at service/repo level.
- `disposePlayer()` exists for controlled teardown if app architecture later requires explicit cubit disposal.

---

## 8) Dark Mode Toggle Feature (Detailed)

This section explains every layer involved in the dark mode toggle feature.

### 8.1 Color System Refactor

The old static `AppColors` class with `const` color values was replaced by `AppColorsExtension`, a proper Flutter `ThemeExtension<AppColorsExtension>`. This allows two separate palettes to coexist and be selected at runtime.

**File:** `lib/core/theme/app_colors.dart`

Key parts:

1. **`AppColorsExtension` class** — holds all 12 semantic color fields (`background`, `surface`, `card`, `accent`, `accentSoft`, `textPrimary`, `textSecondary`, `textDisabled`, `iconInactive`, `sliderInactive`, `error`, `success`).

2. **Two static palettes:**
   - `AppColorsExtension.light` — bright background, white surfaces, dark text.
   - `AppColorsExtension.dark` — dark background (`#121218`), dark surfaces (`#1E1E2A`), light text (`#E8E8F0`).

3. **`copyWith()`** and **`lerp()`** — required by `ThemeExtension` for hot-swap and animated theme transitions. `lerp` smoothly interpolates every color between light and dark.

4. **`AppColorsContext` extension on `BuildContext`** — adds `context.colors` shorthand so widgets access colors via one clean call instead of `Theme.of(context).extension<AppColorsExtension>()!`.

### 8.2 Theme Builder

**File:** `lib/core/theme/app_theme.dart`

A single `_buildTheme(AppColorsExtension colors, Brightness brightness)` factory produces a complete `ThemeData` from a given palette. Both `lightTheme` and `darkTheme` call the same factory with different palettes.

Important: each `ThemeData` registers the palette via `extensions: [colors]`, making it available through `Theme.of(context).extension<AppColorsExtension>()`.

### 8.3 ThemeCubit

**File:** `lib/core/logic/theme_cubit.dart`

```dart
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);

  bool get isDark => state == ThemeMode.dark;

  void toggleTheme() {
    emit(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
```

- State type is Flutter's `ThemeMode` enum (`light`, `dark`, `system`).
- Starts in `ThemeMode.light`.
- `toggleTheme()` flips between light and dark and emits the new value.
- `isDark` getter for quick checks.

### 8.4 Wiring in main.dart

```dart
BlocProvider(
  create: (_) => ThemeCubit(),
  child: BlocBuilder<ThemeCubit, ThemeMode>(
    builder: (context, themeMode) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: const MainLayout(),
      );
    },
  ),
)
```

- `BlocProvider` creates and provides one `ThemeCubit` at the top of the widget tree.
- `BlocBuilder` listens to `ThemeCubit` state changes.
- `MaterialApp.themeMode` is bound to the cubit's state.
- When `toggleTheme()` is called, `BlocBuilder` rebuilds `MaterialApp` with the new theme mode. Flutter internally picks `theme` or `darkTheme` based on that mode.

### 8.5 Toggle Button in MainLayout

In the AppBar's `actions`, an `IconButton` with `AnimatedSwitcher` displays:
- Sun icon (`Icons.light_mode_rounded`) when currently in dark mode (tapping switches to light).
- Moon icon (`Icons.dark_mode_rounded`) when currently in light mode (tapping switches to dark).

The animated transition uses a combined rotation + fade for a polished icon swap.

```dart
actions: [
  IconButton(
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return RotationTransition(
          turns: Tween(begin: 0.75, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Icon(
        themeCubit.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        key: ValueKey<bool>(themeCubit.isDark),
        color: colors.textPrimary,
      ),
    ),
    onPressed: themeCubit.toggleTheme,
  ),
],
```

The `key: ValueKey<bool>(themeCubit.isDark)` triggers `AnimatedSwitcher` to animate when the icon changes.

### 8.6 Widget Migration

Every widget that previously imported `AppColors` and used static constants like `AppColors.textPrimary` was updated to use `context.colors.textPrimary` instead. This means:
- Colors are resolved from the current `Theme` at build time.
- When the theme changes, all widgets automatically rebuild with the correct palette.

Widgets updated:
- `main_layout.dart` (AppBar title, background)
- `bottom_navagationbar.dart` (surface, shadow, nav colors)
- `audio_info.dart` (title, artist, favorite button colors)
- `audio_image.dart` (shadow, fallback card/icon colors)
- `audio_play_buttons.dart` (play button border, background, side button colors)
- `all_audio_header.dart` (button accent/surface)
- `all_audio_list.dart` (list item surface, text, fallback)

### 8.7 Summary Flow

```
User taps toggle icon
      │
      ▼
ThemeCubit.toggleTheme()
      │
      ▼
emit(ThemeMode.dark)  ◄──or──►  emit(ThemeMode.light)
      │
      ▼
BlocBuilder rebuilds MaterialApp
      │
      ▼
Flutter picks darkTheme or theme
      │
      ▼
AppColorsExtension.dark or .light attached to ThemeData
      │
      ▼
All widgets calling context.colors get new palette
      │
      ▼
UI re-renders with dark or light colors
```
