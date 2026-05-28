import 'package:flutter/foundation.dart';

import '../../constants/gallery_constants.dart';
import '../../models/gallery_snapshot.dart';
import '../../models/photo_model.dart';
import '../../shared/types/result.dart';
import '../../utils/errors.dart';
import '../../utils/storage_formatters.dart';
import 'gallery_repository.dart';

class GalleryService {
  GalleryService({GalleryRepository? repository})
      : _repository = repository ?? GalleryRepository();

  final GalleryRepository _repository;

  Future<Result<GallerySnapshot, AppError>> loadGallery() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      final totalBytes = PhotoModel.mockPhotos.fold(
        0,
        (sum, photo) => sum + photo.fileSizeBytes,
      );
      return Result.success(
        GallerySnapshot(
          photos: PhotoModel.mockPhotos,
          aiPhotos: const [],
          totalPhotos: PhotoModel.mockPhotos.length,
          totalBytes: totalBytes,
          estimatedCleanupBytes: (totalBytes * kEstimatedCleanupRatio).round(),
        ),
      );
    }

    final result = await _repository.loadGallery();
    return result.when(
      onSuccess: (data) {
        final photos = data.photos
            .map(
              (photo) => PhotoModel(
                id: photo.id,
                uri: photo.uri,
                imageBytes: photo.thumbnailBytes,
                imageUrl: null,
                filename: photo.title,
                fileSize: formatStorageBytes(photo.sizeBytes),
                fileSizeBytes: photo.sizeBytes,
                createdAtMillis: photo.createdAt.millisecondsSinceEpoch,
                date: _formatDate(photo.createdAt),
              ),
            )
            .toList(growable: false);

        final estimatedCleanupBytes =
            (data.totalBytes * kEstimatedCleanupRatio).round();

        return Result.success(
          GallerySnapshot(
            photos: photos,
            aiPhotos: data.aiPhotos,
            totalPhotos: data.totalPhotos,
            totalBytes: data.totalBytes,
            estimatedCleanupBytes: estimatedCleanupBytes,
          ),
        );
      },
      onFailure: Result.failure,
    );
  }

  Stream<GalleryProgressData> streamGallery() {
    return _repository.streamGallery();
  }

  Future<Result<void, AppError>> deletePhoto(String assetId) {
    return _repository.deletePhoto(assetId);
  }

  Future<Result<List<String>, AppError>> deletePhotos(List<String> ids) {
    return _repository.deletePhotos(ids);
  }

  /// Loads all photos from the gallery and returns them as a list of
  /// [PhotoModel]. Returns a failure if the gallery cannot be accessed.
  Future<Result<List<PhotoModel>, AppError>> getPhotos() async {
    final result = await _repository.loadGallery();
    return result.when(
      onSuccess: (data) {
        final photos = data.photos
            .map(
              (photo) => PhotoModel(
                id: photo.id,
                uri: photo.uri,
                imageBytes: photo.thumbnailBytes,
                imageUrl: null,
                filename: photo.title,
                fileSize: formatStorageBytes(photo.sizeBytes),
                fileSizeBytes: photo.sizeBytes,
                createdAtMillis: photo.createdAt.millisecondsSinceEpoch,
                date: _formatDate(photo.createdAt),
              ),
            )
            .toList(growable: false);
        return Result.success(photos);
      },
      onFailure: Result.failure,
    );
  }

  /// Returns the first photo in [queue], or null if the queue is empty.
  PhotoModel? getNextPhoto(List<PhotoModel> queue) {
    return queue.isNotEmpty ? queue.first : null;
  }

  /// On Android, photos deleted from MediaStore cannot be restored.
  /// This method always returns a failure to communicate that limitation.
  Future<Result<void, AppError>> restorePhoto(String assetId) async {
    // Android does not support restoring deleted MediaStore assets.
    return Result.failure(const AppError(AppErrorType.deleteFailed));
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
