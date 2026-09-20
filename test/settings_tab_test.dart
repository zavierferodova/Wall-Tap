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
  bool? lastPersistentNotificationSet;
  bool batteryOptimizationIgnored = true;

  @override
  Future<bool> setPersistentNotification(bool show) async {
    lastPersistentNotificationSet = show;
    return true;
  }

  @override
  Future<bool> updateWidget() async => true;
  @override
  Future<bool> updateSchedule(int intervalMinutes) async => true;
  @override
  Future<bool> isBatteryOptimizationIgnored() async => batteryOptimizationIgnored;
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

  testWidgets('SettingsTab renders persistent notification toggle when hidden', (tester) async {
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsTab(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active Status Notification'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_off_rounded), findsOneWidget);
    expect(find.textContaining('persistent, unremovable notification'), findsOneWidget);

    final switchFinder = find.byKey(const Key('switch_persistent_notification'));
    expect(switchFinder, findsOneWidget);

    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, false);
  });

  testWidgets('Toggling notification switch activates notification and updates UI', (tester) async {
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsTab(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byKey(const Key('switch_persistent_notification'));
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(controller.config.showPersistentNotification, true);
    expect(fakeWallpaperService.lastPersistentNotificationSet, true);
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

    // Toggle back off
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(controller.config.showPersistentNotification, false);
    expect(fakeWallpaperService.lastPersistentNotificationSet, false);
    expect(find.byIcon(Icons.notifications_off_rounded), findsOneWidget);
  });

  testWidgets('SettingsTab renders initial active state if configured', (tester) async {
    fakeStorage.storedConfig = const SlideshowConfig(showPersistentNotification: true);
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsTab(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

    final switchFinder = find.byKey(const Key('switch_persistent_notification'));
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, true);
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

    expect(find.text('Active Status Notification'), findsOneWidget);
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
    expect(find.text('Zavier Developer'), findsOneWidget);
    expect(
      find.textContaining('This app created by Zavier Ferodova Al Fitroh as Zavier Developer'),
      findsOneWidget,
    );
  });
}
