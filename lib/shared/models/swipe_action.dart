class SwipeAction {
  final String photoId;
  final String action;   // 'keep' or 'delete'
  final int timestamp;

  const SwipeAction({
    required this.photoId,
    required this.action,
    required this.timestamp,
  });
}
