enum SwipeDecision { keep, delete }

class SwipeAction {
  final String photoId;
  final SwipeDecision action;
  final int timestamp; // when the swipe happened (milliseconds)

  const SwipeAction({
    required this.photoId,
    required this.action,
    required this.timestamp,
  });

  factory SwipeAction.fromJson(Map<String, dynamic> json) => SwipeAction(
        photoId: json['photoId'] as String,
        action: SwipeDecision.values.byName(json['action'] as String),
        timestamp: json['timestamp'] as int,
      );

  Map<String, dynamic> toJson() => {
        'photoId': photoId,
        'action': action.name,
        'timestamp': timestamp,
      };
}
