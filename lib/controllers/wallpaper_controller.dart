import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/wallpaper_item.dart';
import '../models/slideshow_config.dart';
import '../models/album.dart';
import '../models/album_widget_config.dart';
import '../services/storage_service.dart';
import '../services/wallpaper_service.dart';

class WallpaperController extends ChangeNotifier {
  final StorageService _storageService;
  final WallpaperService _wallpaperService;

  List<WallpaperItem> _items = [];
  List<Album> _albums = [];
  List<AlbumWidgetConfig> _albumWidgets = [];
  String? _activeAlbumId;
  SlideshowConfig _config = const SlideshowConfig();
  bool _isLoading = false;
  bool _isBatteryOptimizationIgnored = false;
  String? _statusMessage;
  String? _currentWallpaperId;
  int? _nextIndex;

  String? get currentWallpaperId => _currentWallpaperId;
  int? get nextIndex => _nextIndex;

  WallpaperItem? get nextWallpaper {
    final active = activeItems;
    if (active.isEmpty) return null;
    if (_nextIndex != null && _nextIndex! >= 0 && _nextIndex! < active.length) {
      return active[_nextIndex!];
    }
    if (active.length > 1) {
      final nextIdx = (_config.currentIndex + 1) % active.length;
      return active[nextIdx];
    }
    return null;
  }

  WallpaperController({
    StorageService? storageService,
    WallpaperService? wallpaperService,
  })  : _storageService = storageService ?? StorageService(),
        _wallpaperService = wallpaperService ?? WallpaperService() {
    _wallpaperService.onWidgetSync = () {
      reloadFromStorage();
      loadAlbumWidgets();
    };
  }

  List<WallpaperItem> get items => List.unmodifiable(_items);
  List<Album> get albums => List.unmodifiable(_albums);
  List<AlbumWidgetConfig> get albumWidgets => List.unmodifiable(_albumWidgets);
  String? get activeAlbumId => _activeAlbumId;

  Album? get activeAlbum {
    if (_activeAlbumId == null) return null;
    final index = _albums.indexWhere((a) => a.id == _activeAlbumId);
    return index != -1 ? _albums[index] : null;
  }

  SlideshowConfig get config => _config;
  bool get isLoading => _isLoading;
  bool get isBatteryOptimizationIgnored => _isBatteryOptimizationIgnored;
  String? get statusMessage => _statusMessage;
  WallpaperService get wallpaperService => _wallpaperService;

  List<WallpaperItem> get activeItems {
    final album = activeAlbum;
    if (album != null) {
      final idSet = album.wallpaperIds.toSet();
      return _items.where((item) => item.isEnabled && idSet.contains(item.id)).toList();
    }
    return _items.where((item) => item.isEnabled).toList();
  }

  List<WallpaperItem> getAlbumItems(String albumId) {
    if (albumId == 'all' || albumId == 'all_photos' || albumId.isEmpty) {
      return _items;
    }
    final index = _albums.indexWhere((a) => a.id == albumId);
    if (index == -1) return _items;
    final album = _albums[index];
    final itemMap = {for (final item in _items) item.id: item};
    final list = <WallpaperItem>[];
    for (final id in album.wallpaperIds) {
      final item = itemMap[id];
      if (item != null) {
        list.add(item);
      }
    }
    return list;
  }

  WallpaperItem? get currentWallpaper {
    if (_currentWallpaperId != null) {
      final match = _items.where((e) => e.id == _currentWallpaperId);
      if (match.isNotEmpty) return match.first;
      return null;
    }
    final active = activeItems;
    if (active.isEmpty) {
      return _items.isNotEmpty ? _items.first : null;
    }
    final index = _config.currentIndex;
    if (index >= 0 && index < active.length) {
      return active[index];
    }
    return active.first;
  }

  Future<void> initialize() async {
    _setLoading(true);
    try {
      _items = await _storageService.loadItems();
      _albums = await _storageService.loadAlbums();
      _activeAlbumId = await _storageService.loadActiveAlbumId();
      if (_activeAlbumId != null && !_albums.any((a) => a.id == _activeAlbumId)) {
        _activeAlbumId = null;
        await _storageService.saveActiveAlbumId(null);
      }
      _config = await _storageService.loadConfig();
      _nextIndex = await _storageService.loadNextIndex();
      _currentWallpaperId = await _storageService.loadCurrentWallpaperId();
      if (_currentWallpaperId == null && activeItems.isNotEmpty) {
        final idx = _config.currentIndex;
        if (idx >= 0 && idx < activeItems.length) {
          _currentWallpaperId = activeItems[idx].id;
        } else {
          _currentWallpaperId = activeItems.first.id;
        }
      }
      _isBatteryOptimizationIgnored = await _wallpaperService.isBatteryOptimizationIgnored();
      if (_config.isSlideshowEnabled && _config.intervalMinutes > 0) {
        await _wallpaperService.updateSchedule(_config.intervalMinutes);
      } else {
        await _wallpaperService.updateSchedule(0);
      }
      await _syncWidgetAndPlaylist();
      await loadAlbumWidgets();
    } catch (e) {
      debugPrint('Error initializing controller: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _syncWidgetAndPlaylist() async {
    final paths = activeItems.map((e) => e.path).toList();
    await _storageService.syncActivePlaylistPaths(paths);
    if (paths.isNotEmpty) {
      int nextIdx = 0;
      if (paths.length > 1) {
        if (_config.isRandom) {
          int r = Random().nextInt(paths.length);
          if (r == _config.currentIndex) {
            r = (r + 1) % paths.length;
          }
          nextIdx = r;
        } else {
          nextIdx = (_config.currentIndex + 1) % paths.length;
        }
      }
      _nextIndex = nextIdx;
      await _storageService.saveNextIndex(nextIdx);
    }
    await _wallpaperService.updateWidget();
  }

  Future<int> importImages(List<String> filePaths, {String? targetAlbumId}) async {
    if (filePaths.isEmpty) return 0;
    _setLoading(true);
    int addedCount = 0;
    final addedIds = <String>[];
    try {
      for (final path in filePaths) {
        final item = await _storageService.saveImageToStorage(path);
        if (item != null) {
          _items.add(item);
          addedIds.add(item.id);
          addedCount++;
        }
      }
      if (addedCount > 0) {
        await _storageService.saveItems(_items);

        if (targetAlbumId != null) {
          final albumIndex = _albums.indexWhere((a) => a.id == targetAlbumId);
          if (albumIndex != -1) {
            final updatedIds = List<String>.from(_albums[albumIndex].wallpaperIds)..addAll(addedIds);
            _albums[albumIndex] = _albums[albumIndex].copyWith(wallpaperIds: updatedIds);
            await _storageService.saveAlbums(_albums);
          }
        }

        await _syncWidgetAndPlaylist();
        await syncAllAlbumWidgets();
      }
    } catch (e) {
      debugPrint('Error importing images: $e');
    } finally {
      _setLoading(false);
    }
    return addedCount;
  }

  Future<int> importFolder(String folderPath, {String? targetAlbumId}) async {
    _setLoading(true);
    int addedCount = 0;
    try {
      final dir = Directory(folderPath);
      if (await dir.exists()) {
        final supportedExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.bmp'};
        final entities = dir.listSync(recursive: false);
        final imagePaths = <String>[];

        for (final entity in entities) {
          if (entity is File) {
            final ext = entity.path.toLowerCase();
            if (supportedExtensions.any((e) => ext.endsWith(e))) {
              imagePaths.add(entity.path);
            }
          }
        }

        addedCount = await importImages(imagePaths, targetAlbumId: targetAlbumId);
      }
    } catch (e) {
      debugPrint('Error importing folder: $e');
    } finally {
      _setLoading(false);
    }
    return addedCount;
  }

  Future<int> pickAndImportFolder({String? targetAlbumId}) async {
    _setLoading(true);
    try {
      final imagePaths = await _wallpaperService.pickFolderAndGetImages();
      if (imagePaths.isNotEmpty) {
        final count = await importImages(imagePaths, targetAlbumId: targetAlbumId);
        for (final path in imagePaths) {
          try {
            final f = File(path);
            if (await f.exists()) {
              await f.delete();
            }
          } catch (_) {}
        }
        return count;
      }
      return 0;
    } catch (e) {
      debugPrint('Error picking and importing folder: $e');
      return 0;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteItem(String id) async {
    await deleteItems([id]);
  }

  Future<int> deleteItems(Iterable<String> ids) async {
    final idSet = ids.toSet();
    if (idSet.isEmpty) return 0;

    final toRemove = _items.where((item) => idSet.contains(item.id)).toList();
    if (toRemove.isEmpty) return 0;

    _items.removeWhere((item) => idSet.contains(item.id));

    // Remove deleted wallpaper IDs from all albums
    bool albumsChanged = false;
    for (int i = 0; i < _albums.length; i++) {
      if (_albums[i].wallpaperIds.any((id) => idSet.contains(id))) {
        _albums[i] = _albums[i].copyWith(
          wallpaperIds: _albums[i].wallpaperIds.where((id) => !idSet.contains(id)).toList(),
        );
        albumsChanged = true;
      }
    }
    if (albumsChanged) {
      await _storageService.saveAlbums(_albums);
    }

    for (final item in toRemove) {
      await _storageService.deleteWallpaperFile(item.path);
    }

    if (_currentWallpaperId != null && idSet.contains(_currentWallpaperId)) {
      _currentWallpaperId = null;
      await _storageService.saveCurrentWallpaperId(null);
    }

    final active = activeItems;
    if (_config.currentIndex >= active.length) {
      _config = _config.copyWith(currentIndex: max(0, active.length - 1));
      await _storageService.saveConfig(_config);
    }

    await _syncWidgetAndPlaylist();
    await syncAllAlbumWidgets();
    notifyListeners();
    return toRemove.length;
  }

  Future<void> toggleItemEnabled(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final updated = _items[index].copyWith(isEnabled: !_items[index].isEnabled);
    _items[index] = updated;
    await _storageService.saveItems(_items);
    await _syncWidgetAndPlaylist();
    notifyListeners();
  }

  Future<void> setItemsEnabled(Iterable<String> ids, bool enabled) async {
    final idSet = ids.toSet();
    if (idSet.isEmpty) return;

    bool changed = false;
    for (int i = 0; i < _items.length; i++) {
      if (idSet.contains(_items[i].id) && _items[i].isEnabled != enabled) {
        _items[i] = _items[i].copyWith(isEnabled: enabled);
        changed = true;
      }
    }
    if (!changed) return;

    await _storageService.saveItems(_items);
    await _syncWidgetAndPlaylist();
    notifyListeners();
  }

  // --- Album Management ---

  Future<Album> createAlbum(String name, {List<String>? initialItemIds}) async {
    final newAlbum = Album(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Untitled Album' : name.trim(),
      wallpaperIds: initialItemIds != null ? List<String>.from(initialItemIds) : [],
      dateCreated: DateTime.now(),
    );
    _albums.add(newAlbum);
    await _storageService.saveAlbums(_albums);
    notifyListeners();
    return newAlbum;
  }

  Future<void> renameAlbum(String albumId, String newName) async {
    final index = _albums.indexWhere((a) => a.id == albumId);
    if (index == -1) return;
    _albums[index] = _albums[index].copyWith(
      name: newName.trim().isEmpty ? 'Untitled Album' : newName.trim(),
    );
    await _storageService.saveAlbums(_albums);
    notifyListeners();
  }

  Future<void> deleteAlbum(String albumId) async {
    _albums.removeWhere((a) => a.id == albumId);
    if (_activeAlbumId == albumId) {
      _activeAlbumId = null;
      await _storageService.saveActiveAlbumId(null);
      await _syncWidgetAndPlaylist();
    }
    await _storageService.saveAlbums(_albums);
    await syncAllAlbumWidgets();
    notifyListeners();
  }

  Future<void> addItemsToAlbum(String albumId, Iterable<String> itemIds) async {
    final index = _albums.indexWhere((a) => a.id == albumId);
    if (index == -1) return;
    final currentIds = List<String>.from(_albums[index].wallpaperIds);
    for (final id in itemIds) {
      if (!currentIds.contains(id)) {
        currentIds.add(id);
      }
    }
    _albums[index] = _albums[index].copyWith(wallpaperIds: currentIds);
    await _storageService.saveAlbums(_albums);
    if (_activeAlbumId == albumId) {
      await _syncWidgetAndPlaylist();
    }
    await syncAllAlbumWidgets();
    notifyListeners();
  }

  Future<void> removeItemsFromAlbum(String albumId, Iterable<String> itemIds) async {
    final index = _albums.indexWhere((a) => a.id == albumId);
    if (index == -1) return;
    final idSet = itemIds.toSet();
    final currentIds = _albums[index].wallpaperIds.where((id) => !idSet.contains(id)).toList();
    _albums[index] = _albums[index].copyWith(wallpaperIds: currentIds);
    await _storageService.saveAlbums(_albums);
    if (_activeAlbumId == albumId) {
      final active = activeItems;
      if (_config.currentIndex >= active.length) {
        _config = _config.copyWith(currentIndex: max(0, active.length - 1));
        await _storageService.saveConfig(_config);
      }
      await _syncWidgetAndPlaylist();
    }
    await syncAllAlbumWidgets();
    notifyListeners();
  }

  Future<void> setActiveAlbum(String? albumId) async {
    if (albumId != null && !_albums.any((a) => a.id == albumId)) {
      albumId = null;
    }
    _activeAlbumId = albumId;
    await _storageService.saveActiveAlbumId(albumId);
    _config = _config.copyWith(currentIndex: 0);
    await _storageService.saveConfig(_config);
    await _syncWidgetAndPlaylist();
    notifyListeners();
  }

  // --- Configuration ---

  Future<bool> updateTargetScreen(String target) async {
    _config = _config.copyWith(targetScreen: target);
    await _storageService.saveConfig(_config);
    notifyListeners();

    if (_config.isSlideshowEnabled) {
      final current = currentWallpaper;
      if (current != null) {
        return await _wallpaperService.setWallpaper(
          filePath: current.path,
          targetScreen: _config.targetScreen,
          scaleType: _config.scaleType,
        );
      }
    }
    return true;
  }

  Future<bool> updateScaleType(String scale) async {
    _config = _config.copyWith(scaleType: scale);
    await _storageService.saveConfig(_config);
    notifyListeners();

    if (_config.isSlideshowEnabled) {
      final current = currentWallpaper;
      if (current != null) {
        return await _wallpaperService.setWallpaper(
          filePath: current.path,
          targetScreen: _config.targetScreen,
          scaleType: _config.scaleType,
        );
      }
    }
    return true;
  }

  Future<void> updateDefaultScaleType(String scale) async {
    _config = _config.copyWith(defaultScaleType: scale);
    await _storageService.saveConfig(_config);
    notifyListeners();
  }

  Future<void> setDefaultHomeWallpaper(String? path) async {
    if (path == null) {
      _config = _config.copyWith(clearDefaultHome: true);
    } else {
      final item = await _storageService.saveImageToStorage(path, customName: 'default_home');
      _config = _config.copyWith(defaultHomePath: item?.path ?? path);
    }
    await _storageService.saveConfig(_config);
    notifyListeners();
  }

  Future<void> setDefaultLockWallpaper(String? path) async {
    if (path == null) {
      _config = _config.copyWith(clearDefaultLock: true);
    } else {
      final item = await _storageService.saveImageToStorage(path, customName: 'default_lock');
      _config = _config.copyWith(defaultLockPath: item?.path ?? path);
    }
    await _storageService.saveConfig(_config);
    notifyListeners();
  }

  Future<void> toggleRandom(bool isRandom) async {
    _config = _config.copyWith(isRandom: isRandom);
    await _storageService.saveConfig(_config);
    notifyListeners();
  }

  Future<void> toggleSlideshowEnabled(bool enabled) async {
    _config = _config.copyWith(isSlideshowEnabled: enabled);
    await _storageService.saveConfig(_config);
    await _syncWidgetAndPlaylist();

    if (enabled) {
      if (_config.intervalMinutes > 0) {
        await _wallpaperService.updateSchedule(_config.intervalMinutes);
      }
      final current = currentWallpaper;
      if (current != null) {
        await _wallpaperService.setWallpaper(
          filePath: current.path,
          targetScreen: _config.targetScreen,
          scaleType: _config.scaleType,
        );
      }
    } else {
      await _wallpaperService.updateSchedule(0);
    }

    notifyListeners();
  }

  Future<void> updateInterval(int minutes) async {
    _config = _config.copyWith(intervalMinutes: minutes);
    await _storageService.saveConfig(_config);
    if (_config.isSlideshowEnabled && minutes > 0) {
      await _wallpaperService.updateSchedule(minutes);
    } else {
      await _wallpaperService.updateSchedule(0);
    }
    notifyListeners();
  }

  Future<void> checkBatteryOptimizationStatus() async {
    _isBatteryOptimizationIgnored = await _wallpaperService.isBatteryOptimizationIgnored();
    notifyListeners();
  }

  Future<bool> requestDisableBatteryOptimization() async {
    final success = await _wallpaperService.requestIgnoreBatteryOptimizations();
    _isBatteryOptimizationIgnored = await _wallpaperService.isBatteryOptimizationIgnored();
    notifyListeners();
    return success;
  }

  Future<bool> shuffleNext() async {
    final active = activeItems;
    if (active.isEmpty) return false;

    int nextIndex;
    final savedNext = await _storageService.loadNextIndex();
    if (savedNext != null &&
        savedNext >= 0 &&
        savedNext < active.length &&
        (active.length == 1 || savedNext != _config.currentIndex)) {
      nextIndex = savedNext;
    } else {
      if (_config.isRandom && active.length > 1) {
        int r = Random().nextInt(active.length);
        if (r == _config.currentIndex) {
          r = (r + 1) % active.length;
        }
        nextIndex = r;
      } else {
        nextIndex = (_config.currentIndex + 1) % active.length;
      }
    }

    final item = active[nextIndex];
    final success = await _wallpaperService.setWallpaper(
      filePath: item.path,
      targetScreen: _config.targetScreen,
      scaleType: _config.scaleType,
    );

    if (success) {
      _currentWallpaperId = item.id;
      await _storageService.saveCurrentWallpaperId(item.id);
      _config = _config.copyWith(currentIndex: nextIndex);
      await _storageService.saveConfig(_config);
      await _syncWidgetAndPlaylist();
      notifyListeners();
    }
    return success;
  }

  Future<bool> setCurrentWallpaper(WallpaperItem item) async {
    final active = activeItems;
    final index = active.indexWhere((e) => e.id == item.id);
    final targetIndex = index != -1 ? index : _config.currentIndex;

    final success = await _wallpaperService.setWallpaper(
      filePath: item.path,
      targetScreen: _config.targetScreen,
      scaleType: _config.scaleType,
    );

    if (success) {
      _currentWallpaperId = item.id;
      await _storageService.saveCurrentWallpaperId(item.id);
      if (index != -1) {
        _config = _config.copyWith(currentIndex: targetIndex);
        await _storageService.saveConfig(_config);
        await _syncWidgetAndPlaylist();
      }
      notifyListeners();
    }
    return success;
  }

  void sortItemsAlphabetical() {
    _items.sort((a, b) => a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase()));
    _storageService.saveItems(_items);
    notifyListeners();
  }

  void sortItemsByResolution() {
    _items.sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
    _storageService.saveItems(_items);
    notifyListeners();
  }

  void sortItemsByDate() {
    _items.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    _storageService.saveItems(_items);
    notifyListeners();
  }

  // --- Album Widget Management ---

  Future<void> loadAlbumWidgets() async {
    try {
      final widgets = await _wallpaperService.getAlbumWidgets();
      bool changed = false;
      if (widgets.length != _albumWidgets.length) {
        changed = true;
      } else {
        for (int i = 0; i < widgets.length; i++) {
          if (widgets[i] != _albumWidgets[i]) {
            changed = true;
            break;
          }
        }
      }
      if (changed || _albumWidgets.isEmpty) {
        _albumWidgets = widgets;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading album widgets: $e');
    }
  }

  Future<void> updateAlbumWidgetConfig(AlbumWidgetConfig config) async {
    final index = _albumWidgets.indexWhere((w) => w.widgetId == config.widgetId);
    if (index != -1) {
      _albumWidgets[index] = config;
    } else {
      _albumWidgets.add(config);
    }
    notifyListeners();
    await _wallpaperService.updateAlbumWidget(config);
    await loadAlbumWidgets();
  }

  Future<void> shuffleAlbumWidget(int widgetId) async {
    await _wallpaperService.shuffleAlbumWidget(widgetId);
    await loadAlbumWidgets();
  }

  Future<void> syncAllAlbumWidgets() async {
    await _wallpaperService.updateAllAlbumWidgets();
    await loadAlbumWidgets();
  }

  Future<void> reloadFromStorage() async {
    try {
      final freshConfig = await _storageService.loadConfig();
      final freshActiveAlbumId = await _storageService.loadActiveAlbumId();
      final freshBattery = await _wallpaperService.isBatteryOptimizationIgnored();
      bool changed = false;
      if (_config.currentIndex != freshConfig.currentIndex ||
          _config.intervalMinutes != freshConfig.intervalMinutes ||
          _config.isRandom != freshConfig.isRandom ||
          _config.isSlideshowEnabled != freshConfig.isSlideshowEnabled ||
          _config.targetScreen != freshConfig.targetScreen ||
          _config.scaleType != freshConfig.scaleType) {
        _config = freshConfig;
        changed = true;
      }
      if (_activeAlbumId != freshActiveAlbumId) {
        _activeAlbumId = freshActiveAlbumId;
        changed = true;
      }
      if (_isBatteryOptimizationIgnored != freshBattery) {
        _isBatteryOptimizationIgnored = freshBattery;
        changed = true;
      }
      final freshNextIndex = await _storageService.loadNextIndex();
      if (_nextIndex != freshNextIndex) {
        _nextIndex = freshNextIndex;
        changed = true;
      }
      final freshWallpaperId = await _storageService.loadCurrentWallpaperId();
      if (_currentWallpaperId != freshWallpaperId) {
        _currentWallpaperId = freshWallpaperId;
        changed = true;
      }
      if (_currentWallpaperId == null || _currentWallpaperId!.isEmpty) {
        final active = activeItems;
        if (freshConfig.currentIndex >= 0 && freshConfig.currentIndex < active.length) {
          _currentWallpaperId = active[freshConfig.currentIndex].id;
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
      }
      await loadAlbumWidgets();
    } catch (e) {
      debugPrint('Error reloading from storage: $e');
    }
  }
}
