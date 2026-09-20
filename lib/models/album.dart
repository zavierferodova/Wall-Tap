import 'dart:convert';

class Album {
  final String id;
  final String name;
  final List<String> wallpaperIds;
  final DateTime dateCreated;
  final String? coverPath;

  const Album({
    required this.id,
    required this.name,
    this.wallpaperIds = const [],
    required this.dateCreated,
    this.coverPath,
  });

  int get count => wallpaperIds.length;

  Album copyWith({
    String? id,
    String? name,
    List<String>? wallpaperIds,
    DateTime? dateCreated,
    String? coverPath,
    bool clearCoverPath = false,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      wallpaperIds: wallpaperIds ?? List.unmodifiable(this.wallpaperIds),
      dateCreated: dateCreated ?? this.dateCreated,
      coverPath: clearCoverPath ? null : (coverPath ?? this.coverPath),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'wallpaperIds': wallpaperIds,
      'dateCreated': dateCreated.millisecondsSinceEpoch,
      'coverPath': coverPath,
    };
  }

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      wallpaperIds: (map['wallpaperIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      dateCreated: DateTime.fromMillisecondsSinceEpoch(
        (map['dateCreated'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      coverPath: map['coverPath'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Album.fromJson(String source) =>
      Album.fromMap(json.decode(source) as Map<String, dynamic>);
}
