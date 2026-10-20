# AGENTS.md: Wall Tap Engineering Directives & Guidelines

Directives, architecture contracts, and operational standards for AI coding agents developing or maintaining Wall Tap.

---

## 1. Directives & Documentation Hierarchy

When working on this repository, resolve architectural, design, and implementation decisions using this hierarchy:

1. **System Architecture & Bridge**: [`docs/01-architecture.md`](docs/01-architecture.md) (Layers, MethodChannel API, sequence diagrams).
2. **Android Native Integration**: [`docs/02-android-native-integration.md`](docs/02-android-native-integration.md) (Kotlin engine, WallpaperHelper, AppWidgets, exact alarms, SAF picker).
3. **State Management & Storage**: [`docs/03-state-management-and-storage.md`](docs/03-state-management-and-storage.md) (WallpaperController, SharedPreferences registry, file storage, deletion cascades).
4. **Application Features**: [`docs/04-features.md`](docs/04-features.md) (Studio, Library, Albums, Widgets, Settings, dialog workflows).
5. **UI & Design System**: [`docs/05-ui-and-design-system.md`](docs/05-ui-and-design-system.md) and [`DESIGN.md`](DESIGN.md) (Color tokens, typography scale, bottom bar specs, haptics).
6. **Testing Strategy**: [`docs/06-testing-guide.md`](docs/06-testing-guide.md) (Fake services, unit/widget tests, coverage).
7. **Developer Guide**: [`docs/07-developer-guide.md`](docs/07-developer-guide.md) (Prerequisites, execution, release builds, troubleshooting).
8. **AI Agent Guidelines**: [`docs/08-ai-agent-guidelines.md`](docs/08-ai-agent-guidelines.md) (Invariants, memory safety, hot reload policy).

---

## 2. Engineering Directives

### 2.1 Trace Before Writing
- Inspect existing services (`StorageService`, `WallpaperService`), controllers (`WallpaperController`), and fakes before creating new abstractions.
- Never write code based on unverified assumptions.

### 2.2 Dual-Engine Synchronization
- Keys in `SharedPreferences` shared with Android native Kotlin must maintain the `"flutter."` prefix.
- Never add or rename a shared preference key without updating both Dart and Kotlin call sites.

### 2.3 Memory Safety
- High-resolution wallpapers can cause out-of-memory errors on Android devices.
- In Dart, decode dimensions via `instantiateImageCodec` without allocating raw pixel buffers.
- In Kotlin, always decode with `inJustDecodeBounds = true` before full allocation, use `RGB_565` for widget thumbnails, and explicitly recycle temporary bitmaps.

### 2.4 Documentation Synchronization
- When changing architecture, models, platform channels, or UI components, update the corresponding documentation in `docs/` and `DESIGN.md` in the same task.
- Code and documentation must remain synchronized.

---

## 3. Standard Verification Commands

Always run these commands to verify changes before concluding a task:

```bash
# 1. Run all unit and widget tests
flutter test

# 2. Run static analysis
dart analyze
```

<!-- antislop:start -->
## antislop
For UI, copy, people, mobile layout, or code comments work, load the antislop skill for the task:
- Core filter, always on: `antislop`
- UI / visual: `antislop-ui`
- Copy & text: `antislop-copywriting`
- People: `antislop-human`
- Mobile / responsive: `antislop-layoutmobile`
- Code comments: `antislop-code`
Before starting, ask the user when antislop applies: during the work, or after it is done.
<!-- antislop:end -->
