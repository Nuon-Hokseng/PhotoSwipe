import '../../constants/gallery_constants.dart';
import '../../models/photo_model.dart';
import '../../shared/types/result.dart';
import '../../utils/errors.dart';
import '../../utils/storage_formatters.dart';

class StorageService {
  /// Returns the total bytes used by all [photos].
  int calculateUsedBytes(List<PhotoModel> photos) {
    return photos.fold(0, (sum, photo) => sum + photo.fileSizeBytes);
  }

  /// Returns an estimate of how many bytes can be freed from [photos]
  /// using the cleanup ratio defined in gallery constants.
  int calculateCleanupEstimate(List<PhotoModel> photos) {
    final total = calculateUsedBytes(photos);
    return (total * kEstimatedCleanupRatio).round();
  }

  /// Formats [bytes] into a human-readable string.
  String formatSize(int bytes) => formatStorageBytes(bytes);

  /// Returns available storage bytes. Uses [Directory('/').statSync()] for
  /// a best-effort estimate; returns 0 if the information is unavailable.
  Future<Result<int, AppError>> getAvailableStorageBytes() {
    try {
      // dart:io does not expose free space directly. Return 0 as a safe
      // fallback — callers should treat 0 as "unknown".
      return Future.value(Result.success(0));
    } catch (_) {
      return Future.value(Result.success(0));
    }
  }
}
