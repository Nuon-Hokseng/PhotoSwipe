class BinItem {
  const BinItem({
    required this.photoId,
    required this.uri,
    required this.filename,
    required this.fileSizeBytes,
    required this.addedAt,
    required this.expiresAt,
    required this.reason,
    required this.confidence,
  });

  factory BinItem.fromJson(Map<String, dynamic> json) => BinItem(
        photoId: json['photoId'] as String,
        uri: json['uri'] as String,
        filename: json['filename'] as String,
        fileSizeBytes: json['fileSizeBytes'] as int,
        addedAt: json['addedAt'] as int,
        expiresAt: json['expiresAt'] as int,
        reason: json['reason'] as String,
        confidence: (json['confidence'] as num).toDouble(),
      );

  /// The asset ID used by PhotoManager to identify the photo.
  final String photoId;

  /// File-system path to the image.
  final String uri;

  final String filename;
  final int fileSizeBytes;

  /// Milliseconds since epoch when this item was added to the bin.
  final int addedAt;

  /// Milliseconds since epoch when this item expires and will be purged.
  final int expiresAt;

  /// One of: 'blur' | 'screenshot' | 'both' | 'manual'
  final String reason;

  /// AI confidence score 0.0–1.0.
  final double confidence;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch >= expiresAt;

  int get daysRemaining {
    final diff = expiresAt - DateTime.now().millisecondsSinceEpoch;
    if (diff <= 0) return 0;
    return (diff / Duration.millisecondsPerDay).ceil();
  }

  Map<String, dynamic> toJson() => {
        'photoId': photoId,
        'uri': uri,
        'filename': filename,
        'fileSizeBytes': fileSizeBytes,
        'addedAt': addedAt,
        'expiresAt': expiresAt,
        'reason': reason,
        'confidence': confidence,
      };

  BinItem copyWith({
    String? photoId,
    String? uri,
    String? filename,
    int? fileSizeBytes,
    int? addedAt,
    int? expiresAt,
    String? reason,
    double? confidence,
  }) =>
      BinItem(
        photoId: photoId ?? this.photoId,
        uri: uri ?? this.uri,
        filename: filename ?? this.filename,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        addedAt: addedAt ?? this.addedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        reason: reason ?? this.reason,
        confidence: confidence ?? this.confidence,
      );
}
