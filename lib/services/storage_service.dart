import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallpaper_item.dart';
import '../models/slideshow_config.dart';
import '../models/album.dart';

class StorageService {
  static const String _keyItems = 'walltap_items';
  static const String _keyConfig = 'walltap_config';
  static const String _keyPaths = 'walltap_playlist_paths';
  static const String _keyCurrentIndex = 'walltap_current_index';
  static const String _keyTargetScreen = 'walltap_target_screen';
  static const String _keyScaleType = 'walltap_scale_type';
  static const String _keyIsRandom = 'walltap_is_random';
  static const String _keySlideshowEnabled = 'walltap_slideshow_enabled';
  static const String _keyIntervalMinutes = 'walltap_interval_minutes';
  static const String _keyAlbums = 'walltap_albums';
  static const String _keyActiveAlbumId = 'walltap_active_album_id';
  static const String _keyNextIndex = 'walltap_next_index';
  static const String _keyShowPersistentNotification = 'walltap_show_persistent_notification';
  static const String _keyCurrentWallpaperId = 'walltap_current_wallpaper_id';

  Directory? _wallpaperDir;

  Future<Directory> get wallpaperDirectory async {
    if (_wallpaperDir != null) return _wallpaperDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/wallpapers');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _wallpaperDir = dir;
    return dir;
  }

  Future<(int, int)> getImageDimensions(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return (0, 0);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final width = frameInfo.image.width;
      final height = frameInfo.image.height;
      return (width, height);
    } catch (e) {
      debugPrint('Error getting image dimensions for $path: $e');
      return (0, 0);
    }
  }

  Future<WallpaperItem?> saveImageToStorage(String sourcePath, {String? customName}) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return null;

      final dir = await wallpaperDirectory;
      final fileName = customName ?? sourceFile.uri.pathSegments.last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final newFileName = 'wall_${timestamp}_${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_\.]'), '_')}';
      final targetPath = '${dir.path}/$newFileName.$ext';

      final savedFile = await sourceFile.copy(targetPath);
      final fileSize = await savedFile.length();
      final (width, height) = await getImageDimensions(targetPath);

      return WallpaperItem(
        id: timestamp.toString(),
        path: targetPath,
        fileName: fileName,
        width: width,
        height: height,
        fileSize: fileSize,
        isEnabled: true,
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error saving image to storage: $e');
      return null;
    }
  }

  Future<void> deleteWallpaperFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting wallpaper file: $e');
    }
  }

  Future<List<WallpaperItem>> loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyItems);
      if (jsonString == null || jsonString.isEmpty) return [];

      final list = json.decode(jsonString) as List<dynamic>;
      final items = <WallpaperItem>[];
      for (final itemMap in list) {
        final item = WallpaperItem.fromMap(itemMap as Map<String, dynamic>);
        if (File(item.path).existsSync()) {
          items.add(item);
        }
      }
      return items;
    } catch (e) {
      debugPrint('Error loading items from preferences: $e');
      return [];
    }
  }

  Future<void> saveItems(List<WallpaperItem> items, {List<String>? activePlaylistPaths}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.map((e) => e.toMap()).toList();
      await prefs.setString(_keyItems, json.encode(list));

      // Also save raw paths list for native Kotlin widget provider!
      final paths = activePlaylistPaths ??
          items.where((e) => e.isEnabled).map((e) => e.path).toList();
      await prefs.setString(_keyPaths, json.encode(paths));
    } catch (e) {
      debugPrint('Error saving items to preferences: $e');
    }
  }

  Future<void> syncActivePlaylistPaths(List<String> paths) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPaths, json.encode(paths));
    } catch (e) {
      debugPrint('Error syncing active playlist paths: $e');
    }
  }

  Future<List<Album>> loadAlbums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyAlbums);
      if (jsonString == null || jsonString.isEmpty) return [];

      final list = json.decode(jsonString) as List<dynamic>;
      return list.map((e) => Album.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading albums from preferences: $e');
      return [];
    }
  }

  Future<void> saveAlbums(List<Album> albums) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = albums.map((e) => e.toMap()).toList();
      await prefs.setString(_keyAlbums, json.encode(list));
    } catch (e) {
      debugPrint('Error saving albums to preferences: $e');
    }
  }

  Future<String?> loadActiveAlbumId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyActiveAlbumId);
    } catch (e) {
      debugPrint('Error loading active album ID: $e');
      return null;
    }
  }

  Future<void> saveActiveAlbumId(String? albumId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (albumId == null || albumId.isEmpty) {
        await prefs.remove(_keyActiveAlbumId);
      } else {
        await prefs.setString(_keyActiveAlbumId, albumId);
      }
    } catch (e) {
      debugPrint('Error saving active album ID: $e');
    }
  }

  Future<SlideshowConfig> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final jsonString = prefs.getString(_keyConfig);
      SlideshowConfig config = const SlideshowConfig();
      if (jsonString != null && jsonString.isNotEmpty) {
        config = SlideshowConfig.fromJson(jsonString);
      }

      // Sync standalone keys that might have been updated by the native Android widget
      final savedIndex = prefs.getInt(_keyCurrentIndex);
      if (savedIndex != null && savedIndex != config.currentIndex) {
        config = config.copyWith(currentIndex: savedIndex);
      }
      final savedInterval = prefs.getInt(_keyIntervalMinutes);
      if (savedInterval != null && savedInterval != config.intervalMinutes) {
        config = config.copyWith(intervalMinutes: savedInterval);
      }
      final savedRandom = prefs.getBool(_keyIsRandom);
      if (savedRandom != null && savedRandom != config.isRandom) {
        config = config.copyWith(isRandom: savedRandom);
      }
      final savedEnabled = prefs.getBool(_keySlideshowEnabled);
      if (savedEnabled != null && savedEnabled != config.isSlideshowEnabled) {
        config = config.copyWith(isSlideshowEnabled: savedEnabled);
      }
      final savedTarget = prefs.getString(_keyTargetScreen);
      if (savedTarget != null && savedTarget != config.targetScreen) {
        config = config.copyWith(targetScreen: savedTarget);
      }
      final savedScale = prefs.getString(_keyScaleType);
      if (savedScale != null && savedScale != config.scaleType) {
        config = config.copyWith(scaleType: savedScale);
      }
      final savedPersistentNotification = prefs.getBool(_keyShowPersistentNotification);
      if (savedPersistentNotification != null && savedPersistentNotification != config.showPersistentNotification) {
        config = config.copyWith(showPersistentNotification: savedPersistentNotification);
      }
      return config;
    } catch (e) {
      debugPrint('Error loading config: $e');
      return const SlideshowConfig();
    }
  }

  Future<void> saveConfig(SlideshowConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyConfig, config.toJson());

      // Sync individual keys for native Android widget access
      await prefs.setInt(_keyCurrentIndex, config.currentIndex);
      await prefs.setString(_keyTargetScreen, config.targetScreen);
      await prefs.setString(_keyScaleType, config.scaleType);
      await prefs.setBool(_keyIsRandom, config.isRandom);
      await prefs.setBool(_keySlideshowEnabled, config.isSlideshowEnabled);
      await prefs.setInt(_keyIntervalMinutes, config.intervalMinutes);
      await prefs.setBool(_keyShowPersistentNotification, config.showPersistentNotification);
    } catch (e) {
      debugPrint('Error saving config: $e');
    }
  }

  Future<void> saveNextIndex(int nextIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyNextIndex, nextIndex);
    } catch (e) {
      debugPrint('Error saving next index: $e');
    }
  }

  Future<int?> loadNextIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyNextIndex);
    } catch (e) {
      debugPrint('Error loading next index: $e');
      return null;
    }
  }

  Future<void> saveCurrentWallpaperId(String? id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id == null) {
        await prefs.remove(_keyCurrentWallpaperId);
      } else {
        await prefs.setString(_keyCurrentWallpaperId, id);
      }
    } catch (e) {
      debugPrint('Error saving current wallpaper ID: $e');
    }
  }

  Future<String?> loadCurrentWallpaperId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyCurrentWallpaperId);
    } catch (e) {
      debugPrint('Error loading current wallpaper ID: $e');
      return null;
    }
  }
}
