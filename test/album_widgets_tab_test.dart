import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_tap/controllers/wallpaper_controller.dart';
import 'package:wall_tap/models/slideshow_config.dart';
import 'package:wall_tap/models/wallpaper_item.dart';
import 'package:wall_tap/models/album.dart';
import 'package:wall_tap/models/album_widget_config.dart';
import 'package:wall_tap/services/storage_service.dart';
import 'package:wall_tap/services/wallpaper_service.dart';
import 'package:wall_tap/views/album_widgets/album_widgets_tab.dart';

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
  List<AlbumWidgetConfig> widgets = [];
  int shuffledWidgetId = -1;
  bool syncAllCalled = false;

  @override
  Future<bool> setWallpaper({required String filePath, String targetScreen = 'both', String scaleType = 'full'}) async => true;
  @override
  Future<bool> updateWidget() async => true;
  @override
  Future<bool> updateSchedule(int intervalMinutes) async => true;
  @override
  Future<bool> isBatteryOptimizationIgnored() async => true;
  @override
  Future<List<AlbumWidgetConfig>> getAlbumWidgets() async => widgets;
  @override
  Future<bool> updateAlbumWidget(AlbumWidgetConfig config) async {
    final idx = widgets.indexWhere((w) => w.widgetId == config.widgetId);
    if (idx != -1) {
      widgets[idx] = config;
    } else {
      widgets.add(config);
    }
    return true;
  }
  @override
  Future<bool> shuffleAlbumWidget(int widgetId) async {
    shuffledWidgetId = widgetId;
    return true;
  }
  @override
  Future<bool> updateAllAlbumWidgets() async {
    syncAllCalled = true;
    return true;
  }
}

void main() {
  testWidgets('AlbumWidgetsTab renders onboarding when no widgets placed', (tester) async {
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
          body: AlbumWidgetsTab(controller: controller),
        ),
      ),
    );

    expect(find.text('Album Widgets'), findsOneWidget);
    expect(find.text('Desktop Photo Frames'), findsOneWidget);
    expect(find.text('How to Add an Album Widget'), findsOneWidget);
    expect(find.text('Check Placed Widgets'), findsOneWidget);
  });

  testWidgets('AlbumWidgetsTab renders placed widgets and handles shuffle and order toggles', (tester) async {
    final fakeStorage = FakeStorageService();
    final fakeWallpaperService = FakeWallpaperService();
    fakeWallpaperService.widgets = [
      const AlbumWidgetConfig(
        widgetId: 42,
        albumId: 'all_photos',
        albumName: 'All Photos',
        intervalMinutes: 15,
        isRandom: true,
        currentIndex: 0,
      ),
    ];

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
          body: AlbumWidgetsTab(controller: controller),
        ),
      ),
    );

    // Verify placed widget is rendered
    expect(find.text('Widget #42'), findsOneWidget);
    expect(find.text('All Photos'), findsOneWidget);
    expect(find.text('Shuffle Now'), findsOneWidget);
    expect(find.text('Sync All'), findsOneWidget);

    // Tap "Shuffle Now"
    await tester.tap(find.text('Shuffle Now'));
    await tester.pumpAndSettle();
    expect(fakeWallpaperService.shuffledWidgetId, 42);

    // Tap "Ordered" to toggle order mode
    await tester.tap(find.text('Ordered'));
    await tester.pumpAndSettle();
    expect(controller.albumWidgets.first.isRandom, false);

    // Tap "Sync All"
    await tester.tap(find.text('Sync All'));
    await tester.pumpAndSettle();
    expect(fakeWallpaperService.syncAllCalled, true);
  });

  testWidgets('AlbumWidgetsTab does not have refresh button in app bar and supports pull-down to refresh', (tester) async {
    final fakeStorage = FakeStorageService();
    final fakeWallpaperService = FakeWallpaperService();
    final controller = WallpaperController(
      storageService: fakeStorage,
      wallpaperService: fakeWallpaperService,
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlbumWidgetsTab(controller: controller),
        ),
      ),
    );

    // RefreshIndicator is present
    expect(find.byType(RefreshIndicator), findsOneWidget);

    // Refresh icon button in AppBar is removed
    final appBarFinder = find.byType(SliverAppBar);
    expect(
      find.descendant(of: appBarFinder, matching: find.byIcon(Icons.refresh_rounded)),
      findsNothing,
    );

    // Simulate pull-down-to-refresh gesture
    await tester.fling(find.byType(CustomScrollView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    // Verify still stable
    expect(find.text('Album Widgets'), findsOneWidget);
  });

  testWidgets('AlbumWidgetsTab interval picker supports 3m, 5m, 10m, and 45m options', (tester) async {
    final fakeStorage = FakeStorageService();
    final fakeWallpaperService = FakeWallpaperService();
    fakeWallpaperService.widgets = [
      const AlbumWidgetConfig(
        widgetId: 99,
        albumId: 'all_photos',
        albumName: 'All Photos',
        intervalMinutes: 15,
        isRandom: true,
      ),
    ];

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
          body: AlbumWidgetsTab(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the interval selector button (currently displaying '15 minutes')
    await tester.tap(find.text('15 minutes'));
    await tester.pumpAndSettle();

    // Verify modal bottom sheet displays 3, 5, 10, 45 minutes
    expect(find.text('Every 3 minutes'), findsOneWidget);
    expect(find.text('Every 5 minutes'), findsOneWidget);
    expect(find.text('Every 10 minutes'), findsOneWidget);
    expect(find.text('Every 45 minutes'), findsOneWidget);

    // Tap 'Every 3 minutes'
    await tester.tap(find.text('Every 3 minutes'));
    await tester.pumpAndSettle();

    expect(controller.albumWidgets.first.intervalMinutes, 3);
    expect(controller.albumWidgets.first.intervalLabel, '3 minutes');
    expect(find.text('3 minutes'), findsOneWidget);
  });

  testWidgets('AlbumWidgetsTab uses AnimatedSwitcher for transition animation on image preview', (tester) async {
    final fakeStorage = FakeStorageService();
    final fakeWallpaperService = FakeWallpaperService();
    fakeWallpaperService.widgets = [
      const AlbumWidgetConfig(
        widgetId: 101,
        albumId: 'all_photos',
        albumName: 'All Photos',
        intervalMinutes: 15,
        isRandom: true,
      ),
    ];

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
          body: AlbumWidgetsTab(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AnimatedSwitcher is rendered inside the card
    expect(find.byType(AnimatedSwitcher), findsOneWidget);
    final animatedSwitcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(animatedSwitcher.duration, const Duration(milliseconds: 350));
  });
}

