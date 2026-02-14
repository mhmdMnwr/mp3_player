# MP3 Player v2

A feature-rich, offline MP3 player built with Flutter. Scans your device for audio files via Android MediaStore, plays them with `just_audio`, and shows system media notification controls for play/pause/skip — all with zero file duplication.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Data Flow](#data-flow)
- [Audio Handler & Notification Controls](#audio-handler--notification-controls)
- [State Management](#state-management)
- [Theming](#theming)
- [Getting Started](#getting-started)
- [Permissions](#permissions)
- [Project Dependencies](#project-dependencies)

---

## Features

- **Device Audio Scanning** — Queries Android MediaStore via `on_audio_query` to discover all `.mp3` files on the device. No file copying or caching; plays directly from original paths.
- **Media Notification Controls** — Play, pause, skip next/previous from the Android notification bar and lock screen, powered by `audio_service`.
- **Favorites** — Tap the heart button to mark songs as favorites. Favorites are persisted in a lightweight SQLite database (stores only song IDs).
- **Dark / Light Theme** — Toggle between dark and light mode from the app bar. Themes use a custom `ThemeExtension` with semantic color tokens.
- **Animated Playback Controls** — Play/pause button with scale animation, side buttons (skip, shuffle, repeat) revealed with staggered entrance animations.
- **Album Artwork** — Displays embedded album art from MediaStore using `QueryArtworkWidget`, with `keepOldArtwork: true` to prevent flickering during playback updates.
- **Downloads Page (UI Only)** — Downloads tab is preserved as UI only. No download/link processing logic is connected.
- **Smooth Tab Switching** — Uses `IndexedStack` to keep all four pages alive (Player, All Audios, Favorites, Downloads) for instant tab switches without rebuilds.

---

## Tech Stack

| Layer | Library | Purpose |
|---|---|---|
| UI Framework | Flutter (Dart SDK ^3.10.8) | Cross-platform UI |
| State Management | `bloc` / `flutter_bloc` (^9.0.0) | Cubit-based reactive state |
| Audio Playback | `just_audio` (^0.9.46) | Low-level audio player |
| Notification Controls | `audio_service` (^0.18.17) | System media notification & lock screen controls |
| Media Query | `on_audio_query` (^2.9.0) | Android MediaStore song scanning & album art |
| Local Storage | `sqflite` (^2.4.1) | SQLite — stores favorite song IDs only |
| Navigation | `google_nav_bar` (^5.0.7) | Bottom navigation bar with animated tabs |
| Theming | Custom `ThemeExtension` | Semantic color tokens for light/dark themes |

---

## Architecture

### Project Structure

```
lib/
├── main.dart                              # Entry point — inits NotificationController, runs app
├── core/
│   ├── data/
│   │   ├── model/
│   │   │   └── audio_model.dart           # AudioModel data class
│   │   ├── repo/
│   │   │   └── audio_repo.dart            # AudioRepo — scans device songs, manages favorites
│   │   └── service/
│   │       └── local_storage.dart         # SQLite service — favorites table only
│   ├── layout/
│   │   └── main_layout.dart               # Scaffold + IndexedStack (Player, AllAudio, Favorites, Downloads)
│   ├── logic/
│   │   ├── audio_handler.dart             # AppAudioHandler — bridges just_audio ↔ audio_service
│   │   ├── notification_controller.dart   # Centralized notification/service bootstrap
│   │   ├── player_cubit.dart              # PlayerCubit — central playback state (singleton)
│   │   ├── player_state.dart              # PlayerState — immutable state class
│   │   └── theme_cubit.dart               # ThemeCubit — light/dark toggle
│   └── theme/
│       ├── app_colors.dart                # AppColorsExtension with light & dark palettes
│       └── app_theme.dart                 # ThemeData builders using AppColorsExtension
├── features/
│   ├── all_audio/
│   │   └── presentation/
│   │       ├── all_audio_page.dart         # Scan button + song list
│   │       └── widgets/
│   │           ├── all_audio_header.dart   # "Scan Audio" button
│   │           └── all_audio_list.dart     # ListView of songs with artwork thumbnails
│   ├── favorite/
│   │   └── presentation/
│   │       └── favorite_page.dart          # Filtered list of favorited songs
│   ├── download/
│   │   └── presentation/
│   │       └── download_page.dart          # Downloads UI page only (no download logic)
│   └── player/
│       └── presentation/
│           ├── player_page.dart            # Full player UI (artwork, info, slider, controls)
│           └── widgets/
│               ├── audio_image.dart        # Large artwork display (QueryArtworkWidget)
│               ├── audio_info.dart         # Song title, artist, favorite button
│               ├── audio_play_buttons.dart # Animated play/pause/next/prev/shuffle/repeat
│               ├── audio_slider.dart       # Seek slider with position/duration labels
│               └── bottom_navagationbar.dart # GNav bottom bar (Home, Audios, Favorites)
```

### Key Design Decisions

1. **Zero file duplication** — `on_audio_query` returns real file paths from Android MediaStore. The player reads files in place; nothing is copied to app storage.

2. **Singleton PlayerCubit** — Uses a factory constructor to ensure a single instance across the app. All three tabs share the same playback state.

3. **SQLite stores only favorite IDs** — Song metadata is always queried fresh from MediaStore on each scan. The database only persists which songs are favorited (`favorites` table with `song_id TEXT PRIMARY KEY`).

4. **AppAudioHandler as bridge** — `AppAudioHandler` extends `BaseAudioHandler` and wraps the `just_audio` `AudioPlayer`. It forwards playback state to the system notification and emits custom events (`skipToNext` / `skipToPrevious`) that `PlayerCubit` listens to.

5. **keepOldArtwork: true** — `QueryArtworkWidget` is configured to retain the previous artwork image while loading new artwork, preventing visible flickering during frequent rebuilds (e.g., every second from position stream updates).

---

## Data Flow

```
┌─────────────────────────┐
│   Android MediaStore     │
└───────────┬─────────────┘
            │  on_audio_query.querySongs()
            ▼
┌─────────────────────────┐       ┌───────────────────────┐
│     AudioRepoImpl       │◄─────►│  LocalStorageService  │
│  scans songs + merges   │       │  (favorites table)    │
│  favorite flags from DB │       └───────────────────────┘
└───────────┬─────────────┘
            │  List<AudioModel>
            ▼
┌─────────────────────────┐       ┌───────────────────────┐
│     PlayerCubit         │◄─────►│   AppAudioHandler     │
│  playback state,        │       │  wraps AudioPlayer    │
│  song selection,        │       │  + notification       │
│  position tracking,     │       │  controls bridge      │
│  favorites toggle       │       └───────────────────────┘
└───────────┬─────────────┘
            │  PlayerState (stream)
            ▼
┌─────────────────────────┐
│   UI Widgets            │
│  PlayerPage             │
│  AllAudioPage           │
│  FavoritePage           │
│  DownloadPage (UI only) │
└─────────────────────────┘
```

### Step-by-Step Runtime Flow

1. **App Startup** (`main.dart`):
   - `WidgetsFlutterBinding.ensureInitialized()`
  - `NotificationController.initialize()` creates the `AppAudioHandler` singleton and registers the foreground service
   - `runApp()` starts the widget tree

2. **MainLayout Initialization** (`main_layout.dart`):
   - Creates `PlayerCubit` (singleton) with `AudioRepoImpl` and `audioHandler`
   - Calls `playerCubit.loadSongs()` which triggers a full device scan

3. **Device Scan** (`audio_repo.dart`):
   - `OnAudioQuery.permissionsRequest()` asks for `READ_MEDIA_AUDIO` (Android 13+) or `READ_EXTERNAL_STORAGE` (Android 12-)
   - `OnAudioQuery.querySongs()` returns all songs from MediaStore
   - Filters to `.mp3` files only
   - Merges favorite IDs from SQLite
   - Returns `List<AudioModel>` with real file paths

4. **Playback** (`player_cubit.dart`):
   - `_setCurrentSongSource()` calls `AudioPlayer.setFilePath()` on the real MediaStore path
   - Calls `_audioHandler.setCurrentMedia()` to update the notification with title, artist, and duration
   - `play()` / `pause()` / `seek()` all delegate to the AudioPlayer through the handler
   - Position and duration streams emit state updates → UI rebuilds

5. **Notification Interaction**:
   - User taps play/pause in notification → `audio_service` calls handler's `play()` / `pause()` → updates player state
   - User taps next/prev → handler emits `customEvent` → `PlayerCubit` listens and calls `next()` / `previous()`

6. **Favorites** (`local_storage.dart`):
   - Toggling favorite calls `AudioRepo.setFavorite()` → inserts/deletes from `favorites` table
   - `PlayerCubit` updates both `songs` and `favoriteSongs` lists in state
   - Switching to Favorites tab calls `loadFavoriteSongs()` to refresh from DB

---

## Audio Handler & Notification Controls

The media notification is powered by `audio_service` through the `AppAudioHandler` class:

```dart
class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AppAudioHandler() {
    // Forward player events → notification state
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  // Update notification song info
  Future<void> setCurrentMedia({
    required String id,
    required String title,
    required String artist,
    required Duration duration,
  }) async {
    mediaItem.add(MediaItem(id: id, title: title, artist: artist, duration: duration));
  }

  // Notification controls → custom events → PlayerCubit
  Future<void> skipToNext() async => customEvent.add('skipToNext');
  Future<void> skipToPrevious() async => customEvent.add('skipToPrevious');
}
```

**Notification displays:** Previous | Play/Pause | Next — with song title, artist, and seek bar.

### Android Configuration Required

**MainActivity** must extend `AudioServiceActivity` (not `FlutterActivity`):

```kotlin
package com.example.mp3_player_v2

import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity()
```

**AndroidManifest.xml** entries:

```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Service -->
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true">
    <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
    </intent-filter>
</service>

<!-- Media button receiver -->
<receiver
    android:name="com.ryanheise.audioservice.MediaButtonReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
</receiver>
```

---

## State Management

The app uses **Cubit** (from the `bloc` package) for state management:

| Cubit | State | Responsibility |
|---|---|---|
| `PlayerCubit` | `PlayerState` | Playback control, song list, position tracking, favorites |
| `ThemeCubit` | `ThemeMode` | Light/dark theme toggle |

### PlayerState

```dart
class PlayerState {
  final PlayerStatus status;          // initial | loading | loaded | error
  final List<AudioModel> songs;       // All scanned songs
  final List<AudioModel> favoriteSongs; // Filtered favorites
  final int currentIndex;             // Currently selected song index
  final bool isPlaying;
  final Duration position;            // Current playback position
  final Duration duration;            // Total song duration
  final String? errorMessage;

  AudioModel? get currentSong => ...;
  bool get hasSongs => songs.isNotEmpty;
}
```

### AudioModel

```dart
class AudioModel {
  final String id;          // MediaStore song ID (as String)
  final String title;       // Song title from metadata
  final String artist;      // Artist name from metadata
  final String duration;    // Formatted as "MM:SS"
  final String filePath;    // Real file path from MediaStore (no copying)
  final int artworkId;      // MediaStore ID for QueryArtworkWidget
  final bool isFavorite;    // Merged from local SQLite favorites table
}
```

### PlayerCubit Key Methods

| Method | Description |
|---|---|
| `loadSongs()` | Scans device via `AudioRepo`, loads songs into state |
| `scanAndLoadSongs()` | Alias for `loadSongs()` — called from "Scan Audio" button |
| `play()` / `pause()` | Start/stop playback + update state |
| `next()` / `previous()` | Skip to next/previous song (wraps around) |
| `seek(Duration)` | Seek to position |
| `selectSongById(id)` | Jump to specific song (from list tap) |
| `toggleCurrentSongFavorite()` | Toggle favorite in DB + update state |
| `loadFavoriteSongs()` | Refresh favorite flags from DB |
| `playPause()` | Toggle play/pause |

---

## Theming

Custom `ThemeExtension<AppColorsExtension>` provides semantic color tokens accessible via `context.colors`:

| Token | Light | Dark |
|---|---|---|
| `background` | `#F6F7FB` | `#121218` |
| `surface` | `#FFFFFF` | `#1E1E2A` |
| `card` | `#F1F2F8` | `#272736` |
| `accent` | `#7C6CFF` | `#9B8CFF` |
| `accentSoft` | `#9B8CFF` | `#7C6CFF` |
| `textPrimary` | `#0E0E11` | `#E8E8F0` |
| `textSecondary` | `#55566B` | `#A0A0B8` |
| `textDisabled` | `#9A9AB0` | `#606078` |
| `iconInactive` | `#7A7A90` | `#7A7A90` |
| `sliderInactive` | `#E0E1EA` | `#3A3A4E` |
| `error` | `#FF4D4D` | `#FF6B6B` |
| `success` | `#4ADE80` | `#4ADE80` |

Toggle theme from the app bar icon button (animated sun/moon rotation). `ThemeCubit` emits `ThemeMode.light` or `ThemeMode.dark`.

---

## Getting Started

### Prerequisites

- Flutter SDK (Dart ^3.10.8)
- Android SDK (compileSdk 34)
- A physical Android device or emulator with audio files

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd mp3_player_v2

# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build release APK
flutter build apk --release
```

The release APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Permissions

On first launch, the app requests storage permissions to read audio files:

| Permission | API Level | Purpose |
|---|---|---|
| `READ_MEDIA_AUDIO` | Android 13+ (API 33) | Read audio files from MediaStore |
| `READ_EXTERNAL_STORAGE` | Android 12 and below (max SDK 32) | Legacy storage access |
| `FOREGROUND_SERVICE` | All | Media notification foreground service |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Android 14+ | Media playback foreground type |
| `POST_NOTIFICATIONS` | Android 13+ | Show notification controls |

---

## Project Dependencies

```yaml
dependencies:
  flutter: sdk
  cupertino_icons: ^1.0.8
  google_nav_bar: ^5.0.7
  sqflite: ^2.4.1
  path: ^1.9.1
  bloc: ^9.0.0
  flutter_bloc: ^9.0.0
  on_audio_query: ^2.9.0
  just_audio: ^0.9.46
  audio_service: ^0.18.17

dev_dependencies:
  flutter_test: sdk
  flutter_launcher_icons: ^0.14.3
  flutter_lints: ^6.0.0
```

---

## Local Storage Schema

Database: `audio_library.db` (version 2)

```sql
CREATE TABLE favorites (
    song_id TEXT PRIMARY KEY
);
```

Only favorite song IDs are persisted. All song metadata is queried from MediaStore at runtime. On upgrade from v1 (which stored full song data), the old `audios` table is dropped.

---

## License

This project is for personal/educational use.
