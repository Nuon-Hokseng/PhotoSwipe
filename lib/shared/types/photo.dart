class PhotoItem {
  const PhotoItem({
    required this.id,
    required this.uri,
    required this.size,
    required this.createdAt,
  });

  factory PhotoItem.fromJson(Map<String, Object?> json) => PhotoItem(
        id: json['id'] as String,
        uri: json['uri'] as String,
        size: json['size'] as int,
        createdAt: json['created_at'] as int,
      );

  final String id;
  final String uri;
  final int size;
  final int createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'uri': uri,
        'size': size,
        'created_at': createdAt,
      };

  PhotoItem copyWith({
    String? id,
    String? uri,
    int? size,
    int? createdAt,
  }) =>
      PhotoItem(
        id: id ?? this.id,
        uri: uri ?? this.uri,
        size: size ?? this.size,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() =>
      'PhotoItem(id: $id, uri: $uri, size: $size, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          uri == other.uri &&
          size == other.size &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, uri, size, createdAt);
}
