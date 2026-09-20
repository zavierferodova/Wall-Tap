import 'dart:convert';

class WallpaperItem {
  final String id;
  final String path;
  final String fileName;
  final int width;
  final int height;
  final int fileSize;
  final bool isEnabled;
  final DateTime dateAdded;

  const WallpaperItem({
    required this.id,
    required this.path,
    required this.fileName,
    required this.width,
    required this.height,
    required this.fileSize,
    this.isEnabled = true,
    required this.dateAdded,
  });

  String get resolutionText {
    if (width <= 0 || height <= 0) return 'Original';
    return '${width}x$height';
  }

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  WallpaperItem copyWith({
    String? id,
    String? path,
    String? fileName,
    int? width,
    int? height,
    int? fileSize,
    bool? isEnabled,
    DateTime? dateAdded,
  }) {
    return WallpaperItem(
      id: id ?? this.id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      isEnabled: isEnabled ?? this.isEnabled,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'fileName': fileName,
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'isEnabled': isEnabled,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
    };
  }

  factory WallpaperItem.fromMap(Map<String, dynamic> map) {
    return WallpaperItem(
      id: map['id'] as String? ?? '',
      path: map['path'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      fileSize: (map['fileSize'] as num?)?.toInt() ?? 0,
      isEnabled: map['isEnabled'] as bool? ?? true,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(
        (map['dateAdded'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory WallpaperItem.fromJson(String source) =>
      WallpaperItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
