import '../../shared/models/photo_item.dart';
import '../../shared/models/swipe_action.dart';

class QueueService {
  /// Initializes the queue with a list of photo items.
  Future<void> initialize(List<PhotoItem> photos) async {
    // Stub implementation
  }

  /// Returns the next unseen photo or null if the queue is exhausted.
  Future<PhotoItem?> getNextPhoto() async {
    // Stub implementation
    return null;
  }

  /// Records a keep/delete decision for a photo, advancing the queue.
  Future<void> submitAction(SwipeAction action) async {
    // Stub implementation
  }

  /// Reverses and returns the last recorded swipe action.
  Future<SwipeAction?> undoLastAction() async {
    // Stub implementation
    return null;
  }

  /// Returns stats of the current queue (total, seen, remaining).
  Map<String, int> getQueue() {
    // Stub implementation
    return {
      'total': 0,
      'seen': 0,
      'remaining': 0,
    };
  }

  /// Persists the current queue state.
  Future<void> saveSession() async {
    // Stub implementation
  }
}
