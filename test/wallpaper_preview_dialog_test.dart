import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_tap/controllers/wallpaper_controller.dart';
import 'package:wall_tap/models/slideshow_config.dart';
import 'package:wall_tap/models/wallpaper_item.dart';
import 'package:wall_tap/models/album.dart';
import 'package:wall_tap/models/album_widget_config.dart';
import 'package:wall_tap/services/storage_service.dart';
import 'package:wall_tap/services/wallpaper_service.dart';
import 'package:wall_tap/views/widgets/wallpaper_preview_dialog.dart';

class FakeStorageService extends StorageService {
  List<WallpaperItem> storedItems = [];
  List<Album> storedAlbums = [];
  String? storedActiveAlbumId;
  SlideshowConfig storedConfig = const SlideshowConfig();

  String? storedCurrentWallpaperId;

  @override
  Future<List<WallpaperItem>> loadItems() async => storedItems;
  @override
  Future<void> saveItems(List<WallpaperItem> items, {List<String>? activePlaylistPaths}) async {
    storedItems = List.from(items);
  }
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
  @override
  Future<int?> loadNextIndex() async => 0;
  @override
  Future<void> saveNextIndex(int index) async {}
  @override
  Future<String?> loadCurrentWallpaperId() async => storedCurrentWallpaperId;
  @override
  Future<void> saveCurrentWallpaperId(String? id) async {
    storedCurrentWallpaperId = id;
  }
}

class FakeWallpaperService extends WallpaperService {
  String? lastWallpaperApplied;

  @override
  Future<bool> setWallpaper({required String filePath, String targetScreen = 'both', String scaleType = 'full'}) async {
    lastWallpaperApplied = filePath;
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

  testWidgets('WallpaperPreviewDialog renders full resolution, pan/pinch viewer and sheet actions', (tester) async {
    final now = DateTime.now();
    final testItem = WallpaperItem(
      id: 'item_1',
      fileName: '34.jpg',
      path: '/non_existent/34.jpg',
      width: 4752,
      height: 2970,
      fileSize: 2200000,
      isEnabled: true,
      dateAdded: now,
    );
    fakeStorage.storedItems = [testItem];
    fakeStorage.storedCurrentWallpaperId = 'other_id';
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: WallpaperPreviewDialog(
          item: testItem,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify filename, real resolution text and size text
    expect(find.text('34.jpg'), findsOneWidget);
    expect(find.text('4752x2970'), findsOneWidget);
    expect(find.textContaining('2.1 MB'), findsOneWidget);

    // Verify InteractiveViewer is present for pan & pinch zoom
    expect(find.byType(InteractiveViewer), findsOneWidget);

    // Verify Active status and toggle button
    expect(find.text('Active in shuffle rotation'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    // Tap Active button to toggle to Excluded
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();

    // Verify state updated in real-time on overlay
    expect(find.text('Excluded from rotation'), findsOneWidget);
    expect(find.text('Excluded'), findsOneWidget);
    expect(controller.items.first.isEnabled, false);

    // Initially not current, so no CURRENT badges and button says 'Set as Current Wallpaper'
    expect(find.text('CURRENT'), findsNothing);
    expect(find.text('Set as Current Wallpaper'), findsOneWidget);

    // Tap Set as Current Wallpaper
    await tester.tap(find.text('Set as Current Wallpaper'));
    await tester.pumpAndSettle();

    expect(fakeWallpaper.lastWallpaperApplied, '/non_existent/34.jpg');
    // Button now shows active status
    expect(find.text('Current Wallpaper'), findsOneWidget);
    // Redundant CURRENT badges are removed, bottom button acts as current indicator
    expect(find.text('CURRENT'), findsNothing);

    // Verify Delete button exists
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });

  testWidgets('Single tap toggles controls visibility', (tester) async {
    final now = DateTime.now();
    final testItem = WallpaperItem(
      id: 'item_2',
      fileName: 'nature.png',
      path: '/dummy/nature.png',
      width: 1920,
      height: 1080,
      fileSize: 500000,
      isEnabled: true,
      dateAdded: now,
    );
    fakeStorage.storedItems = [testItem];
    fakeStorage.storedCurrentWallpaperId = 'other_id';
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: WallpaperPreviewDialog(
          item: testItem,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set as Current Wallpaper'), findsOneWidget);

    // Tap at screen center (outside top/bottom bars) and wait past double-tap timeout
    await tester.tapAt(const Offset(400, 260));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Verify IgnorePointer has ignoring = true for controls
    final ignorePointers = tester.widgetList<IgnorePointer>(find.byType(IgnorePointer));
    expect(ignorePointers.any((ip) => ip.ignoring == true), isTrue);
  });

  testWidgets('Shows bottom indicator green Current Wallpaper button and no CURRENT badges when item is current device wallpaper', (tester) async {
    final now = DateTime.now();
    final testItem = WallpaperItem(
      id: 'current_item',
      fileName: 'active_current.png',
      path: '/dummy/active_current.png',
      width: 3840,
      height: 2160,
      fileSize: 1500000,
      isEnabled: true,
      dateAdded: now,
    );
    fakeStorage.storedItems = [testItem];
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: WallpaperPreviewDialog(
          item: testItem,
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify CURRENT badges are NOT rendered
    expect(find.text('CURRENT'), findsNothing);
    // Verify resolution text is present
    expect(find.text('3840x2160'), findsOneWidget);
    // Verify bottom button acts as indicator with Current Wallpaper and checkmark
    expect(find.text('Current Wallpaper'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
  });
}

