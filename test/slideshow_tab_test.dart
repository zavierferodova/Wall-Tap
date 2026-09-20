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
  testWidgets('SlideshowTab renders Wallpaper Configuration with Target Screen and Scale Mode', (tester) async {
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

    // Verify Wallpaper Configuration header is rendered on homepage
    expect(find.text('Wallpaper Configuration'), findsOneWidget);
    expect(find.text('Target Screen'), findsOneWidget);
    expect(find.text('Scale Mode'), findsOneWidget);
    expect(find.text('Auto-Shuffle Timer'), findsOneWidget);

    // Verify Target Screen options
    expect(find.text('Both'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Lock'), findsOneWidget);

    // Verify Scale Mode options
    expect(find.text('Full Image'), findsOneWidget);
    expect(find.text('Center Crop'), findsOneWidget);
    expect(find.text('Fit'), findsOneWidget);

    // Tap 'Lock' to switch target screen
    await tester.tap(find.text('Lock'));
    await tester.pumpAndSettle();
    expect(controller.config.targetScreen, 'lock');

    // Tap 'Center Crop' to switch scale mode
    await tester.tap(find.text('Center Crop'));
    await tester.pumpAndSettle();
    expect(controller.config.scaleType, 'crop');
  });

  testWidgets('SlideshowTab renders Help button and opens WidgetGuideDialog on tap', (tester) async {
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

    // Verify Help button is rendered
    expect(find.text('Help'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);

    // Tap Help button
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    // Verify Dialog content is shown
    expect(find.text('Home Screen Widget'), findsOneWidget);
    expect(find.text('Preview upcoming wallpaper & control shuffle from home screen'), findsOneWidget);
    expect(find.text('Long-press any empty space on your Android home screen'), findsOneWidget);
    expect(find.text('Select "Widgets" and find "Wall Tap"'), findsOneWidget);
    expect(find.text('Drag it onto your home screen to preview and rotate wallpapers'), findsOneWidget);
    expect(find.text('Up Next'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Got It'), findsOneWidget);

    // Tap 'Got It' to dismiss
    await tester.tap(find.text('Got It'));
    await tester.pumpAndSettle();

    // Verify dialog dismissed
    expect(find.text('Got It'), findsNothing);
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

    // Tap 'Home' to switch target screen
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(controller.config.targetScreen, 'home');
    expect(fakeWallpaperService.lastWallpaperSet, '/mock/wall_active.jpg');
    expect(fakeWallpaperService.lastTargetScreen, 'home');

    // Tap 'Fit' to switch scale mode
    await tester.tap(find.text('Fit'));
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

    tester.view.physicalSize = const Size(1080, 800);
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
    expect(find.text('Studio'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);

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
}

