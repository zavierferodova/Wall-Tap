import 'dart:convert';

class AlbumWidgetConfig {
  final int widgetId;
  final String albumId;
  final String albumName;
  final int intervalMinutes;
  final bool isRandom;
  final int currentIndex;
  final String currentImagePath;
  final int totalImages;

  const AlbumWidgetConfig({
    required this.widgetId,
    required this.albumId,
    this.albumName = '',
    this.intervalMinutes = 15,
    this.isRandom = true,
    this.currentIndex = 0,
    this.currentImagePath = '',
    this.totalImages = 0,
  });

  AlbumWidgetConfig copyWith({
    int? widgetId,
    String? albumId,
    String? albumName,
    int? intervalMinutes,
    bool? isRandom,
    int? currentIndex,
    String? currentImagePath,
    int? totalImages,
  }) {
    return AlbumWidgetConfig(
      widgetId: widgetId ?? this.widgetId,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      isRandom: isRandom ?? this.isRandom,
      currentIndex: currentIndex ?? this.currentIndex,
      currentImagePath: currentImagePath ?? this.currentImagePath,
      totalImages: totalImages ?? this.totalImages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'widgetId': widgetId,
      'albumId': albumId,
      'albumName': albumName,
      'intervalMinutes': intervalMinutes,
      'isRandom': isRandom,
      'currentIndex': currentIndex,
      'currentImagePath': currentImagePath,
      'totalImages': totalImages,
    };
  }

  factory AlbumWidgetConfig.fromMap(Map<String, dynamic> map) {
    return AlbumWidgetConfig(
      widgetId: (map['widgetId'] as num?)?.toInt() ?? 0,
      albumId: map['albumId'] as String? ?? '',
      albumName: map['albumName'] as String? ?? '',
      intervalMinutes: (map['intervalMinutes'] as num?)?.toInt() ?? 15,
      isRandom: map['isRandom'] as bool? ?? true,
      currentIndex: (map['currentIndex'] as num?)?.toInt() ?? 0,
      currentImagePath: map['currentImagePath'] as String? ?? '',
      totalImages: (map['totalImages'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory AlbumWidgetConfig.fromJson(String source) =>
      AlbumWidgetConfig.fromMap(json.decode(source) as Map<String, dynamic>);

  String get intervalLabel {
    if (intervalMinutes <= 0) return 'Manual';
    if (intervalMinutes == 1) return '1 minute';
    if (intervalMinutes < 60) return '$intervalMinutes minutes';
    if (intervalMinutes == 60) return '1 hour';
    if (intervalMinutes == 1440) return 'Daily (24h)';
    return '${intervalMinutes ~/ 60} hours';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumWidgetConfig &&
          runtimeType == other.runtimeType &&
          widgetId == other.widgetId &&
          albumId == other.albumId &&
          albumName == other.albumName &&
          intervalMinutes == other.intervalMinutes &&
          isRandom == other.isRandom &&
          currentIndex == other.currentIndex &&
          currentImagePath == other.currentImagePath &&
          totalImages == other.totalImages;

  @override
  int get hashCode => Object.hash(
        widgetId,
        albumId,
        albumName,
        intervalMinutes,
        isRandom,
        currentIndex,
        currentImagePath,
        totalImages,
      );
}
