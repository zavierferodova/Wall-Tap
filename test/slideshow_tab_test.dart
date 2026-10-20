import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_tap/controllers/wallpaper_controller.dart';
import 'package:wall_tap/models/slideshow_config.dart';
import 'package:wall_tap/models/wallpaper_item.dart';
import 'package:wall_tap/models/album.dart';
import 'package:wall_tap/models/album_widget_config.dart';
import 'package:wall_tap/services/storage_service.dart';
import 'package:wall_tap/services/wallpaper_service.dart';
import 'package:wall_tap/views/slideshow/slideshow_tab.dart';

class FakeStorageService extends StorageService {
  List<WallpaperItem> storedItems = [];
  List<Album> storedAlbums = [];
  String? storedActiveAlbumId;
  SlideshowConfig storedConfig = const SlideshowConfig();

  @override
  Future<List<WallpaperItem>> loadItems() async => storedItems;
  @override
  Future<void> saveItems(List<WallpaperItem> items, {List<String>? activePlaylistPaths}) async {}
  @override
  Future<void> syncActivePlaylistPaths(List<String> paths) async {}
  @override
  Future<List<Album>> loadAlbums() async => storedAlbums;
  @override
  Future<void> saveAlbums(List<Album> albums) async {}
  @override
  Future<String?> loadActiveAlbumId() async => storedActiveAlbumId;
  @override
  Future<void> saveActiveAlbumId(String? albumId) async {}
  @override
  Future<SlideshowConfig> loadConfig() async => storedConfig;
  int? storedNextIndex;

  @override
  Future<void> saveNextIndex(int nextIndex) async {
    storedNextIndex = nextIndex;
  }

  @override
  Future<int?> loadNextIndex() async => storedNextIndex;

  @override
  Future<void> saveConfig(SlideshowConfig config) async {
    storedConfig = config;
  }
  String? storedCurrentWallpaperId;
  @override
  Future<String?> loadCurrentWallpaperId() async => storedCurrentWallpaperId;
  @override
  Future<void> saveCurrentWallpaperId(String? id) async {
    storedCurrentWallpaperId = id;
  }
}

class FakeWallpaperService extends WallpaperService {
  String? lastWallpaperSet;
  String? lastTargetScreen;
  String? lastScaleType;

  @override
  Future<bool> setWallpaper({required String filePath, String targetScreen = 'both', String scaleType = 'full'}) async {
    lastWallpaperSet = filePath;
    lastTargetScreen = targetScreen;
    lastScaleType = scaleType;
    return true;
  }
  @override
  Future<bool> updateWidget() async => true;
  @override
  Future<bool> updateSchedule(int intervalMinutes) async => true;
  @override
  Future<bool> isBatteryOptimizationIgnored() async => true;
  @override
  Future<List<AlbumWidgetConfig>> getAlbumWidgets() async => [];
}

void main() {
  testWidgets('SlideshowTab renders Configuration with Target Screen and Scale Mode', (tester) async {
    final fakeStorage = FakeStorageService();
    final fakeWallpaperService = FakeWallpaperService();
    final controller = WallpaperController(
      storageService: fakeStorage,
      wallpaperService: fakeWallpaperService,
    );

    await controller.initialize();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlideshowTab(controller: controller),
        ),
      ),
    );

    // Verify Configuration headers are rendered on homepage
    expect(find.text('APPLY TO'), findsOneWidget);
    expect(find.text('FIT'), findsOneWidget);
    expect(find.text('AUTO-SHUFFLE EVERY'), findsOneWidget);

    // Verify Target Screen options inside configuration card
    final configCard = find.byKey(const Key('wallpaper_config_card'));
    expect(find.descendant(of: configCard, matching: find.text('Both')), findsOneWidget);
    expect(find.descendant(of: configCard, matching: find.text('Home')), findsOneWidget);
    expect(find.descendant(of: configCard, matching: find.text('Lock')), findsOneWidget);

    // Verify Scale Mode options
    expect(find.descendant(of: configCard, matching: find.text('Full')), findsOneWidget);
    expect(find.descendant(of: configCard, matching: find.text('Crop')), findsOneWidget);
    expect(find.descendant(of: configCard, matching: find.text('Fit')), findsOneWidget);

    // Tap 'Lock' to switch target screen
    await tester.tap(find.byKey(const Key('segment_apply_lock')));
    await tester.pumpAndSettle();
    expect(controller.config.targetScreen, 'lock');

    // Tap 'Fit' to switch scale mode
    await tester.tap(find.byKey(const Key('segment_fit_fit')));
    await tester.pumpAndSettle();
    expect(controller.config.scaleType, 'fit');
  });

  testWidgets('SlideshowTab does not render Help button and dialog', (tester) async {
    final fakeStorage = FakeStorageService();
    final fakeWallpaperService = FakeWallpaperService();
    final controller = WallpaperController(
      storageService: fakeStorage,
      wallpaperService: fakeWallpaperService,
    );

    await controller.initialize();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlideshowTab(controller: controller),
        ),
      ),
    );

    // Verify Help button is not rendered
    expect(find.text('Help'), findsNothing);
    expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
  });

  testWidgets('Tapping Target Screen or Scale Mode immediately applies to current wallpaper on device', (tester) async {
    final fakeStorage = FakeStorageService();
    fakeStorage.storedItems = [
      WallpaperItem(
        id: 'wall_active',
        path: '/mock/wall_active.jpg',
        fileName: 'wall_active.jpg',
        width: 1080,
        height: 1920,
        fileSize: 2048,
        isEnabled: true,
        dateAdded: DateTime.now(),
      ),
    ];
    final fakeWallpaperService = FakeWallpaperService();
    final controller = WallpaperController(
      storageService: fakeStorage,
      wallpaperService: fakeWallpaperService,
    );

    await controller.initialize();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlideshowTab(controller: controller),
        ),
      ),
    );

    // Tap 'Home' to switch target screen while inactive (does NOT apply wallpaper)
    await tester.tap(find.byKey(const Key('segment_apply_home')));
    await tester.pumpAndSettle();
    expect(controller.config.targetScreen, 'home');
    expect(fakeWallpaperService.lastWallpaperSet, isNull);

    // Toggle switch to turn on Running state
    await tester.tap(find.byKey(const Key('switch_slideshow_running')));
    await tester.pumpAndSettle();
    expect(controller.config.isSlideshowEnabled, true);
    expect(fakeWallpaperService.lastWallpaperSet, '/mock/wall_active.jpg');
    expect(fakeWallpaperService.lastTargetScreen, 'home');

    // Tap 'Fit' to switch scale mode while running (immediately applies)
    await tester.tap(find.byKey(const Key('segment_fit_fit')));
    await tester.pumpAndSettle();
    expect(controller.config.scaleType, 'fit');
    expect(fakeWallpaperService.lastScaleType, 'fit');
  });

  testWidgets('Sticky navbar remains fixed at the top after scrolling down', (tester) async {
    final fakeStorage = FakeStorageService();
    final fakeWallpaperService = FakeWallpaperService();
    final controller = WallpaperController(
      storageService: fakeStorage,
      wallpaperService: fakeWallpaperService,
    );

    await controller.initialize();

    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlideshowTab(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial navbar position and that border line does not show (transparent)
    final initialNavbarPos = tester.getTopLeft(find.text('Wall Tap'));
    expect(initialNavbarPos.dy, greaterThanOrEqualTo(0));
    final navbarBefore = tester.widget<AnimatedContainer>(find.byKey(const Key('sticky_navbar')));
    final borderBefore = (navbarBefore.decoration as BoxDecoration).border;
    expect(borderBefore?.bottom.color, equals(Colors.transparent));

    // Scroll the ListView down
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // Verify navbar position has not moved despite content scrolling
    final scrolledNavbarPos = tester.getTopLeft(find.text('Wall Tap'));
    expect(scrolledNavbarPos.dy, equals(initialNavbarPos.dy));
    expect(find.text('Wall Tap'), findsOneWidget);
    expect(find.text('Studio'), findsNothing);
    expect(find.text('Help'), findsNothing);

    // Verify border line now shows up
    final navbarAfter = tester.widget<AnimatedContainer>(find.byKey(const Key('sticky_navbar')));
    final borderAfter = (navbarAfter.decoration as BoxDecoration).border;
    expect(borderAfter?.bottom.color, equals(const Color(0xFF1E212D)));

    // Scroll back up to the very top
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pumpAndSettle();

    // Verify border line is hidden again
    final navbarTop = tester.widget<AnimatedContainer>(find.byKey(const Key('sticky_navbar')));
    final borderTop = (navbarTop.decoration as BoxDecoration).border;
    expect(borderTop?.bottom.color, equals(Colors.transparent));
  });

  testWidgets('SlideshowTab allows selecting 1m, 5m, 15m, 1h, and modal intervals', (tester) async {
    final fakeStorage = FakeStorageService();
    final fakeWallpaperService = FakeWallpaperService();
    final controller = WallpaperController(
      storageService: fakeStorage,
      wallpaperService: fakeWallpaperService,
    );

    await controller.initialize();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlideshowTab(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify segment options exist
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('1m'), findsOneWidget);
    expect(find.text('5m'), findsOneWidget);
    expect(find.text('15m'), findsOneWidget);
    expect(find.text('1h'), findsOneWidget);

    // Tap 1m
    await tester.tap(find.text('1m'));
    await tester.pumpAndSettle();
    expect(controller.config.intervalMinutes, 1);

    // Tap 5m
    await tester.tap(find.text('5m'));
    await tester.pumpAndSettle();
    expect(controller.config.intervalMinutes, 5);

    // Tap 15m
    await tester.tap(find.text('15m'));
    await tester.pumpAndSettle();
    expect(controller.config.intervalMinutes, 15);

    // Tap 1h
    await tester.tap(find.text('1h'));
    await tester.pumpAndSettle();
    expect(controller.config.intervalMinutes, 60);

    // Open More options modal
    await tester.tap(find.text('More options'));
    await tester.pumpAndSettle();

    expect(find.text('Every 3 minutes'), findsOneWidget);
    expect(find.text('Every 5 minutes'), findsOneWidget);
    expect(find.text('Every 10 minutes'), findsOneWidget);
    expect(find.text('Every 45 minutes'), findsOneWidget);

    // Select 'Every 3 minutes' from modal
    await tester.tap(find.text('Every 3 minutes'));
    await tester.pumpAndSettle();
    expect(controller.config.intervalMinutes, 3);

    // Verify indicator is displayed when custom option is selected
    expect(find.byKey(const Key('segment_interval_custom')), findsOneWidget);
    expect(find.text('3m'), findsOneWidget);
    expect(find.textContaining('Custom interval active: 3 minutes'), findsOneWidget);
    expect(find.textContaining('More options (3m)'), findsOneWidget);

    // Tapping standard preset removes custom indicator
    await tester.tap(find.text('5m'));
    await tester.pumpAndSettle();
    expect(controller.config.intervalMinutes, 5);
    expect(find.byKey(const Key('segment_interval_custom')), findsNothing);
    expect(find.text('More options'), findsOneWidget);
  });

  testWidgets('SlideshowTab displays Rotation Queue when active wallpapers exist', (tester) async {
    final fakeStorage = FakeStorageService();
    final fakeWallpaperService = FakeWallpaperService();
    final item1 = WallpaperItem(
      id: 'item1',
      path: '/test/item1.jpg',
      fileName: 'item1.jpg',
      width: 1080,
      height: 1920,
      fileSize: 1024,
      dateAdded: DateTime.now(),
    );
    final item2 = WallpaperItem(
      id: 'item2',
      path: '/test/item2.jpg',
      fileName: 'item2.jpg',
      width: 1080,
      height: 1920,
      fileSize: 1024,
      dateAdded: DateTime.now(),
    );
    fakeStorage.storedItems = [item1, item2];

    final controller = WallpaperController(
      storageService: fakeStorage,
      wallpaperService: fakeWallpaperService,
    );
    await controller.initialize();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlideshowTab(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rotation Queue'), findsOneWidget);
    expect(find.textContaining('in rotation'), findsNothing);
    expect(find.text('LIVE'), findsOneWidget);
  });
}

