import 'dart:io';

import 'package:background_remover/features/ai/ai_constants.dart';
import 'package:background_remover/features/ai/ai_types.dart';
import 'package:background_remover/services/logger/app_logger.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:background_remover/shared/types/result.dart';
import 'package:background_remover/utils/image_analysis/blur_scoring.dart';
import 'package:background_remover/utils/image_analysis/hash_utils.dart';
import 'package:background_remover/utils/image_analysis/similarity_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

// MUST be top-level — not a class method — for compute() to work.
List<String> _hashBatchIsolate(List<String> uris) => uris.map((uri) {
      try {
        return computePerceptualHash(
            decodeImageBytes(File(uri).readAsBytesSync()));
      } catch (_) {
        return '';
      }
    }).toList();

class DuplicateDetectionService {
  static const _tag = 'DuplicateDetectionService';
  static const _uuid = Uuid();

  /// Detects duplicate groups in [photos]. Returns [] when fewer than 2 photos.
  Future<Result<List<DuplicateGroup>, AppError>> detectDuplicate(
    List<PhotoItem> photos,
  ) async {
    if (photos.length < 2) return Result.success([]);
    try {
      final hashMap = await _computeHashesForAll(photos);
      // Step 1: exact duplicates via hash index (free — O(n))
      final index = buildHashIndex(hashMap);
      final allPairs = <SimilarPair>[];
      for (final group in index.values.where((g) => g.length >= 2)) {
        for (var i = 0; i < group.length; i++) {
          for (var j = i + 1; j < group.length; j++) {
            allPairs.add(SimilarPair(
                photoIdA: group[i],
                photoIdB: group[j],
                similarity: 1.0));
          }
        }
      }
      // Step 2: pairwise comparison in chunks of kMaxPairwiseComparisonBatch
      final ids = hashMap.keys.toList();
      for (var i = 0; i < ids.length; i += kMaxPairwiseComparisonBatch) {
        final chunk = ids.sublist(
            i, (i + kMaxPairwiseComparisonBatch).clamp(0, ids.length));
        final chunkMap = {for (final id in chunk) id: hashMap[id]!};
        allPairs.addAll(
            findSimilarPairs(chunkMap, kDuplicateSimilarityThreshold));
      }
      final clusters = groupIntoClusters(allPairs);
      return Result.success(_buildDuplicateGroups(clusters, photos, hashMap));
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.duplicateAnalysisFailed);
    }
  }

  /// Thin wrapper using the default similarity threshold.
  Future<Result<List<DuplicateGroup>, AppError>> getExactDuplicates(
    List<PhotoItem> photos,
  ) =>
      detectDuplicate(photos);

  /// Finds visually similar photos using a lower configurable [threshold].
  Future<Result<List<DuplicateGroup>, AppError>> getSimilarPhotos(
    List<PhotoItem> photos, {
    double threshold = 0.75,
  }) async {
    if (photos.length < 2) return Result.success([]);
    try {
      final hashMap = await _computeHashesForAll(photos);
      final allPairs = <SimilarPair>[];
      final ids = hashMap.keys.toList();
      for (var i = 0; i < ids.length; i += kMaxPairwiseComparisonBatch) {
        final chunk = ids.sublist(
            i, (i + kMaxPairwiseComparisonBatch).clamp(0, ids.length));
        final chunkMap = {for (final id in chunk) id: hashMap[id]!};
        allPairs.addAll(findSimilarPairs(chunkMap, threshold));
      }
      return Result.success(
          _buildDuplicateGroups(groupIntoClusters(allPairs), photos, hashMap));
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.duplicateAnalysisFailed);
    }
  }

  Future<Map<String, String>> _computeHashesForAll(
      List<PhotoItem> photos) async {
    final hashMap = <String, String>{};
    for (var i = 0; i < photos.length; i += kAiBatchSize) {
      final batch =
          photos.sublist(i, (i + kAiBatchSize).clamp(0, photos.length));
      final hashes =
          await compute(_hashBatchIsolate, batch.map((p) => p.uri).toList());
      for (var j = 0; j < batch.length; j++) {
        if (hashes[j].isNotEmpty) {
          hashMap[batch[j].id] = hashes[j];
        } else {
          AppLogger.warning(_tag, 'Hash failed for ${batch[j].uri} — skipped');
        }
      }
      await _yieldToMainThread();
    }
    return hashMap;
  }

  List<DuplicateGroup> _buildDuplicateGroups(
    List<List<String>> clusters,
    List<PhotoItem> photos,
    Map<String, String> hashMap,
  ) {
    final photoMap = {for (final p in photos) p.id: p};
    final groups = <DuplicateGroup>[];
    for (final cluster in clusters) {
      final members = cluster.where(photoMap.containsKey).toList();
      if (members.length < 2) continue;
      var simSum = 0.0;
      var pairCount = 0;
      for (var i = 0; i < members.length; i++) {
        for (var j = i + 1; j < members.length; j++) {
          final hA = hashMap[members[i]];
          final hB = hashMap[members[j]];
          if (hA != null && hB != null) {
            simSum += computeSimilarity(hA, hB);
            pairCount++;
          }
        }
      }
      groups.add(DuplicateGroup(
        groupId: _uuid.v4(),
        photos: members.map((id) => photoMap[id]!).toList(),
        similarity: pairCount > 0 ? simSum / pairCount : 1.0,
        recommendKeep: rankBestInGroup(members, photoMap),
      ));
    }
    groups.sort((a, b) => b.photos.length.compareTo(a.photos.length));
    return groups;
  }

  Future<void> _yieldToMainThread() => Future.delayed(Duration.zero);
}
