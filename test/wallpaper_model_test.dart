import 'package:flutter_test/flutter_test.dart';
import 'package:wall_tap/models/wallpaper_item.dart';
import 'package:wall_tap/models/slideshow_config.dart';

void main() {
  group('WallpaperItem Tests', () {
    test('Correctly calculates resolution text', () {
      const item = WallpaperItem(
        id: '1',
        path: '/tmp/test.jpg',
        fileName: 'test.jpg',
        width: 1441,
        height: 2560,
        fileSize: 2048000,
        dateAdded: _ConstDateTime(0),
      );

      expect(item.resolutionText, '1441x2560');
      expect(item.formattedSize, '2.0 MB');
    });

    test('Serializes to and from JSON', () {
      final now = DateTime.now();
      final item = WallpaperItem(
        id: '123',
        path: '/storage/wallpapers/image.png',
        fileName: 'image.png',
        width: 3328,
        height: 4864,
        fileSize: 5242880,
        isEnabled: true,
        dateAdded: now,
      );

      final jsonStr = item.toJson();
      final restored = WallpaperItem.fromJson(jsonStr);

      expect(restored.id, item.id);
      expect(restored.path, item.path);
      expect(restored.fileName, item.fileName);
      expect(restored.width, item.width);
      expect(restored.height, item.height);
      expect(restored.fileSize, item.fileSize);
      expect(restored.isEnabled, item.isEnabled);
      expect(restored.dateAdded.millisecondsSinceEpoch, item.dateAdded.millisecondsSinceEpoch);
    });

    test('copyWith works properly', () {
      const item = WallpaperItem(
        id: '1',
        path: '/path.jpg',
        fileName: 'path.jpg',
        width: 100,
        height: 200,
        fileSize: 1000,
        isEnabled: true,
        dateAdded: _ConstDateTime(0),
      );

      final updated = item.copyWith(isEnabled: false, fileName: 'new.jpg');
      expect(updated.isEnabled, false);
      expect(updated.fileName, 'new.jpg');
      expect(updated.id, '1');
    });
  });

  group('SlideshowConfig Tests', () {
    test('Default values and label getters', () {
      const config = SlideshowConfig();
      expect(config.targetScreen, 'both');
      expect(config.scaleType, 'crop');
      expect(config.targetScreenLabel, 'Home and Lock screen');
      expect(config.scaleTypeLabel, 'Center crop');
      expect(config.intervalMinutes, 0);
      expect(config.intervalLabel, 'Off (Manual)');
      expect(config.isSlideshowEnabled, false);
    });

    test('Serializes to and from JSON', () {
      const config = SlideshowConfig(
        targetScreen: 'home',
        scaleType: 'crop',
        defaultHomePath: '/home/default.jpg',
        defaultLockPath: null,
        currentIndex: 3,
        isRandom: true,
        isSlideshowEnabled: false,
        intervalMinutes: 60,
      );

      final jsonStr = config.toJson();
      final restored = SlideshowConfig.fromJson(jsonStr);

      expect(restored.targetScreen, 'home');
      expect(restored.scaleType, 'crop');
      expect(restored.defaultHomePath, '/home/default.jpg');
      expect(restored.defaultLockPath, isNull);
      expect(restored.currentIndex, 3);
      expect(restored.isRandom, true);
      expect(restored.isSlideshowEnabled, false);
      expect(restored.intervalMinutes, 60);
    });

    test('copyWith handles clearDefaultHome and clearDefaultLock', () {
      const config = SlideshowConfig(
        defaultHomePath: '/home.jpg',
        defaultLockPath: '/lock.jpg',
      );

      final updated = config.copyWith(clearDefaultHome: true);
      expect(updated.defaultHomePath, isNull);
      expect(updated.defaultLockPath, '/lock.jpg');
    });
  });
}

class _ConstDateTime implements DateTime {
  final int _ms;
  const _ConstDateTime(this._ms);

  @override
  int get millisecondsSinceEpoch => _ms;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
