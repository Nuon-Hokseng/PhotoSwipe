import 'photo_item.dart';

class DeleteQueueItem {
  final PhotoItem photo;
  final int queuedAt;

  const DeleteQueueItem({required this.photo, required this.queuedAt});
}
