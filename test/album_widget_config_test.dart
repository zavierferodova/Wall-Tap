import 'package:flutter_test/flutter_test.dart';
import 'package:wall_tap/models/album_widget_config.dart';

void main() {
  group('AlbumWidgetConfig Tests', () {
    test('Default values and getters', () {
      const config = AlbumWidgetConfig(
        widgetId: 101,
        albumId: 'album_1',
        albumName: 'Cars',
      );

      expect(config.widgetId, 101);
      expect(config.albumId, 'album_1');
      expect(config.albumName, 'Cars');
      expect(config.intervalMinutes, 15);
      expect(config.isRandom, true);
      expect(config.currentIndex, 0);
      expect(config.intervalLabel, '15 minutes');
    });

    test('intervalLabel formats correctly', () {
      expect(const AlbumWidgetConfig(widgetId: 1, albumId: 'a', intervalMinutes: 0).intervalLabel, 'Manual');
      expect(const AlbumWidgetConfig(widgetId: 1, albumId: 'a', intervalMinutes: 1).intervalLabel, '1 minute');
      expect(const AlbumWidgetConfig(widgetId: 1, albumId: 'a', intervalMinutes: 30).intervalLabel, '30 minutes');
      expect(const AlbumWidgetConfig(widgetId: 1, albumId: 'a', intervalMinutes: 60).intervalLabel, '1 hour');
      expect(const AlbumWidgetConfig(widgetId: 1, albumId: 'a', intervalMinutes: 180).intervalLabel, '3 hours');
      expect(const AlbumWidgetConfig(widgetId: 1, albumId: 'a', intervalMinutes: 1440).intervalLabel, 'Daily (24h)');
    });

    test('Serializes to and from JSON and Map', () {
      const config = AlbumWidgetConfig(
        widgetId: 202,
        albumId: 'nature_9',
        albumName: 'Nature',
        intervalMinutes: 60,
        isRandom: true,
        currentIndex: 3,
      );

      final map = config.toMap();
      final fromMap = AlbumWidgetConfig.fromMap(map);
      expect(fromMap.widgetId, 202);
      expect(fromMap.albumId, 'nature_9');
      expect(fromMap.albumName, 'Nature');
      expect(fromMap.intervalMinutes, 60);
      expect(fromMap.isRandom, true);
      expect(fromMap.currentIndex, 3);

      final jsonStr = config.toJson();
      final fromJson = AlbumWidgetConfig.fromJson(jsonStr);
      expect(fromJson.widgetId, 202);
      expect(fromJson.albumId, 'nature_9');
      expect(fromJson.albumName, 'Nature');
      expect(fromJson.intervalMinutes, 60);
      expect(fromJson.isRandom, true);
      expect(fromJson.currentIndex, 3);
    });

    test('copyWith works properly', () {
      const config = AlbumWidgetConfig(
        widgetId: 1,
        albumId: 'orig',
        albumName: 'Original',
        intervalMinutes: 15,
        isRandom: false,
        currentIndex: 0,
      );

      final updated = config.copyWith(
        albumId: 'new_id',
        albumName: 'New Name',
        intervalMinutes: 30,
        isRandom: true,
        currentIndex: 5,
      );

      expect(updated.widgetId, 1);
      expect(updated.albumId, 'new_id');
      expect(updated.albumName, 'New Name');
      expect(updated.intervalMinutes, 30);
      expect(updated.isRandom, true);
      expect(updated.currentIndex, 5);
    });
  });
}
