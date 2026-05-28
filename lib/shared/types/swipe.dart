enum SwipeActionType { keep, delete }

class SwipeAction {
  const SwipeAction({
    required this.photoId,
    required this.action,
    required this.timestamp,
  });

  factory SwipeAction.fromJson(Map<String, Object?> json) => SwipeAction(
        photoId: json['photo_id'] as String,
        action: SwipeActionType.values.byName(json['action'] as String),
        timestamp: json['timestamp'] as int,
      );

  final String photoId;
  final SwipeActionType action;
  final int timestamp;

  Map<String, Object?> toJson() => {
        'photo_id': photoId,
        'action': action.name,
        'timestamp': timestamp,
      };

  @override
  String toString() =>
      'SwipeAction(photoId: $photoId, action: ${action.name}, timestamp: $timestamp)';
}
