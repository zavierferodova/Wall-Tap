import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_tap/controllers/wallpaper_controller.dart';
import 'package:wall_tap/models/album.dart';
import 'package:wall_tap/models/album_widget_config.dart';
import 'package:wall_tap/models/slideshow_config.dart';
import 'package:wall_tap/models/wallpaper_item.dart';
import 'package:wall_tap/services/storage_service.dart';
import 'package:wall_tap/services/wallpaper_service.dart';
import 'package:wall_tap/views/playlist/album_detail_screen.dart';

class FakeStorageService extends StorageService {
  List<WallpaperItem> storedItems = [];
  List<Album> storedAlbums = [];
  String? storedActiveAlbumId;
  SlideshowConfig storedConfig = const SlideshowConfig();
  int storedNextIndex = 0;

  @override
  Future<List<WallpaperItem>> loadItems() async => storedItems;
  @override
  Future<void> saveItems(List<WallpaperItem> items, {List<String>? activePlaylistPaths}) async {
    storedItems = items;
  }
  @override
  Future<void> syncActivePlaylistPaths(List<String> paths) async {}
  @override
  Future<List<Album>> loadAlbums() async => storedAlbums;
  @override
  Future<void> saveAlbums(List<Album> albums) async {
    storedAlbums = albums;
  }
  @override
  Future<String?> loadActiveAlbumId() async => storedActiveAlbumId;
  @override
  Future<void> saveActiveAlbumId(String? albumId) async {
    storedActiveAlbumId = albumId;
  }
  @override
  Future<SlideshowConfig> loadConfig() async => storedConfig;
  @override
  Future<void> saveConfig(SlideshowConfig config) async {
    storedConfig = config;
  }
  @override
  Future<int> loadNextIndex() async => storedNextIndex;
  @override
  Future<void> saveNextIndex(int index) async {
    storedNextIndex = index;
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
  @override
  Future<bool> setWallpaper({required String filePath, String targetScreen = 'both', String scaleType = 'full'}) async => true;
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStorageService fakeStorage;
  late FakeWallpaperService fakeWallpaper;
  late WallpaperController controller;

  setUp(() {
    fakeStorage = FakeStorageService();
    fakeWallpaper = FakeWallpaperService();
    controller = WallpaperController(
      storageService: fakeStorage,
      wallpaperService: fakeWallpaper,
    );
  });

  Widget buildTestWidget(String albumId) {
    return MaterialApp(
      home: AlbumDetailScreen(
        controller: controller,
        albumId: albumId,
      ),
    );
  }

  testWidgets('Multi-selection batch Exclude and Include in AlbumDetailScreen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    fakeStorage.storedItems = [
      WallpaperItem(
        id: 'wp1',
        fileName: 'Album Wall 1.jpg',
        path: '/dummy/path1.jpg',
        width: 1080,
        height: 1920,
        fileSize: 1024,
        dateAdded: now,
        isEnabled: true,
      ),
      WallpaperItem(
        id: 'wp2',
        fileName: 'Album Wall 2.jpg',
        path: '/dummy/path2.jpg',
        width: 1080,
        height: 1920,
        fileSize: 2048,
        dateAdded: now,
        isEnabled: true,
      ),
    ];
    fakeStorage.storedAlbums = [
      Album(
        id: 'album_1',
        name: 'Favorites',
        wallpaperIds: ['wp1', 'wp2'],
        dateCreated: now,
      ),
    ];

    await controller.initialize();
    await tester.pumpWidget(buildTestWidget('album_1'));
    await tester.pumpAndSettle();

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('ACTIVE'), findsNothing);
    expect(find.text('EXCLUDED'), findsNothing);

    // Long press first item to enter selection mode
    await tester.longPress(find.text('1080x1920').first);
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Exclude'), findsOneWidget);
    expect(find.text('Delete (1)'), findsOneWidget);

    // Tap second item to select it
    await tester.tap(find.text('1080x1920').last);
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('Delete (2)'), findsOneWidget);

    // Tap Exclude
    await tester.tap(find.text('Exclude'));
    await tester.pumpAndSettle();

    // Verify both items in controller are now excluded
    expect(controller.items.every((i) => !i.isEnabled), true);

    // Enter selection mode again
    await tester.longPress(find.text('1080x1920').first);
    await tester.pumpAndSettle();

    // The button should now show Include
    expect(find.text('Include'), findsOneWidget);

    // Tap Include
    await tester.tap(find.text('Include'));
    await tester.pumpAndSettle();

    expect(controller.items.firstWhere((i) => i.id == 'wp1').isEnabled, true);
  });

  testWidgets('Multi-selection batch Delete: remove from album in AlbumDetailScreen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    fakeStorage.storedItems = [
      WallpaperItem(
        id: 'wp1',
        fileName: 'Album Wall 1.jpg',
        path: '/dummy/path1.jpg',
        width: 1080,
        height: 1920,
        fileSize: 1024,
        dateAdded: now,
        isEnabled: true,
      ),
      WallpaperItem(
        id: 'wp2',
        fileName: 'Album Wall 2.jpg',
        path: '/dummy/path2.jpg',
        width: 1080,
        height: 1920,
        fileSize: 2048,
        dateAdded: now,
        isEnabled: true,
      ),
    ];
    fakeStorage.storedAlbums = [
      Album(
        id: 'album_1',
        name: 'Favorites',
        wallpaperIds: ['wp1', 'wp2'],
        dateCreated: now,
      ),
    ];

    await controller.initialize();
    await tester.pumpWidget(buildTestWidget('album_1'));
    await tester.pumpAndSettle();

    // Long press first item to enter selection mode
    await tester.longPress(find.text('1080x1920').first);
    await tester.pumpAndSettle();

    // Tap Delete (1)
    await tester.tap(find.text('Delete (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Delete 1 Wallpaper?'), findsOneWidget);
    expect(find.text('Remove from Album'), findsOneWidget);
    expect(find.text('Delete Permanently'), findsOneWidget);

    // Choose Remove from Album
    await tester.tap(find.text('Remove from Album'));
    await tester.pumpAndSettle();

    // Verify wp1 removed from album but still exists in items
    expect(controller.albums.first.wallpaperIds, ['wp2']);
    expect(controller.items.length, 2);
  });

  testWidgets('Multi-selection batch Delete: delete permanently in AlbumDetailScreen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    fakeStorage.storedItems = [
      WallpaperItem(
        id: 'wp1',
        fileName: 'Album Wall 1.jpg',
        path: '/dummy/path1.jpg',
        width: 1080,
        height: 1920,
        fileSize: 1024,
        dateAdded: now,
        isEnabled: true,
      ),
      WallpaperItem(
        id: 'wp2',
        fileName: 'Album Wall 2.jpg',
        path: '/dummy/path2.jpg',
        width: 1080,
        height: 1920,
        fileSize: 2048,
        dateAdded: now,
        isEnabled: true,
      ),
    ];
    fakeStorage.storedAlbums = [
      Album(
        id: 'album_1',
        name: 'Favorites',
        wallpaperIds: ['wp1', 'wp2'],
        dateCreated: now,
      ),
    ];

    await controller.initialize();
    await tester.pumpWidget(buildTestWidget('album_1'));
    await tester.pumpAndSettle();

    // Long press first item to enter selection mode
    await tester.longPress(find.text('1080x1920').first);
    await tester.pumpAndSettle();

    // Tap Delete (1)
    await tester.tap(find.text('Delete (1)'));
    await tester.pumpAndSettle();

    // Choose Delete Permanently
    await tester.tap(find.text('Delete Permanently'));
    await tester.pumpAndSettle();

    // Verify wp1 deleted from controller items and album
    expect(controller.items.length, 1);
    expect(controller.items.first.id, 'wp2');
    expect(controller.albums.first.wallpaperIds, ['wp2']);
  });
}
