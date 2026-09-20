import 'package:flutter_test/flutter_test.dart';
import 'package:wall_tap/models/album.dart';
import 'package:wall_tap/models/album_widget_config.dart';

void main() {
  group('Album Model Tests', () {
    test('Serializes to and from JSON', () {
      final now = DateTime.now();
      final album = Album(
        id: 'album_1',
        name: 'Nature Landscapes',
        wallpaperIds: ['w1', 'w2', 'w3'],
        dateCreated: now,
        coverPath: '/path/to/cover.jpg',
      );

      final jsonString = album.toJson();
      final deserialized = Album.fromJson(jsonString);

      expect(deserialized.id, equals('album_1'));
      expect(deserialized.name, equals('Nature Landscapes'));
      expect(deserialized.wallpaperIds, equals(['w1', 'w2', 'w3']));
      expect(deserialized.count, equals(3));
      expect(deserialized.coverPath, equals('/path/to/cover.jpg'));
      expect(
        deserialized.dateCreated.millisecondsSinceEpoch,
        equals(now.millisecondsSinceEpoch),
      );
    });

    test('copyWith works properly', () {
      final album = Album(
        id: 'album_1',
        name: 'Cars',
        wallpaperIds: ['c1'],
        dateCreated: DateTime.now(),
      );

      final updated = album.copyWith(
        name: 'Supercars',
        wallpaperIds: ['c1', 'c2'],
      );

      expect(updated.id, equals('album_1'));
      expect(updated.name, equals('Supercars'));
      expect(updated.wallpaperIds, equals(['c1', 'c2']));
      expect(updated.count, equals(2));
    });
  });

  group('AlbumWidgetConfig Model Tests', () {
    test('Serializes to and from Map and JSON with currentImagePath and totalImages', () {
      const config = AlbumWidgetConfig(
        widgetId: 12,
        albumId: 'all_photos',
        albumName: 'All Photos',
        intervalMinutes: 1,
        isRandom: false,
        currentIndex: 2,
        currentImagePath: '/wallpapers/img_1.jpg',
        totalImages: 4,
      );

      final map = config.toMap();
      expect(map['widgetId'], 12);
      expect(map['currentImagePath'], '/wallpapers/img_1.jpg');
      expect(map['totalImages'], 4);

      final deserialized = AlbumWidgetConfig.fromMap(map);
      expect(deserialized, equals(config));
      expect(deserialized.hashCode, equals(config.hashCode));
      expect(deserialized.currentImagePath, '/wallpapers/img_1.jpg');
      expect(deserialized.totalImages, 4);

      final jsonString = config.toJson();
      final fromJson = AlbumWidgetConfig.fromJson(jsonString);
      expect(fromJson, equals(config));
    });

    test('copyWith correctly updates fields', () {
      const config = AlbumWidgetConfig(
        widgetId: 10,
        albumId: 'favs',
        albumName: 'Favorites',
      );

      final updated = config.copyWith(
        currentIndex: 3,
        currentImagePath: '/new_path.jpg',
        totalImages: 5,
      );

      expect(updated.currentIndex, 3);
      expect(updated.currentImagePath, '/new_path.jpg');
      expect(updated.totalImages, 5);
      expect(updated.widgetId, 10);
      expect(updated.albumId, 'favs');
    });
  });
}
