import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_tap/controllers/wallpaper_controller.dart';
import 'package:wall_tap/models/slideshow_config.dart';
import 'package:wall_tap/models/wallpaper_item.dart';
import 'package:wall_tap/models/album.dart';
import 'package:wall_tap/models/album_widget_config.dart';
import 'package:wall_tap/services/storage_service.dart';
import 'package:wall_tap/services/wallpaper_service.dart';
import 'package:wall_tap/views/settings/settings_tab.dart';

class FakeStorageService extends StorageService {
  List<WallpaperItem> storedItems = [];
  List<Album> storedAlbums = [];
  String? storedActiveAlbumId;
  SlideshowConfig storedConfig = const SlideshowConfig();
  int? storedNextIndex;

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
  bool batteryOptimizationIgnored = true;
  bool requestIgnoreCalled = false;

  @override
  Future<bool> isBatteryOptimizationIgnored() async => batteryOptimizationIgnored;
  @override
  Future<bool> requestIgnoreBatteryOptimizations() async {
    requestIgnoreCalled = true;
    return true;
  }
  @override
  Future<bool> updateWidget() async => true;
  @override
  Future<bool> updateSchedule(int intervalMinutes) async => true;
  @override
  Future<List<AlbumWidgetConfig>> getAlbumWidgets() async => [];
}

void main() {
  late FakeStorageService fakeStorage;
  late FakeWallpaperService fakeWallpaperService;
  late WallpaperController controller;

  setUp(() {
    fakeStorage = FakeStorageService();
    fakeWallpaperService = FakeWallpaperService();
    controller = WallpaperController(
      storageService: fakeStorage,
      wallpaperService: fakeWallpaperService,
    );
  });

  testWidgets('SettingsTab renders Battery Optimization card without persistent notification toggle', (tester) async {
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsTab(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings & System'), findsOneWidget);
    expect(find.text('Battery Optimization'), findsOneWidget);
    expect(find.text('Active Status Notification'), findsNothing);
    expect(find.byKey(const Key('switch_persistent_notification')), findsNothing);
  });

  testWidgets('SettingsTab displays battery optimization button when not ignored and triggers request', (tester) async {
    fakeWallpaperService.batteryOptimizationIgnored = false;
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsTab(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Allow Unrestricted Background Execution'), findsOneWidget);
    await tester.tap(find.text('Allow Unrestricted Background Execution'));
    await tester.pumpAndSettle();

    expect(fakeWallpaperService.requestIgnoreCalled, true);
  });

  testWidgets('SettingsTab does not render storage and playlist clear section', (tester) async {
    fakeStorage.storedItems = [
      WallpaperItem(
        id: '1',
        path: '/test/1.jpg',
        fileName: '1.jpg',
        width: 1080,
        height: 1920,
        fileSize: 1024 * 500,
        dateAdded: DateTime.now(),
      ),
    ];
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsTab(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Storage & Playlist Data'), findsNothing);
    expect(find.text('Playlist Storage'), findsNothing);
    expect(find.text('Clear All Wallpapers'), findsNothing);
  });

  testWidgets('SettingsTab does not overflow on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(300, 700);
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

    expect(find.text('Battery Optimization'), findsOneWidget);
    expect(find.text('Active Status Notification'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SettingsTab renders About section with developer attribution', (tester) async {
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsTab(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('About Wall Tap'), findsOneWidget);
    expect(find.text('Zavier Ferodova Al Fitroh'), findsOneWidget);
    expect(find.text('Zavier Developer'), findsNothing);
    expect(find.textContaining('This app created by'), findsNothing);
    expect(
      find.text('Designed for automatic wallpaper scheduling, album rotation, and home screen widgets.'),
      findsOneWidget,
    );
  });
}
