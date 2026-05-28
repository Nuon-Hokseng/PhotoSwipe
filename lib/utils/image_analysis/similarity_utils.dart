import 'package:background_remover/services/logger/app_logger.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:background_remover/utils/image_analysis/clustering_utils.dart';
import 'package:background_remover/utils/image_analysis/hash_utils.dart';

class SimilarPair {
  const SimilarPair({
    required this.photoIdA,
    required this.photoIdB,
    required this.similarity,
  });

  final String photoIdA;
  final String photoIdB;
  final double similarity;
}

/// Builds an inverted index { hashString → [photoId, ...] } for exact-match fast-lookup.
Map<String, List<String>> buildHashIndex(Map<String, String> photoHashMap) {
  final index = <String, List<String>>{};
  for (final entry in photoHashMap.entries) {
    index.putIfAbsent(entry.value, () => []).add(entry.key);
  }
  return index;
}

// O(n²) — only call on pre-filtered batches of ≤500 photos.
/// Compares every photo pair and returns pairs whose similarity >= [threshold].
List<SimilarPair> findSimilarPairs(
  Map<String, String> photoHashMap,
  double threshold,
) {
  final ids = photoHashMap.keys.toList();
  if (ids.length < 2) return [];
  final pairs = <SimilarPair>[];
  for (var i = 0; i < ids.length; i++) {
    for (var j = i + 1; j < ids.length; j++) {
      final sim =
          computeSimilarity(photoHashMap[ids[i]]!, photoHashMap[ids[j]]!);
      if (sim >= threshold) {
        pairs.add(SimilarPair(photoIdA: ids[i], photoIdB: ids[j], similarity: sim));
      }
    }
  }
  pairs.sort((a, b) => b.similarity.compareTo(a.similarity));
  return pairs;
}

/// Groups transitively connected [SimilarPair]s into clusters using Union-Find.
List<List<String>> groupIntoClusters(List<SimilarPair> pairs) {
  if (pairs.isEmpty) return [];
  final allIds = <String>{};
  for (final p in pairs) {
    allIds.add(p.photoIdA);
    allIds.add(p.photoIdB);
  }
  final uf = UnionFind(allIds.toList());
  for (final p in pairs) {
    uf.union(p.photoIdA, p.photoIdB);
  }
  return uf.getGroups().values.toList();
}

/// Returns the photoId of the best photo to keep in [cluster].
/// Priority: largest [PhotoItem.size], then most recent [PhotoItem.createdAt].
String rankBestInGroup(List<String> cluster, Map<String, PhotoItem> photoMap) {
  if (cluster.isEmpty) throw ArgumentError('Cluster must not be empty');
  PhotoItem? best;
  String bestId = cluster.first;
  for (final id in cluster) {
    final photo = photoMap[id];
    if (photo == null) {
      AppLogger.warning('rankBestInGroup', 'photoId $id not found in photoMap — skipped');
      continue;
    }
    if (best == null ||
        photo.size > best.size ||
        (photo.size == best.size && photo.createdAt > best.createdAt)) {
      best = photo;
      bestId = id;
    }
  }
  return bestId;
}
