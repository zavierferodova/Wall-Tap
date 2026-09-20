# Wall Tap

<p align="center">
  <b>A sleek, high-performance Android wallpaper manager and interactive home screen widget suite built with Flutter & Kotlin.</b>
</p>

---

## Overview

**Wall Tap** turns your Android device into a dynamic gallery. Designed around an OLED-optimized dark aesthetic, Wall Tap lets you curate wallpaper collections, create custom albums, rotate home and lock screen wallpapers on scheduled intervals, and place interactive widgets on your Android launcher for instant shuffling.

```
┌─────────────────────────────────────────────────────────────┐
│  STUDIO       GALLERY       WIDGETS       SETTINGS          │
│                                                             │
│  • Instant Wallpaper Shuffle                                │
│  • Dual-Engine Architecture (Flutter UI + Kotlin Engine)    │
│  • Home Screen Widgets (Shuffle & Album Frame)              │
│  • Battery-Friendly Exact Alarms & Doze Mode Support        │
│  • Tactile Haptics & Glassmorphic OLED Design               │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Features

- **Studio Tab**: One-tap wallpaper shuffle with tactile haptics, live artwork preview, rotation interval slider (1 min to 24 hr / daily), target screen configuration (Home / Lock / Both), and scaling mode adjustments (Full / Crop / Fit).
- **Gallery & Custom Albums**: Fast two-column wallpaper grid with resolution tags, batch multi-selection mode (batch include, exclude, and delete), and custom album organization.
- **Home Screen Widgets**:
  - **Wall Tap Shuffle**: Launcher widget with upcoming wallpaper thumbnail preview, instant shuffle button, and pause/resume auto-rotation toggle.
  - **Album Display Widget**: Interactive home screen photo frame displaying albums of your choice with tap-to-reveal controls for manual photo skipping.
- **Interactive Full-Screen Preview**: Pan and pinch zoom up to 5x, double-tap 2.5x smart zoom, full resolution inspection, and one-tap "Set as Current Wallpaper".
- **Background Execution Reliability**: AlarmManager exact alarms (`RTC_WAKEUP`), reboot recovery (`BOOT_COMPLETED`), battery optimization exemption request, and persistent status notification.

---

## Tech Stack & Architecture

- **Flutter 3.12+ (Dart 3.12+)**: Pure Material 3 UI layer, `ChangeNotifier` state management, custom physics animations (`PressableScale`), and glassmorphism (`BackdropFilter`).
- **Kotlin Native Android Engine**:
  - `WallpaperManager` multi-screen flag integration (`FLAG_SYSTEM`, `FLAG_LOCK`).
  - Sampled bitmap decoding (`inSampleSize`) and memory-safe scaling to prevent OOM errors with 4K/8K images.
  - Native `AppWidgetProvider` implementations for interactive home screen widgets.
  - Storage Access Framework (SAF) folder picker (`ACTION_OPEN_DOCUMENT_TREE`).
  - `AlarmManager` exact scheduling and Doze mode handling.
- **IPC Bridge**: Strongly-typed `MethodChannel` (`com.walltap.app/wallpaper`) and synchronized `SharedPreferences`.

---

## Documentation Index

Comprehensive guides for human developers, open-source contributors, and AI agents are organized in the [`docs/`](docs/) directory:

| Document                                          | Title                                                                     | Description                                                                                                       |
| :------------------------------------------------ | :------------------------------------------------------------------------ | :---------------------------------------------------------------------------------------------------------------- |
| [**01**](docs/01-architecture.md)                 | [**System Architecture & Bridge**](docs/01-architecture.md)               | High-level architecture, component layers, `MethodChannel` API specification, and sequence diagrams.              |
| [**02**](docs/02-android-native-integration.md)   | [**Android Native Integration**](docs/02-android-native-integration.md)   | Deep dive into Kotlin engine, `WallpaperHelper`, AppWidgets, exact alarms, SAF picker, and permissions.           |
| [**03**](docs/03-state-management-and-storage.md) | [**State Management & Storage**](docs/03-state-management-and-storage.md) | `WallpaperController`, app lifecycle sync, exhaustive `SharedPreferences` key registry, and file storage.         |
| [**04**](docs/04-features.md)                     | [**Application Features & User Flows**](docs/04-features.md)              | Detailed walkthrough of Studio, Gallery, Albums, Widgets, Settings, and interactive dialogs.                      |
| [**05**](docs/05-ui-and-design-system.md)         | [**UI Architecture & Design System**](docs/05-ui-and-design-system.md)    | OLED dark color tokens, typography scale, glassmorphic navigation bar, and haptic physics.                        |
| [**06**](docs/06-testing-guide.md)                | [**Testing Strategy & Quality Assurance**](docs/06-testing-guide.md)      | Test suite overview, test fakes (`FakeStorageService`, `FakeWallpaperService`), unit/widget tests, and commands.  |
| [**07**](docs/07-developer-guide.md)              | [**Developer Setup & Build Guide**](docs/07-developer-guide.md)           | Environment prerequisites, running the app, debugging native code, building release APK/AAB, and troubleshooting. |
| [**08**](docs/08-ai-agent-guidelines.md)          | [**AI Agent Development Guidelines**](docs/08-ai-agent-guidelines.md)     | Invariants, dual-engine sync rules, memory bounds, hot reload policies, and guardrails for AI coding agents.      |

---

## Quickstart

### Prerequisites

- Flutter SDK `^3.12.2`
- Android SDK (API level 21 to 34, JDK 17)

### Installation & Run

```bash
# Clone repository
git clone <repository_url>
cd wall_tap

# Install dependencies
flutter pub get

# Run test suite
flutter test

# Run application on connected Android device or emulator
flutter run
```

---

## Quality Assurance

Wall Tap maintains automated tests covering model serialization, controller business logic, and UI screens:

```bash
# Run all tests
flutter test

# Run static analysis
dart analyze
```

---

## Creator

Developed by **Zavier Ferodova Al Fitroh**
