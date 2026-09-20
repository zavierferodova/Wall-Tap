import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_tap/controllers/wallpaper_controller.dart';
import 'package:wall_tap/models/album.dart';
import 'package:wall_tap/models/album_widget_config.dart';
import 'package:wall_tap/models/slideshow_config.dart';
import 'package:wall_tap/models/wallpaper_item.dart';
import 'package:wall_tap/services/storage_service.dart';
import 'package:wall_tap/services/wallpaper_service.dart';
import 'package:wall_tap/views/playlist/playlist_tab.dart';
import 'package:wall_tap/views/widgets/pressable_scale.dart';

class FakeStorageService extends StorageService {
  List<WallpaperItem> storedItems = [];
  List<Album> storedAlbums = [];
  String? storedActiveAlbumId;
  SlideshowConfig storedConfig = const SlideshowConfig();
  int storedNextIndex = 0;

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
  @override
  Future<bool> updateAllAlbumWidgets() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStorageService fakeStorage;
  late FakeWallpaperService fakeWallpaper;
  late WallpaperController controller;

  setUp(() async {
    fakeStorage = FakeStorageService();
    fakeWallpaper = FakeWallpaperService();
    controller = WallpaperController(
      storageService: fakeStorage,
      wallpaperService: fakeWallpaper,
    );
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: PlaylistTab(controller: controller),
      ),
    );
  }

  testWidgets('Renders empty albums state when no albums exist and hides search bar', (tester) async {
    await controller.initialize();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Switch to Albums segment
    await tester.tap(find.text('Albums (0)'));
    await tester.pumpAndSettle();

    expect(find.text('No albums created yet'), findsOneWidget);
    expect(find.text('Create First Album'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Displays search bar and filters albums by name', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    fakeStorage.storedAlbums = [
      Album(id: '1', name: 'Nature Vibe', wallpaperIds: const ['w1'], dateCreated: now),
      Album(id: '2', name: 'Anime Collection', wallpaperIds: const ['w2'], dateCreated: now),
      Album(id: '3', name: 'Minimalist Architecture', wallpaperIds: const [], dateCreated: now),
    ];

    await controller.initialize();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Switch to Albums segment
    await tester.tap(find.text('Albums (3)'));
    await tester.pumpAndSettle();

    // All 3 albums displayed initially
    expect(find.text('Nature Vibe'), findsOneWidget);
    expect(find.text('Anime Collection'), findsOneWidget);
    expect(find.text('Minimalist Architecture'), findsOneWidget);
    expect(find.text('3 albums'), findsOneWidget);

    // Search bar is visible
    expect(find.byType(TextField), findsOneWidget);

    // Enter query 'Anime'
    await tester.enterText(find.byType(TextField), 'Anime');
    await tester.pumpAndSettle();

    // Only Anime Collection is shown
    expect(find.text('Anime Collection'), findsOneWidget);
    expect(find.text('Nature Vibe'), findsNothing);
    expect(find.text('Minimalist Architecture'), findsNothing);
    expect(find.text('1 of 3 albums found'), findsOneWidget);

    // Suffix clear button appears
    final clearIcon = find.byIcon(Icons.close_rounded);
    expect(clearIcon, findsOneWidget);

    // Tap clear button
    await tester.tap(clearIcon);
    await tester.pumpAndSettle();

    // All albums restored
    expect(find.text('Nature Vibe'), findsOneWidget);
    expect(find.text('Anime Collection'), findsOneWidget);
    expect(find.text('Minimalist Architecture'), findsOneWidget);
    expect(find.text('3 albums'), findsOneWidget);
  });

  testWidgets('Shows no results state when query does not match and allows clearing', (tester) async {
    final now = DateTime.now();
    fakeStorage.storedAlbums = [
      Album(id: '1', name: 'Cyberpunk', wallpaperIds: const [], dateCreated: now),
    ];

    await controller.initialize();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Switch to Albums
    await tester.tap(find.text('Albums (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Cyberpunk'), findsOneWidget);

    // Enter non-matching query
    await tester.enterText(find.byType(TextField), 'Futuristic');
    await tester.pumpAndSettle();

    expect(find.text('Cyberpunk'), findsNothing);
    expect(find.text('No albums found'), findsOneWidget);
    expect(find.textContaining('No albums match "Futuristic"'), findsOneWidget);
    expect(find.text('0 of 1 albums found'), findsOneWidget);

    // Tap "Clear Search" button in empty state
    await tester.tap(find.text('Clear Search'));
    await tester.pumpAndSettle();

    // Cyberpunk restored
    expect(find.text('Cyberpunk'), findsOneWidget);
    expect(find.text('No albums found'), findsNothing);
  });

  testWidgets('Header search icon focuses search field', (tester) async {
    final now = DateTime.now();
    fakeStorage.storedAlbums = [
      Album(id: '1', name: 'Wallpapers', wallpaperIds: const [], dateCreated: now),
    ];

    await controller.initialize();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Switch to Albums
    await tester.tap(find.text('Albums (1)'));
    await tester.pumpAndSettle();

    // Find the header search button
    final headerSearchBtn = find.widgetWithIcon(PressableScale, Icons.search_rounded);
    expect(headerSearchBtn, findsOneWidget);

    await tester.tap(headerSearchBtn);
    await tester.pumpAndSettle();

    // Check focus
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.focusNode?.hasFocus, isTrue);
  });

  testWidgets('Shows EXCLUDED indicator on wallpapers and toggles them', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    fakeStorage.storedItems = [
      WallpaperItem(
        id: 'wp1',
        fileName: 'Wallpaper 1.jpg',
        path: '/dummy/path1.jpg',
        width: 1080,
        height: 1920,
        fileSize: 1024,
        dateAdded: now,
        isEnabled: true,
      ),
      WallpaperItem(
        id: 'wp2',
        fileName: 'Wallpaper 2.jpg',
        path: '/dummy/path2.jpg',
        width: 1080,
        height: 1920,
        fileSize: 2048,
        dateAdded: now,
        isEnabled: false,
      ),
    ];

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await controller.initialize();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('ACTIVE'), findsNothing);
    expect(find.text('EXCLUDED'), findsOneWidget);

    // Tap toggle button on excluded wallpaper (wp2) to make it active
    final excludedIconFinder = find.byIcon(Icons.remove_circle_outline_rounded);
    expect(excludedIconFinder, findsAtLeastNWidgets(1));
    await tester.tap(excludedIconFinder.last);
    await tester.pumpAndSettle();

    // Now both should be active (no ACTIVE or EXCLUDED badges)
    expect(find.text('ACTIVE'), findsNothing);
    expect(find.text('EXCLUDED'), findsNothing);
  });

  testWidgets('Shows ACTIVE and EXCLUDED indicators on album cards', (tester) async {
    final now = DateTime.now();
    fakeStorage.storedItems = [
      WallpaperItem(
        id: 'wp1',
        fileName: 'Wallpaper 1.jpg',
        path: '/dummy/path1.jpg',
        width: 1080,
        height: 1920,
        fileSize: 1024,
        dateAdded: now,
        isEnabled: true,
      ),
      WallpaperItem(
        id: 'wp2',
        fileName: 'Wallpaper 2.jpg',
        path: '/dummy/path2.jpg',
        width: 1080,
        height: 1920,
        fileSize: 2048,
        dateAdded: now,
        isEnabled: false,
      ),
    ];
    fakeStorage.storedAlbums = [
      Album(id: 'a1', name: 'Active Album', wallpaperIds: ['wp1'], dateCreated: now),
      Album(id: 'a2', name: 'Excluded Album', wallpaperIds: ['wp2'], dateCreated: now),
    ];

    await controller.initialize();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Switch to Albums
    await tester.tap(find.text('Albums (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Active Album'), findsOneWidget);
    expect(find.text('Excluded Album'), findsOneWidget);
    expect(find.text('ACTIVE'), findsNothing);
    expect(find.text('1 wallpapers • All active'), findsOneWidget);
    expect(find.text('1 wallpapers • Excluded'), findsOneWidget);

    // Set a1 as active shuffle album
    await controller.setActiveAlbum('a1');
    await tester.pumpAndSettle();

    expect(find.text('ACTIVE SHUFFLE'), findsOneWidget);
  });

  testWidgets('Multi-selection batch Exclude and Include in PlaylistTab', (tester) async {
    final now = DateTime.now();
    fakeStorage.storedItems = [
      WallpaperItem(
        id: 'wp1',
        fileName: 'Wallpaper 1.jpg',
        path: '/dummy/path1.jpg',
        width: 1080,
        height: 1920,
        fileSize: 1024,
        dateAdded: now,
        isEnabled: true,
      ),
      WallpaperItem(
        id: 'wp2',
        fileName: 'Wallpaper 2.jpg',
        path: '/dummy/path2.jpg',
        width: 1080,
        height: 1920,
        fileSize: 2048,
        dateAdded: now,
        isEnabled: true,
      ),
    ];

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await controller.initialize();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Long press first wallpaper to enter selection mode
    await tester.longPress(find.text('1080x1920').first);
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Exclude'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    // Tap second wallpaper to select it too
    await tester.tap(find.text('1080x1920').last);
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    // Tap Exclude
    await tester.tap(find.text('Exclude'));
    await tester.pump();
    expect(find.text('Excluded 2 wallpapers'), findsOneWidget);
    await tester.pumpAndSettle();

    // Verify both are now excluded
    expect(controller.items.every((i) => !i.isEnabled), true);
    expect(find.text('EXCLUDED'), findsNWidgets(2));

    // Now long press to enter selection mode again
    await tester.longPress(find.text('1080x1920').first);
    await tester.pumpAndSettle();

    // Since it's excluded, the button should now say Include
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Include'), findsOneWidget);

    // Tap Include
    await tester.tap(find.text('Include'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Included 1 wallpaper'), findsOneWidget);
    await tester.pumpAndSettle();

    // Verify item 1 is now active
    expect(controller.items.firstWhere((i) => i.id == 'wp1').isEnabled, true);
  });

  testWidgets('Multi-selection batch Delete in PlaylistTab', (tester) async {
    final now = DateTime.now();
    fakeStorage.storedItems = [
      WallpaperItem(
        id: 'wp1',
        fileName: 'Wallpaper 1.jpg',
        path: '/dummy/path1.jpg',
        width: 1080,
        height: 1920,
        fileSize: 1024,
        dateAdded: now,
        isEnabled: true,
      ),
      WallpaperItem(
        id: 'wp2',
        fileName: 'Wallpaper 2.jpg',
        path: '/dummy/path2.jpg',
        width: 1080,
        height: 1920,
        fileSize: 2048,
        dateAdded: now,
        isEnabled: true,
      ),
    ];

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await controller.initialize();
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Long press first wallpaper to enter selection mode
    await tester.longPress(find.text('1080x1920').first);
    await tester.pumpAndSettle();

    // Tap delete button in selection header
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    // Bottom sheet confirmation should appear
    expect(find.text('Delete 1 Wallpaper?'), findsOneWidget);
    expect(find.text('Delete (1)'), findsOneWidget);

    // Tap confirm delete
    await tester.tap(find.text('Delete (1)'));
    await tester.pumpAndSettle();

    expect(controller.items.length, 1);
    expect(controller.items.first.id, 'wp2');
  });
}
