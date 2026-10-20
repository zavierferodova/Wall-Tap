# 06 - Testing Strategy & Quality Assurance

Automated testing patterns, test fakes, suite structure, and execution commands for Wall Tap.

---

## 1. Test Suite Structure

The `test/` directory contains 11 test suites with 73 automated unit and widget tests:

```
test/
├── album_detail_screen_test.dart       # Widget tests for album wallpaper management screen
├── album_model_test.dart               # Serialization and immutability tests for Album model
├── album_widget_config_test.dart       # Serialization and intervals for AlbumWidgetConfig
├── album_widgets_tab_test.dart         # Widget tests for launcher widget manager tab
├── playlist_tab_test.dart              # Widget tests for Library tab, grid layouts, and multi-select
├── responsive_layout_test.dart         # Tests for screen width adaptations, column calculation, and tablet constraints
├── settings_tab_test.dart              # Widget tests for Settings tab, battery optimization, and attribution
├── slideshow_tab_test.dart             # Widget tests for Studio tab, interval selector, and scale modes
├── wallpaper_controller_test.dart      # Business logic tests: shuffles, imports, albums, deletions, and config
├── wallpaper_model_test.dart           # Model tests for WallpaperItem resolution and file formats
└── wallpaper_preview_dialog_test.dart  # Widget tests for zoom viewer and full-screen preview dialog
```

---

## 2. Test Architecture: Fakes Pattern

Rather than using reflection-based mock frameworks, Wall Tap uses in-memory test fakes (`FakeStorageService` and `FakeWallpaperService`) extending the real service classes.

### 2.1 `FakeStorageService`
In-memory storage fake that intercepts disk and SharedPreferences calls:

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
}
```

### 2.2 `FakeWallpaperService`
Intercepts `MethodChannel` calls so tests run on any development environment without Android native engine binaries:

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

## 3. Unit & Controller Tests

When testing `WallpaperController`:
1. Instantiate `FakeStorageService` and `FakeWallpaperService`.
2. Pass fakes into the `WallpaperController` constructor.
3. Seed test state (e.g. `storage.storedItems = [...]`).
4. Run `await controller.initialize()`.
5. Execute controller methods and verify internal state and side effects.

```dart
test('shuffleNext advances wallpaper and saves active id', () async {
  final storage = FakeStorageService();
  final wallpaperService = FakeWallpaperService();
  storage.storedItems = [
    WallpaperItem(
      id: '1',
      path: '/path/1.jpg',
      fileName: '1.jpg',
      width: 1080,
      height: 2400,
      fileSize: 1024,
      dateAdded: DateTime.now(),
    ),
    WallpaperItem(
      id: '2',
      path: '/path/2.jpg',
      fileName: '2.jpg',
      width: 1080,
      height: 2400,
      fileSize: 1024,
      dateAdded: DateTime.now(),
    ),
  ];

  final controller = WallpaperController(
    storageService: storage,
    wallpaperService: wallpaperService,
  );
  await controller.initialize();

  final success = await controller.shuffleNext();
  expect(success, isTrue);
  expect(wallpaperService.setWallpaperCalled, isTrue);
  expect(controller.currentWallpaperId, isNotNull);
});
```

---

## 4. Widget Tests

When testing UI screens:
1. Wrap the widget in a `MaterialApp` configured with dark theme:
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
3. Call `tester.pumpWidget()`, followed by `tester.pumpAndSettle()` to complete animations.
4. Verify elements using `find.text()`, `find.byIcon()`, or `find.byType()`.
5. Test interactions using `await tester.tap(...)` and `await tester.pumpAndSettle()`.

---

## 5. Execution Commands

### Run Full Test Suite
```bash
flutter test
```

### Run a Specific Test Suite
```bash
flutter test test/wallpaper_controller_test.dart
```

### Run with Coverage
```bash
flutter test --coverage
```
Outputs LCOV report to `coverage/lcov.info`.

### Run Static Analysis
```bash
dart analyze
```
Verifies rules in `analysis_options.yaml`.
