import '../shared/types/photo.dart';
import 'photo_model.dart';

class GallerySnapshot {
  const GallerySnapshot({
    required this.photos,
    required this.aiPhotos,
    required this.totalPhotos,
    required this.totalBytes,
    required this.estimatedCleanupBytes,
  });

  final List<PhotoModel> photos;
  final List<PhotoItem> aiPhotos;
  final int totalPhotos;
  final int totalBytes;
  final int estimatedCleanupBytes;
}
