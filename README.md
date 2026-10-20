# Wall Tap

An Android wallpaper manager and home screen widget application built with Flutter and Kotlin. Wall Tap schedules automated wallpaper changes, organizes wallpapers into albums, and provides interactive launcher widgets for cycling wallpapers and photos directly from the home screen.

---

## Features

- **Studio**: Manual wallpaper rotation with tactile feedback, current wallpaper preview, automated interval scheduling (1m, 3m, 5m, 10m, 15m, 30m, 45m, 1h, 3h, 6h, 12h, 24h), target screen selection (Home, Lock, Both), and image scaling modes (Center Crop, Fit, Full).
- **Library & Custom Albums**: Multi-column wallpaper grid with resolution tags, batch selection mode (batch include, exclude, delete), and custom album management.
- **Home Screen Widgets**:
  - **Wall Tap Shuffle**: Launcher widget displaying a preview of the upcoming wallpaper with a one-tap shuffle button.
  - **Album Display Widget**: Launcher photo frame displaying photos from a selected album with on-widget controls for manual advancing and automated background rotation.
- **Full-Screen Preview**: Pan and pinch zoom from 1.0x to 5.0x, double-tap zoom to 2.5x, file metadata display, and one-tap wallpaper setting.
- **Background Reliability**: Android `AlarmManager` exact wakeup alarms (`RTC_WAKEUP`), device reboot recovery (`BOOT_COMPLETED`), and battery optimization exemption requests.

---

## Technical Stack & Architecture

- **Flutter & Dart**: Material 3 presentation layer, `ChangeNotifier` state management, custom touch feedback (`PressableScale`), and dark theme tokens.
- **Kotlin Android Native Layer**:
  - `WallpaperManager` screen targeting (`FLAG_SYSTEM`, `FLAG_LOCK`).
  - Sampled bitmap decoding (`inSampleSize`) to prevent out-of-memory errors on 4K and 8K wallpapers.
  - Native `AppWidgetProvider` implementations for launcher widgets.
  - Storage Access Framework folder picker (`ACTION_OPEN_DOCUMENT_TREE`).
  - `AlarmManager` exact scheduling and Doze mode compatibility.
- **Inter-Process Communication**: Typed `MethodChannel` (`com.walltap.app/wallpaper`) and synchronized `SharedPreferences` (`FlutterSharedPreferences`).

---

## Documentation Index

Detailed architectural and technical guides are located in the [`docs/`](docs/) directory:

| Document | Title | Description |
| :--- | :--- | :--- |
| [**01**](docs/01-architecture.md) | [System Architecture & Bridge](docs/01-architecture.md) | Architecture layers, component responsibilities, `MethodChannel` specification, and sequence diagrams. |
| [**02**](docs/02-android-native-integration.md) | [Android Native Integration](docs/02-android-native-integration.md) | Kotlin implementation, `WallpaperHelper`, AppWidgets, exact alarms, SAF picker, and permissions. |
| [**03**](docs/03-state-management-and-storage.md) | [State Management & Storage](docs/03-state-management-and-storage.md) | `WallpaperController`, lifecycle synchronization, `SharedPreferences` key registry, and file storage. |
| [**04**](docs/04-features.md) | [Application Features & User Flows](docs/04-features.md) | User workflows for Studio, Library, Albums, Widgets, Settings, and interactive dialogs. |
| [**05**](docs/05-ui-and-design-system.md) | [UI Architecture & Design System](docs/05-ui-and-design-system.md) | Color tokens, typography scale, bottom navigation bar specifications, and touch feedback. |
| [**06**](docs/06-testing-guide.md) | [Testing Strategy & Quality Assurance](docs/06-testing-guide.md) | Test suite breakdown (73 tests), test fakes pattern, unit/widget tests, and commands. |
| [**07**](docs/07-developer-guide.md) | [Developer Setup & Build Guide](docs/07-developer-guide.md) | Environment setup, physical device debugging, release APK/AAB builds, and troubleshooting. |
| [**08**](docs/08-ai-agent-guidelines.md) | [AI Agent Development Guidelines](docs/08-ai-agent-guidelines.md) | Architecture invariants, platform channel stability, memory bounds, and coding standards. |

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.12.2`
- Android SDK (API level 21 to 34, JDK 17)

### Installation & Execution

```bash
# Clone repository
git clone <repository_url>
cd wall_tap

# Install dependencies
flutter pub get

# Run test suite
flutter test

# Run application on a connected Android device or emulator
flutter run
```

---

## Automated Verification

Wall Tap includes automated unit and widget tests covering models, controller logic, and user interface components:

```bash
# Run all tests
flutter test

# Run static analysis
dart analyze
```

---

## Author

Developed by **Zavier Ferodova Al Fitroh**
