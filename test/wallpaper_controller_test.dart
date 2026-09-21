import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_tap/controllers/wallpaper_controller.dart';
import 'package:wall_tap/models/wallpaper_item.dart';
import 'package:wall_tap/models/slideshow_config.dart';
import 'package:wall_tap/services/storage_service.dart';
import 'package:wall_tap/services/wallpaper_service.dart';

import 'package:wall_tap/models/album.dart';
import 'package:wall_tap/models/album_widget_config.dart';

class FakeStorageService extends StorageService {
  List<WallpaperItem> storedItems = [];
  List<Album> storedAlbums = [];
  String? storedActiveAlbumId;
  List<String> syncedPaths = [];
  SlideshowConfig storedConfig = const SlideshowConfig();

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
  Future<void> syncActivePlaylistPaths(List<String> paths) async {
    syncedPaths = List.from(paths);
  }

  @override
  Future<List<Album>> loadAlbums() async => storedAlbums;

  @override
  Future<void> saveAlbums(List<Album> albums) async {
    storedAlbums = List.from(albums);
  }

  @override
  Future<String?> loadActiveAlbumId() async => storedActiveAlbumId;

  @override
  Future<void> saveActiveAlbumId(String? albumId) async {
    storedActiveAlbumId = albumId;
  }

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

  @override
  Future<void> deleteWallpaperFile(String path) async {}

  @override
  Future<WallpaperItem?> saveImageToStorage(String sourcePath, {String? customName}) async {
    return WallpaperItem(
      id: sourcePath,
      path: sourcePath,
      fileName: customName ?? sourcePath.split('/').last,
      width: 1080,
      height: 1920,
      fileSize: 1024,
      dateAdded: DateTime.now(),
    );
  }
}

class FakeWallpaperService extends WallpaperService {
  String? lastWallpaperSet;
  String? lastTargetScreen;
  String? lastScaleType;
  int? lastScheduledInterval;
  bool batteryOptimizationIgnored = false;
  List<String> mockFolderImages = [];
  bool? lastPersistentNotificationSet;

  @override
  Future<bool> setPersistentNotification(bool show) async {
    lastPersistentNotificationSet = show;
    return true;
  }

  @override
  Future<bool> setWallpaper({
    required String filePath,
    String targetScreen = 'both',
    String scaleType = 'full',
  }) async {
    lastWallpaperSet = filePath;
    lastTargetScreen = targetScreen;
    lastScaleType = scaleType;
    return true;
  }

  @override
  Future<bool> updateWidget() async => true;

  @override
  Future<bool> updateSchedule(int intervalMinutes) async {
    lastScheduledInterval = intervalMinutes;
    return true;
  }

  @override
  Future<bool> isBatteryOptimizationIgnored() async => batteryOptimizationIgnored;

  @override
  Future<bool> requestIgnoreBatteryOptimizations() async {
    batteryOptimizationIgnored = true;
    return true;
  }

  @override
  Future<List<String>> pickFolderAndGetImages() async {
    return mockFolderImages;
  }

  List<AlbumWidgetConfig> mockAlbumWidgets = [];
  int? lastShuffledWidgetId;
  AlbumWidgetConfig? lastUpdatedWidgetConfig;

  @override
  Future<List<AlbumWidgetConfig>> getAlbumWidgets() async => mockAlbumWidgets;

  @override
  Future<bool> updateAlbumWidget(AlbumWidgetConfig config) async {
    lastUpdatedWidgetConfig = config;
    final index = mockAlbumWidgets.indexWhere((w) => w.widgetId == config.widgetId);
    if (index != -1) {
      mockAlbumWidgets[index] = config;
    } else {
      mockAlbumWidgets.add(config);
    }
    return true;
  }

  @override
  Future<bool> shuffleAlbumWidget(int widgetId) async {
    lastShuffledWidgetId = widgetId;
    return true;
  }

  @override
  Future<bool> updateAllAlbumWidgets() async => true;
}

void main() {
  group('WallpaperController Tests', () {
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

    test('Loads items and config on initialize', () async {
      fakeStorage.storedItems = [
        WallpaperItem(
          id: '1',
          path: '/path/1.jpg',
          fileName: 'Alpha.jpg',
          width: 1080,
          height: 1920,
          fileSize: 1000,
          dateAdded: DateTime.now(),
        ),
      ];
      fakeStorage.storedConfig = const SlideshowConfig(targetScreen: 'home');

      await controller.initialize();

      expect(controller.items.length, 1);
      expect(controller.config.targetScreen, 'home');
      expect(controller.currentWallpaper?.id, '1');
    });

    test('Filters activeItems by isEnabled', () async {
      fakeStorage.storedItems = [
        WallpaperItem(
          id: '1',
          path: '/path/1.jpg',
          fileName: 'Image 1',
          width: 1080,
          height: 1920,
          fileSize: 1000,
          isEnabled: true,
          dateAdded: DateTime.now(),
        ),
        WallpaperItem(
          id: '2',
          path: '/path/2.jpg',
          fileName: 'Image 2',
          width: 1080,
          height: 1920,
          fileSize: 1000,
          isEnabled: false,
          dateAdded: DateTime.now(),
        ),
      ];

      await controller.initialize();
      expect(controller.items.length, 2);
      expect(controller.activeItems.length, 1);
      expect(controller.activeItems.first.id, '1');
    });

    test('Sorts items alphabetically', () async {
      fakeStorage.storedItems = [
        WallpaperItem(
          id: '1',
          path: '/path/1.jpg',
          fileName: 'Zebra.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
        WallpaperItem(
          id: '2',
          path: '/path/2.jpg',
          fileName: 'Apple.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
      ];

      await controller.initialize();
      controller.sortItemsAlphabetical();

      expect(controller.items.first.fileName, 'Apple.jpg');
      expect(controller.items.last.fileName, 'Zebra.jpg');
    });

    test('shuffleNext advances currentIndex and calls wallpaper service', () async {
      fakeStorage.storedItems = [
        WallpaperItem(
          id: '1',
          path: '/path/1.jpg',
          fileName: 'Image 1',
          width: 1080,
          height: 1920,
          fileSize: 1000,
          dateAdded: DateTime.now(),
        ),
        WallpaperItem(
          id: '2',
          path: '/path/2.jpg',
          fileName: 'Image 2',
          width: 1080,
          height: 1920,
          fileSize: 1000,
          dateAdded: DateTime.now(),
        ),
      ];
      fakeStorage.storedConfig = const SlideshowConfig(currentIndex: 0, isRandom: false);

      await controller.initialize();
      final success = await controller.shuffleNext();

      expect(success, true);
      expect(controller.config.currentIndex, 1);
      expect(fakeWallpaperService.lastWallpaperSet, '/path/2.jpg');
    });

    test('updateInterval updates config and schedules alarm when running, but not when inactive', () async {
      await controller.initialize();
      expect(fakeWallpaperService.lastScheduledInterval, 0);

      // Inactive: updates config, but does not schedule alarm (remains 0)
      await controller.updateInterval(15);
      expect(controller.config.intervalMinutes, 15);
      expect(fakeStorage.storedConfig.intervalMinutes, 15);
      expect(fakeWallpaperService.lastScheduledInterval, 0);

      // Turn on running state: schedules alarm with configured interval
      await controller.toggleSlideshowEnabled(true);
      expect(fakeWallpaperService.lastScheduledInterval, 15);

      // Updating interval while running immediately reschedules
      await controller.updateInterval(30);
      expect(fakeWallpaperService.lastScheduledInterval, 30);

      // Disabling running state cancels schedule
      await controller.toggleSlideshowEnabled(false);
      expect(fakeWallpaperService.lastScheduledInterval, 0);
    });

    test('Battery optimization flow can be requested and checked', () async {
      await controller.initialize();
      expect(controller.isBatteryOptimizationIgnored, false);

      final granted = await controller.requestDisableBatteryOptimization();
      expect(granted, true);
      expect(controller.isBatteryOptimizationIgnored, true);
    });

    test('pickAndImportFolder imports images returned from wallpaper service', () async {
      await controller.initialize();
      expect(controller.items.isEmpty, true);

      fakeWallpaperService.mockFolderImages = ['/tmp/pic1.jpg', '/tmp/pic2.png'];
      final count = await controller.pickAndImportFolder();

      expect(count, 2);
      expect(controller.items.length, 2);
      expect(fakeStorage.storedItems.length, 2);
    });

    test('importFolder only imports images in root directory, not subdirectories', () async {
      await controller.initialize();
      final tempDir = Directory.systemTemp.createTempSync('walltap_test_folder_');
      try {
        File('${tempDir.path}/root_img.jpg').createSync();
        final subDir = Directory('${tempDir.path}/sub_folder')..createSync();
        File('${subDir.path}/sub_img.jpg').createSync();

        final count = await controller.importFolder(tempDir.path);
        expect(count, 1);
        expect(controller.items.length, 1);
        expect(controller.items.first.fileName, 'root_img.jpg');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('deleteItems deletes multiple items in batch and updates state', () async {
      fakeStorage.storedItems = [
        WallpaperItem(
          id: '1',
          path: '/path/1.jpg',
          fileName: '1.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
        WallpaperItem(
          id: '2',
          path: '/path/2.jpg',
          fileName: '2.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
        WallpaperItem(
          id: '3',
          path: '/path/3.jpg',
          fileName: '3.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
      ];

      await controller.initialize();
      expect(controller.items.length, 3);

      final deleted = await controller.deleteItems({'1', '3'});
      expect(deleted, 2);
      expect(controller.items.length, 1);
      expect(controller.items.first.id, '2');
      expect(fakeStorage.storedItems.length, 1);
      expect(fakeStorage.storedItems.first.id, '2');
    });

    test('setItemsEnabled batch enables and disables items and updates state', () async {
      fakeStorage.storedItems = [
        WallpaperItem(
          id: '1',
          path: '/path/1.jpg',
          fileName: '1.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
          isEnabled: true,
        ),
        WallpaperItem(
          id: '2',
          path: '/path/2.jpg',
          fileName: '2.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
          isEnabled: true,
        ),
        WallpaperItem(
          id: '3',
          path: '/path/3.jpg',
          fileName: '3.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
          isEnabled: false,
        ),
      ];

      await controller.initialize();
      expect(controller.activeItems.length, 2);

      // Batch exclude items '1' and '2'
      await controller.setItemsEnabled({'1', '2'}, false);
      expect(controller.items.firstWhere((i) => i.id == '1').isEnabled, false);
      expect(controller.items.firstWhere((i) => i.id == '2').isEnabled, false);
      expect(controller.activeItems.length, 0);
      expect(fakeStorage.storedItems.where((i) => i.isEnabled).length, 0);

      // Batch include items '1' and '3'
      await controller.setItemsEnabled({'1', '3'}, true);
      expect(controller.items.firstWhere((i) => i.id == '1').isEnabled, true);
      expect(controller.items.firstWhere((i) => i.id == '2').isEnabled, false);
      expect(controller.items.firstWhere((i) => i.id == '3').isEnabled, true);
      expect(controller.activeItems.length, 2);
    });

    test('createAlbum, renameAlbum, and deleteAlbum work properly', () async {
      await controller.initialize();
      expect(controller.albums, isEmpty);

      final album = await controller.createAlbum('Anime Collection');
      expect(controller.albums.length, 1);
      expect(controller.albums.first.name, 'Anime Collection');
      expect(fakeStorage.storedAlbums.length, 1);

      await controller.renameAlbum(album.id, 'Super Anime');
      expect(controller.albums.first.name, 'Super Anime');

      await controller.deleteAlbum(album.id);
      expect(controller.albums, isEmpty);
      expect(fakeStorage.storedAlbums, isEmpty);
    });

    test('addItemsToAlbum and removeItemsFromAlbum manage album item IDs', () async {
      fakeStorage.storedItems = [
        WallpaperItem(
          id: 'w1',
          path: '/path/w1.jpg',
          fileName: 'w1.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
        WallpaperItem(
          id: 'w2',
          path: '/path/w2.jpg',
          fileName: 'w2.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
      ];

      await controller.initialize();
      final album = await controller.createAlbum('Favorites');

      await controller.addItemsToAlbum(album.id, ['w2', 'w1']);
      expect(controller.albums.first.wallpaperIds, equals(['w2', 'w1']));
      expect(controller.getAlbumItems(album.id).length, 2);
      // Order must match wallpaperIds order: w2 first, then w1
      expect(controller.getAlbumItems(album.id)[0].id, 'w2');
      expect(controller.getAlbumItems(album.id)[1].id, 'w1');

      // 'all_photos' must return all items
      expect(controller.getAlbumItems('all_photos').length, 2);
      expect(controller.getAlbumItems('all').length, 2);
      expect(controller.getAlbumItems('').length, 2);

      await controller.removeItemsFromAlbum(album.id, ['w1']);
      expect(controller.albums.first.wallpaperIds, equals(['w2']));
      expect(controller.getAlbumItems(album.id).length, 1);
      expect(controller.getAlbumItems(album.id).first.id, 'w2');
    });

    test('setActiveAlbum filters activeItems and syncs playlist', () async {
      fakeStorage.storedItems = [
        WallpaperItem(
          id: 'w1',
          path: '/path/w1.jpg',
          fileName: 'w1.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
        WallpaperItem(
          id: 'w2',
          path: '/path/w2.jpg',
          fileName: 'w2.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
        WallpaperItem(
          id: 'w3',
          path: '/path/w3.jpg',
          fileName: 'w3.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
      ];

      await controller.initialize();
      expect(controller.activeItems.length, 3);

      final album = await controller.createAlbum('Nature', initialItemIds: ['w1', 'w3']);
      await controller.setActiveAlbum(album.id);

      expect(controller.activeAlbumId, album.id);
      expect(controller.activeAlbum?.name, 'Nature');
      expect(controller.activeItems.length, 2);
      expect(controller.activeItems.map((e) => e.id).toList(), equals(['w1', 'w3']));
      expect(fakeStorage.syncedPaths, equals(['/path/w1.jpg', '/path/w3.jpg']));

      // Switching back to All Wallpapers
      await controller.setActiveAlbum(null);
      expect(controller.activeAlbumId, isNull);
      expect(controller.activeItems.length, 3);
      expect(fakeStorage.syncedPaths.length, 3);
    });

    test('deleteItems cleans up wallpaper IDs from all albums', () async {
      fakeStorage.storedItems = [
        WallpaperItem(
          id: 'w1',
          path: '/path/w1.jpg',
          fileName: 'w1.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
        WallpaperItem(
          id: 'w2',
          path: '/path/w2.jpg',
          fileName: 'w2.jpg',
          width: 100,
          height: 100,
          fileSize: 100,
          dateAdded: DateTime.now(),
        ),
      ];

      await controller.initialize();
      await controller.createAlbum('Favorites', initialItemIds: ['w1', 'w2']);
      expect(controller.albums.first.wallpaperIds.length, 2);

      await controller.deleteItems(['w1']);
      expect(controller.items.length, 1);
      expect(controller.albums.first.wallpaperIds, equals(['w2']));
    });

    test('loadAlbumWidgets, updateAlbumWidgetConfig, and shuffleAlbumWidget work properly', () async {
      fakeWallpaperService.mockAlbumWidgets = [
        const AlbumWidgetConfig(
          widgetId: 10,
          albumId: 'a1',
          albumName: 'Album 1',
          intervalMinutes: 15,
          isRandom: false,
        ),
      ];

      await controller.initialize();
      expect(controller.albumWidgets.length, 1);
      expect(controller.albumWidgets.first.widgetId, 10);
      expect(controller.albumWidgets.first.albumName, 'Album 1');

      // Update widget config
      final updated = controller.albumWidgets.first.copyWith(intervalMinutes: 30, isRandom: true);
      await controller.updateAlbumWidgetConfig(updated);
      expect(fakeWallpaperService.lastUpdatedWidgetConfig?.intervalMinutes, 30);
      expect(fakeWallpaperService.lastUpdatedWidgetConfig?.isRandom, true);

      // Shuffle widget
      await controller.shuffleAlbumWidget(10);
      expect(fakeWallpaperService.lastShuffledWidgetId, 10);
    });

    test('reloadFromStorage reloads updated config and active album from storage', () async {
      fakeStorage.storedItems = [
        WallpaperItem(id: '1', path: '/p1.jpg', fileName: '1.jpg', width: 100, height: 100, fileSize: 10, isEnabled: true, dateAdded: DateTime.now()),
        WallpaperItem(id: '2', path: '/p2.jpg', fileName: '2.jpg', width: 100, height: 100, fileSize: 10, isEnabled: true, dateAdded: DateTime.now()),
      ];
      fakeStorage.storedConfig = const SlideshowConfig(currentIndex: 0);
      await controller.initialize();
      expect(controller.config.currentIndex, 0);
      expect(controller.currentWallpaper?.id, '1');

      // Simulate storage updated externally (e.g. by home screen widget)
      fakeStorage.storedConfig = const SlideshowConfig(currentIndex: 1);
      await controller.reloadFromStorage();
      expect(controller.config.currentIndex, 1);
      expect(controller.currentWallpaper?.id, '2');
    });

    test('updateTargetScreen updates config without applying wallpaper when inactive, applies when running', () async {
      fakeStorage.storedItems = [
        WallpaperItem(id: '1', path: '/path/to/wall1.jpg', fileName: 'wall1.jpg', width: 1080, height: 1920, fileSize: 100, isEnabled: true, dateAdded: DateTime.now()),
      ];
      fakeStorage.storedConfig = const SlideshowConfig(targetScreen: 'both', scaleType: 'full', currentIndex: 0, isSlideshowEnabled: false);
      await controller.initialize();

      // Inactive: updates config but does NOT set wallpaper
      await controller.updateTargetScreen('home');
      expect(controller.config.targetScreen, 'home');
      expect(fakeWallpaperService.lastWallpaperSet, isNull);

      // Turn on running state
      await controller.toggleSlideshowEnabled(true);
      expect(controller.config.isSlideshowEnabled, true);
      expect(fakeWallpaperService.lastWallpaperSet, '/path/to/wall1.jpg');

      // Now running: changing target screen immediately applies to wallpaper
      await controller.updateTargetScreen('lock');
      expect(controller.config.targetScreen, 'lock');
      expect(fakeWallpaperService.lastTargetScreen, 'lock');
    });

    test('updateScaleType updates config without applying wallpaper when inactive, applies when running', () async {
      fakeStorage.storedItems = [
        WallpaperItem(id: '1', path: '/path/to/wall1.jpg', fileName: 'wall1.jpg', width: 1080, height: 1920, fileSize: 100, isEnabled: true, dateAdded: DateTime.now()),
      ];
      fakeStorage.storedConfig = const SlideshowConfig(targetScreen: 'both', scaleType: 'full', currentIndex: 0, isSlideshowEnabled: false);
      await controller.initialize();

      // Inactive: updates config but does NOT set wallpaper
      await controller.updateScaleType('crop');
      expect(controller.config.scaleType, 'crop');
      expect(fakeWallpaperService.lastWallpaperSet, isNull);

      // Turn on running state
      await controller.toggleSlideshowEnabled(true);
      expect(controller.config.isSlideshowEnabled, true);
      expect(fakeWallpaperService.lastWallpaperSet, '/path/to/wall1.jpg');
      expect(fakeWallpaperService.lastScaleType, 'crop');

      // Now running: changing scale type immediately applies to wallpaper
      await controller.updateScaleType('fit');
      expect(controller.config.scaleType, 'fit');
      expect(fakeWallpaperService.lastScaleType, 'fit');
    });

    test('togglePersistentNotification updates config, saves storage, and invokes wallpaperService', () async {
      await controller.initialize();
      expect(controller.config.showPersistentNotification, false);

      final res = await controller.togglePersistentNotification(true);
      expect(res, true);
      expect(controller.config.showPersistentNotification, true);
      expect(fakeStorage.storedConfig.showPersistentNotification, true);
      expect(fakeWallpaperService.lastPersistentNotificationSet, true);

      final res2 = await controller.togglePersistentNotification(false);
      expect(res2, true);
      expect(controller.config.showPersistentNotification, false);
      expect(fakeStorage.storedConfig.showPersistentNotification, false);
      expect(fakeWallpaperService.lastPersistentNotificationSet, false);
    });

    test('initialize restores persistent notification if enabled in config', () async {
      fakeStorage.storedConfig = const SlideshowConfig(showPersistentNotification: true);
      await controller.initialize();

      expect(controller.config.showPersistentNotification, true);
      expect(fakeWallpaperService.lastPersistentNotificationSet, true);
    });

    test('setCurrentWallpaper sets current wallpaper, persists ID and updates currentWallpaper', () async {
      final item1 = WallpaperItem(
        id: '1',
        path: '/path/1.jpg',
        fileName: '1.jpg',
        width: 1080,
        height: 1920,
        fileSize: 100,
        dateAdded: DateTime.now(),
      );
      final item2 = WallpaperItem(
        id: '2',
        path: '/path/2.jpg',
        fileName: '2.jpg',
        width: 1080,
        height: 1920,
        fileSize: 100,
        dateAdded: DateTime.now(),
      );
      fakeStorage.storedItems = [item1, item2];
      await controller.initialize();

      expect(controller.currentWallpaper?.id, '1');

      final success = await controller.setCurrentWallpaper(item2);
      expect(success, true);
      expect(controller.currentWallpaper?.id, '2');
      expect(controller.currentWallpaperId, '2');
      expect(fakeStorage.storedCurrentWallpaperId, '2');
      expect(fakeWallpaperService.lastWallpaperSet, '/path/2.jpg');
    });
  });
}
