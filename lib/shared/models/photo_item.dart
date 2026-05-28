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

  Map<String, dynamic> toJson() => {
    'id': id, 'uri': uri, 'size': size,
    'createdAt': createdAt, 'width': width,
    'height': height, 'mimeType': mimeType,
  };

  factory PhotoItem.fromJson(Map<String, dynamic> json) => PhotoItem(
    id: json['id'], uri: json['uri'], size: json['size'],
    createdAt: json['createdAt'], width: json['width'],
    height: json['height'], mimeType: json['mimeType'],
  );
}
