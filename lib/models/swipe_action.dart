enum SwipeActionType { keep, delete }

class SwipeActionRecord {
  const SwipeActionRecord({
    required this.photoId,
    required this.action,
    required this.timestamp,
    required this.photoSizeBytes,
  });

  final String photoId;
  final SwipeActionType action;
  final DateTime timestamp;
  final int photoSizeBytes;
}
