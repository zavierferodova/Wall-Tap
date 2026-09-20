import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_tap/controllers/wallpaper_controller.dart';
import 'package:wall_tap/models/album.dart';
import 'package:wall_tap/models/album_widget_config.dart';
import 'package:wall_tap/models/slideshow_config.dart';
import 'package:wall_tap/models/wallpaper_item.dart';
import 'package:wall_tap/services/storage_service.dart';
import 'package:wall_tap/services/wallpaper_service.dart';
import 'package:wall_tap/views/album_widgets/album_widgets_tab.dart';
import 'package:wall_tap/views/main_screen.dart';
import 'package:wall_tap/views/playlist/album_detail_screen.dart';
import 'package:wall_tap/views/playlist/playlist_tab.dart';
import 'package:wall_tap/views/settings/settings_tab.dart';
import 'package:wall_tap/views/slideshow/slideshow_tab.dart';

class MockStorageService extends StorageService {
  List<WallpaperItem> items = [];
  List<Album> albums = [];
  String? activeAlbumId;
  SlideshowConfig config = const SlideshowConfig();
  String? currentWallpaperId;

  @override
  Future<List<WallpaperItem>> loadItems() async => items;
  @override
  Future<void> saveItems(List<WallpaperItem> newItems, {List<String>? activePlaylistPaths}) async {
    items = List.from(newItems);
  }
  @override
  Future<void> syncActivePlaylistPaths(List<String> paths) async {}
  @override
  Future<List<Album>> loadAlbums() async => albums;
  @override
  Future<void> saveAlbums(List<Album> newAlbums) async {
    albums = List.from(newAlbums);
  }
  @override
  Future<String?> loadActiveAlbumId() async => activeAlbumId;
  @override
  Future<void> saveActiveAlbumId(String? albumId) async {
    activeAlbumId = albumId;
  }
  @override
  Future<SlideshowConfig> loadConfig() async => config;
  @override
  Future<void> saveConfig(SlideshowConfig newConfig) async {
    config = newConfig;
  }
  @override
  Future<String?> loadCurrentWallpaperId() async => currentWallpaperId;
  @override
  Future<void> saveCurrentWallpaperId(String? id) async {
    currentWallpaperId = id;
  }
  int storedNextIndex = 0;
  @override
  Future<void> saveNextIndex(int nextIndex) async {
    storedNextIndex = nextIndex;
  }
  @override
  Future<int?> loadNextIndex() async => storedNextIndex;
}

class MockWallpaperService extends WallpaperService {
  List<AlbumWidgetConfig> widgets = [];

  @override
  Future<bool> setPersistentNotification(bool enable) async => true;

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
  Future<bool> updateAlbumWidget(AlbumWidgetConfig config) async => true;
  @override
  Future<bool> shuffleAlbumWidget(int widgetId) async => true;
  @override
  Future<bool> updateAllAlbumWidgets() async => true;
}

WallpaperItem _createTestItem(String id, String name) {
  return WallpaperItem(
    id: id,
    fileName: name,
    path: '/mock/$name',
    width: 1080,
    height: 1920,
    fileSize: 1024000,
    dateAdded: DateTime.now(),
  );
}

void main() {
  late MockStorageService storageService;
  late MockWallpaperService wallpaperService;
  late WallpaperController controller;

  setUp(() {
    storageService = MockStorageService();
    wallpaperService = MockWallpaperService();
    controller = WallpaperController(
      storageService: storageService,
      wallpaperService: wallpaperService,
    );
  });

  group('Responsive Layout Tests across Phone and Tablet Form Factors', () {
    testWidgets('SlideshowTab adapts hero mockup to phone portrait aspect ratio', (tester) async {
      // Set phone size (390 x 844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      storageService.items = [
        _createTestItem('item_1', 'phone_wp.jpg'),
      ];
      await controller.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideshowTab(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the hero mockup is rendered with AspectRatio matching 390 / 844
      expect(find.byKey(const Key('hero_device_mockup')), findsOneWidget);
      final mockupSize = tester.getSize(find.byKey(const Key('hero_device_mockup')));
      final ratio = mockupSize.width / mockupSize.height;
      final expectedRatio = 390.0 / 844.0;
      expect((ratio - expectedRatio).abs(), lessThan(0.02));

      // Verify pill notch exists in portrait
      expect(find.byKey(const Key('hero_portrait_notch')), findsOneWidget);
      expect(find.byKey(const Key('hero_landscape_camera')), findsNothing);
    });

    testWidgets('SlideshowTab adapts hero mockup to tablet landscape aspect ratio with webcam dot', (tester) async {
      // Set tablet landscape size (1280 x 800)
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      storageService.items = [
        _createTestItem('item_1', 'tablet_wp.jpg'),
      ];
      await controller.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideshowTab(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the hero mockup is rendered with AspectRatio matching 1280 / 800 = 1.6
      expect(find.byKey(const Key('hero_device_mockup')), findsOneWidget);
      final mockupSize = tester.getSize(find.byKey(const Key('hero_device_mockup')));
      final ratio = mockupSize.width / mockupSize.height;
      final expectedRatio = 1280.0 / 800.0;
      expect((ratio - expectedRatio).abs(), lessThan(0.02));

      // In landscape, circular webcam dot is displayed, not pill notch
      expect(find.byKey(const Key('hero_landscape_camera')), findsOneWidget);
      expect(find.byKey(const Key('hero_portrait_notch')), findsNothing);
    });

    testWidgets('MainScreen centers and constrains bottom navigation bar on wide tablet', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await controller.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: MainScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Find bottom navigation bar constrained box
      final navConstrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byWidgetPredicate((widget) =>
            widget is ConstrainedBox && widget.constraints.maxWidth == 540),
      );
      expect(navConstrainedBoxes.isNotEmpty, isTrue);

      // Verify SlideshowTab body content is rendered and visible (not collapsed to 0 height)
      expect(find.byKey(const Key('hero_device_mockup')), findsOneWidget);
      final heroSize = tester.getSize(find.byKey(const Key('hero_device_mockup')));
      expect(heroSize.height, greaterThan(0));
    });

    testWidgets('PlaylistTab calculates responsive columns based on screen width', (tester) async {
      // Create 8 test items
      storageService.items = List.generate(
        8,
        (i) => _createTestItem('item_$i', 'wallpaper_$i.jpg'),
      );
      await controller.initialize();

      // 1. Phone width (390px) -> 2 columns
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistTab(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var gridView = tester.widget<GridView>(find.byType(GridView));
      var delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);

      // 2. Medium tablet width (800px) -> 4 columns
      tester.view.physicalSize = const Size(800, 1280);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistTab(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      gridView = tester.widget<GridView>(find.byType(GridView));
      delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);

      // 3. Large tablet landscape width (1280px) -> 6 columns
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistTab(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      gridView = tester.widget<GridView>(find.byType(GridView));
      delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 6);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('AlbumDetailScreen calculates responsive columns for album wallpapers', (tester) async {
      final testAlbum = Album(
        id: 'album_1',
        name: 'Nature',
        wallpaperIds: const ['it_1', 'it_2', 'it_3', 'it_4'],
        dateCreated: DateTime.now(),
      );
      storageService.albums = [testAlbum];
      storageService.items = [
        _createTestItem('it_1', '1.jpg'),
        _createTestItem('it_2', '2.jpg'),
        _createTestItem('it_3', '3.jpg'),
        _createTestItem('it_4', '4.jpg'),
      ];
      await controller.initialize();

      // Tablet portrait (800 x 1280) -> 4 columns
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumDetailScreen(
              controller: controller,
              albumId: 'album_1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
    });

    testWidgets('SettingsTab content is constrained on wide tablet', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await controller.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsTab(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final constrainedBoxFinder = find.byWidgetPredicate((widget) =>
          widget is ConstrainedBox && widget.constraints.maxWidth == 720);
      expect(constrainedBoxFinder, findsOneWidget);
    });

    testWidgets('AlbumWidgetsTab content is constrained and renders 2-column grid on tablet', (tester) async {
      wallpaperService.widgets = [
        const AlbumWidgetConfig(
          widgetId: 101,
          albumId: 'all_photos',
          albumName: 'All Photos',
          intervalMinutes: 30,
        ),
        const AlbumWidgetConfig(
          widgetId: 102,
          albumId: 'all_photos',
          albumName: 'All Photos',
          intervalMinutes: 60,
        ),
      ];
      await controller.initialize();

      tester.view.physicalSize = const Size(900, 1200);
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

      // Verify content maxWidth 850 is present
      final constrainedFinder = find.byWidgetPredicate((widget) =>
          widget is ConstrainedBox && widget.constraints.maxWidth == 850);
      expect(constrainedFinder, findsOneWidget);

      // Verify 2-column GridView for placed widgets
      final gridViewFinder = find.byType(GridView);
      expect(gridViewFinder, findsOneWidget);
      final gridView = tester.widget<GridView>(gridViewFinder);
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });
  });
}
