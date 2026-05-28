class PhotoItem {
  final String id;
  final String uri;          // local file path on device
  final int size;            
  final int createdAt;     
  final int width;
  final int height;
  final String mimeType;     

  const PhotoItem({
    required this.id,
    required this.uri,
    required this.size,
    required this.createdAt, 
    required this.width,
    required this.height,
    required this.mimeType,
  });

  factory PhotoItem.fromJson(Map<String, dynamic> json) => PhotoItem(
        id: json['id'] as String,
        uri: json['uri'] as String,
        size: json['size'] as int,
        createdAt: json['createdAt'] as int,
        width: json['width'] as int,
        height: json['height'] as int,
        mimeType: json['mimeType'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'uri': uri,
        'size': size,
        'createdAt': createdAt,
        'width': width,
        'height': height,
        'mimeType': mimeType,
      };
}
