# 06 - Testing Strategy & Quality Assurance

This document outlines the testing architecture, fake services pattern, test execution commands, and guidelines for adding new automated tests in Wall Tap.

---

## 1. Test Suite Structure

The `test/` directory contains 10 test suites covering models, business logic controllers, and UI screens:

```
test/
├── album_model_test.dart               # Serialization, deserialization, and copyWith for Album
├── album_widget_config_test.dart       # Model tests for AlbumWidgetConfig (JSON & intervals)
├── wallpaper_model_test.dart           # Model tests for WallpaperItem (resolution, size formats)
├── wallpaper_controller_test.dart      # Business logic: shuffle, imports, albums, deletions, config
├── slideshow_tab_test.dart             # UI widget tests for Studio tab (shuffle, scale, interval)
├── playlist_tab_test.dart              # UI widget tests for Gallery tab (grids, multi-select)
├── album_detail_screen_test.dart       # UI widget tests for individual Album management screen
├── album_widgets_tab_test.dart         # UI widget tests for home screen widget manager tab
├── settings_tab_test.dart              # UI widget tests for Settings, battery optimization & attribution
└── wallpaper_preview_dialog_test.dart  # UI widget tests for zoom viewer and full-screen dialog
```

---

## 2. Test Architecture: Fakes vs Mocks

Rather than using dynamic reflection-based mocks that can become brittle, Wall Tap uses **test fakes** (`FakeStorageService` and `FakeWallpaperService`) extending the real classes.

### 2.1 FakeStorageService
In-memory storage fake that intercepts all disk and SharedPreferences calls:

```dart
class FakeStorageService extends StorageService {
  List<WallpaperItem> storedItems = [];
  List<Album> storedAlbums = [];
  String? storedActiveAlbumId;
  List<String> syncedPaths = [];
  SlideshowConfig storedConfig = const SlideshowConfig();
  int? storedNextIndex;
  String? storedCurrentWallpaperId;

  @override
  Future<List<WallpaperItem>> loadItems() async => storedItems;

  @override
  Future<void> saveItems(List<WallpaperItem> items, {List<String>? activePlaylistPaths}) async {
    storedItems = List.from(items);
    if (activePlaylistPaths != null) {
      syncedPaths = List.from(activePlaylistPaths);
    }
  }

  @override
  Future<SlideshowConfig> loadConfig() async => storedConfig;

  @override
  Future<void> saveConfig(SlideshowConfig config) async {
    storedConfig = config;
  }
  // ...
}
```

### 2.2 FakeWallpaperService
Intercepts `MethodChannel` invocations so tests can run on any host machine without Android engine binaries:

```dart
class FakeWallpaperService extends WallpaperService {
  bool setWallpaperCalled = false;
  String? lastSetWallpaperPath;
  String? lastTargetScreen;
  String? lastScaleType;

  @override
  Future<bool> setWallpaper({
    required String filePath,
    String targetScreen = 'both',
    String scaleType = 'full',
  }) async {
    setWallpaperCalled = true;
    lastSetWallpaperPath = filePath;
    lastTargetScreen = targetScreen;
    lastScaleType = scaleType;
    return true;
  }
}
```

---

## 3. Writing Unit & Controller Tests

When testing `WallpaperController`:
1. Instantiate `FakeStorageService` and `FakeWallpaperService`.
2. Pass fakes into the `WallpaperController` constructor.
3. Seed test state (e.g. `fakeStorage.storedItems = [...]`).
4. Call `await controller.initialize()`.
5. Execute controller methods and verify both internal state and fake side-effects.

Example:
```dart
test('shuffleNext advances wallpaper and saves active id', () async {
  final storage = FakeStorageService();
  final wallpaperService = FakeWallpaperService();
  storage.storedItems = [
    WallpaperItem(id: '1', path: '/path/1.jpg', fileName: '1.jpg', width: 1080, height: 2400, fileSize: 1024, dateAdded: DateTime.now()),
    WallpaperItem(id: '2', path: '/path/2.jpg', fileName: '2.jpg', width: 1080, height: 2400, fileSize: 1024, dateAdded: DateTime.now()),
  ];

  final controller = WallpaperController(storageService: storage, wallpaperService: wallpaperService);
  await controller.initialize();

  final success = await controller.shuffleNext();
  expect(success, isTrue);
  expect(wallpaperService.setWallpaperCalled, isTrue);
  expect(controller.currentWallpaperId, isNotNull);
});
```

---

## 4. Writing Widget Tests

When testing UI screens:
1. Wrap the widget in a `MaterialApp` configured with Wall Tap's dark theme:
   ```dart
   Widget buildTestableWidget(Widget child) {
     return MaterialApp(
       themeMode: ThemeMode.dark,
       darkTheme: ThemeData.dark(),
       home: child,
     );
   }
   ```
2. Inject a configured `WallpaperController`.
3. Use `tester.pumpWidget()`, followed by `tester.pumpAndSettle()` to wait for animations and transitions to complete.
4. Verify element presence using `find.text()`, `find.byIcon()`, or `find.byType()`.
5. Test interactions using `await tester.tap(...)` and `await tester.pumpAndSettle()`.

---

## 5. Execution Commands

### Run Complete Test Suite
```bash
flutter test
```

### Run a Specific Test Suite
```bash
flutter test test/wallpaper_controller_test.dart
```

### Run with Coverage Generation
```bash
flutter test --coverage
```
*Outputs LCOV report to `coverage/lcov.info`.*

### Run Static Analysis
```bash
dart analyze
```
*Ensures compliance with `flutter_lints` rules in `analysis_options.yaml`.*
