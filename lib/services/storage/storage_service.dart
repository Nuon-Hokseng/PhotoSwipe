import '../../shared/models/delete_queue_item.dart';

class StorageService {
  /// Adds a photo to the temporary deletion queue.
  Future<void> addToDeleteQueue(String photoId) async {
    // Stub implementation
  }

  /// Removes a photo from the temporary deletion queue.
  Future<void> removeFromDeleteQueue(String photoId) async {
    // Stub implementation
  }

  /// Returns the current list of items queued for deletion.
  Future<List<DeleteQueueItem>> getDeleteQueue() async {
    // Stub implementation
    return [];
  }

  /// Calculates and returns a formatted string of storage space to be freed (e.g. "238 MB").
  Future<String> getStorageToFree() async {
    // Stub implementation
    return "0 B";
  }

  /// Executes permanent deletion of the queued items from device storage.
  /// Returns a map of successfully deleted and failed IDs.
  Future<Map<String, List<String>>> executeDeletion() async {
    // Stub implementation
    return {
      'deleted': [],
      'failed': [],
    };
  }

  /// Removes a photo from the delete queue (pre-deletion undo).
  Future<void> restorePhoto(String photoId) async {
    // Stub implementation
  }

  /// Cancels the deletion process.
  Future<void> cancelDeletion() async {
    // Stub implementation
  }
}
