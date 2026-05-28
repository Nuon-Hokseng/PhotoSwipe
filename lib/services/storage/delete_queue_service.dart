import '../../shared/models/delete_queue_item.dart';
import '../../shared/models/photo_item.dart';
import '../../shared/types/result.dart';
import '../../utils/errors.dart';
import '../gallery/gallery_repository.dart';

class DeleteQueueService {
  final List<DeleteQueueItem> _queue = [];

  List<DeleteQueueItem> get pending => List.unmodifiable(_queue);

  bool get isEmpty => _queue.isEmpty;

  int get count => _queue.length;

  /// Adds [photo] to the pending delete queue.
  void enqueue(PhotoItem photo) {
    _queue.add(
      DeleteQueueItem(
        photo: photo,
        queuedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Removes the entry with the given [photoId] from the queue (restore).
  void dequeue(String photoId) {
    _queue.removeWhere((item) => item.photo.id == photoId);
  }

  /// Flushes all queued deletes via [repo]. Returns the list of successfully
  /// deleted asset ids and clears the internal queue.
  Future<Result<List<String>, AppError>> flushDeletes(
    GalleryRepository repo,
  ) async {
    if (_queue.isEmpty) return Result.success([]);

    final ids = _queue.map((item) => item.photo.id).toList();
    final result = await repo.deletePhotos(ids);
    return result.when(
      onSuccess: (deletedIds) {
        _queue.clear();
        return Result.success(deletedIds);
      },
      onFailure: Result.failure,
    );
  }
}
