import 'dart:math';

import '../../models/photo_model.dart';

class QueueService {
  /// Shuffles [photos] using [seed]. If [seed] is null or 0, uses
  /// DateTime.now().millisecondsSinceEpoch as the seed.
  List<PhotoModel> shuffle(List<PhotoModel> photos, {int? seed}) {
    final effectiveSeed =
        (seed == null || seed == 0) ? DateTime.now().millisecondsSinceEpoch : seed;
    final result = List<PhotoModel>.from(photos);
    result.shuffle(Random(effectiveSeed));
    return result;
  }

  /// Removes duplicate photos by id, preserving first occurrence.
  List<PhotoModel> deduplicate(List<PhotoModel> photos) {
    final seen = <String>{};
    final result = <PhotoModel>[];
    for (final photo in photos) {
      if (seen.add(photo.id)) {
        result.add(photo);
      }
    }
    return result;
  }

  /// Splits [photos] into chunks of at most [size] elements.
  List<List<PhotoModel>> chunk(List<PhotoModel> photos, int size) {
    if (size <= 0) return [List<PhotoModel>.from(photos)];
    final result = <List<PhotoModel>>[];
    for (var i = 0; i < photos.length; i += size) {
      result.add(
        photos.sublist(i, i + size > photos.length ? photos.length : i + size),
      );
    }
    return result;
  }
}
