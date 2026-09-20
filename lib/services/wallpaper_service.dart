import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/album_widget_config.dart';

class WallpaperService {
  static const MethodChannel _channel = MethodChannel('com.walltap.app/wallpaper');

  Future<bool> setWallpaper({
    required String filePath,
    String targetScreen = 'both',
    String scaleType = 'full',
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('setWallpaper', {
        'filePath': filePath,
        'targetScreen': targetScreen,
        'scaleType': scaleType,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformException setting wallpaper: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error setting wallpaper: $e');
      return false;
    }
  }

  Future<bool> updateWidget() async {
    try {
      final result = await _channel.invokeMethod<bool>('updateWidget');
      return result ?? false;
    } catch (e) {
      debugPrint('Error updating widget: $e');
      return false;
    }
  }

  Future<(int, int)> getDisplayDimensions() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDisplayDimensions');
      if (result != null) {
        final w = (result['width'] as num?)?.toInt() ?? 1080;
        final h = (result['height'] as num?)?.toInt() ?? 2400;
        return (w, h);
      }
    } catch (e) {
      debugPrint('Error getting display dimensions: $e');
    }
    return (1080, 2400);
  }

  Future<bool> updateSchedule(int intervalMinutes) async {
    try {
      final result = await _channel.invokeMethod<bool>('updateSchedule', {
        'intervalMinutes': intervalMinutes,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error updating schedule: $e');
      return false;
    }
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
      return false;
    }
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting battery optimization: $e');
      return false;
    }
  }

  Future<List<String>> pickFolderAndGetImages() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('pickFolderAndGetImages');
      if (result != null) {
        return result.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('Error picking folder and getting images: $e');
    }
    return [];
  }

  Future<List<AlbumWidgetConfig>> getAlbumWidgets() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getAlbumWidgets');
      if (result != null) {
        return result.map((e) => AlbumWidgetConfig.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (e) {
      debugPrint('Error getting album widgets: $e');
    }
    return [];
  }

  Future<bool> updateAlbumWidget(AlbumWidgetConfig config) async {
    try {
      final result = await _channel.invokeMethod<bool>('updateAlbumWidget', {
        'widgetId': config.widgetId,
        'albumId': config.albumId,
        'albumName': config.albumName,
        'intervalMinutes': config.intervalMinutes,
        'isRandom': config.isRandom,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error updating album widget: $e');
      return false;
    }
  }

  Future<bool> shuffleAlbumWidget(int widgetId) async {
    try {
      final result = await _channel.invokeMethod<bool>('shuffleAlbumWidget', {
        'widgetId': widgetId,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error shuffling album widget: $e');
      return false;
    }
  }

  Future<bool> updateAllAlbumWidgets() async {
    try {
      final result = await _channel.invokeMethod<bool>('updateAllAlbumWidgets');
      return result ?? false;
    } catch (e) {
      debugPrint('Error updating all album widgets: $e');
      return false;
    }
  }

  Future<bool> setPersistentNotification(bool show) async {
    try {
      final method = show ? 'showPersistentNotification' : 'hidePersistentNotification';
      final result = await _channel.invokeMethod<bool>(method);
      return result ?? false;
    } catch (e) {
      debugPrint('Error setting persistent notification: $e');
      return false;
    }
  }
}
