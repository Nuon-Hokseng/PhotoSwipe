import 'package:background_remover/features/ai/ai_constants.dart';
import 'package:background_remover/features/ai/ai_types.dart';

class RawCandidate {
  const RawCandidate({
    required this.id,
    required this.type,
    required this.photoIds,
    required this.rawScore,
    required this.reason,
    required this.action,
  });

  final String id;
  final RecommendationType type;
  final List<String> photoIds;
  final double rawScore;
  final String reason;
  final RecommendationAction action;
}

class ScoredCandidate {
  const ScoredCandidate({required this.candidate, required this.confidence});
  final RawCandidate candidate;
  final double confidence;
}

/// Returns null if the photo is not blurry; otherwise builds a blur candidate.
RawCandidate? scoreBlurCandidate(BlurResult result) {
  if (!result.isBlurry) return null;
  final s = result.blurScore;
  final reason = s > 0.80
      ? 'Very blurry photo — unlikely to be useful'
      : s > 0.60
          ? 'Noticeably blurry — consider deleting'
          : 'Slightly blurry photo';
  return RawCandidate(
    id: '${result.photoId}_blur',
    type: RecommendationType.blur,
    photoIds: [result.photoId],
    rawScore: s,
    reason: reason,
    action: RecommendationAction.delete,
  );
}

/// Returns null if the photo is not a screenshot; otherwise builds a screenshot candidate.
RawCandidate? scoreScreenshotCandidate(ScreenshotResult result) {
  if (!result.isScreenshot) return null;
  final c = result.confidence;
  final reason = c > 0.90
      ? 'Almost certainly a screenshot — safe to delete'
      : 'Likely a screenshot';
  return RawCandidate(
    id: '${result.photoId}_screenshot',
    type: RecommendationType.screenshot,
    photoIds: [result.photoId],
    rawScore: c,
    reason: reason,
    action: RecommendationAction.delete,
  );
}

/// Returns null when group has fewer than 2 photos; photoIds excludes recommendKeep.
RawCandidate? scoreDuplicateCandidate(DuplicateGroup group) {
  if (group.photos.length < 2) return null;
  final s = group.similarity;
  final reason = s >= 0.99
      ? 'Exact duplicate — keep the best copy'
      : s >= 0.95
          ? 'Near-identical photos — keep the best copy'
          : 'Very similar photos (${group.photos.length} copies found)';
  return RawCandidate(
    id: '${group.groupId}_duplicate',
    type: RecommendationType.duplicate,
    photoIds: group.photos
        .map((p) => p.id)
        .where((id) => id != group.recommendKeep)
        .toList(),
    rawScore: s,
    reason: reason,
    action: RecommendationAction.delete,
  );
}

/// Multiplies rawScore by a type-specific weight from ai_constants.dart.
ScoredCandidate applyConfidenceWeights(RawCandidate candidate) {
  final weight = switch (candidate.type) {
    RecommendationType.blur => kBlurConfidenceWeight,
    RecommendationType.duplicate => kDuplicateConfidenceWeight,
    RecommendationType.screenshot => kScreenshotConfidenceWeight,
    RecommendationType.cluster => kClusterConfidenceWeight,
  };
  return ScoredCandidate(
    candidate: candidate,
    confidence: (candidate.rawScore * weight).clamp(0.0, 1.0),
  );
}

/// Removes candidates whose confidence is below [kMinRecommendationConfidence].
List<ScoredCandidate> filterBelowMinConfidence(
        List<ScoredCandidate> candidates) =>
    candidates.where((c) => c.confidence >= kMinRecommendationConfidence).toList();

const _typePriority = {
  RecommendationType.duplicate: 3,
  RecommendationType.screenshot: 2,
  RecommendationType.blur: 1,
  RecommendationType.cluster: 0,
};

/// Sorts by confidence descending; tie-breaks by type priority (duplicate > screenshot > blur > cluster).
List<ScoredCandidate> rankCandidates(List<ScoredCandidate> candidates) =>
    List<ScoredCandidate>.from(candidates)
      ..sort((a, b) {
        final cmp = b.confidence.compareTo(a.confidence);
        if (cmp != 0) return cmp;
        return (_typePriority[b.candidate.type] ?? 0)
            .compareTo(_typePriority[a.candidate.type] ?? 0);
      });

/// Caps the list at [kMaxRecommendations].
List<ScoredCandidate> limitCandidates(List<ScoredCandidate> candidates) =>
    candidates.length <= kMaxRecommendations
        ? candidates
        : candidates.sublist(0, kMaxRecommendations);

/// Maps a [ScoredCandidate] to the shared [Recommendation] type.
Recommendation toRecommendation(ScoredCandidate scored) => Recommendation(
      id: scored.candidate.id,
      type: scored.candidate.type,
      photoIds: scored.candidate.photoIds,
      reason: scored.candidate.reason,
      confidence: scored.confidence,
      action: scored.candidate.action,
    );

/// Full pipeline: filter → rank → limit → map to Recommendation.
List<Recommendation> buildRecommendationPipeline(
    List<ScoredCandidate> candidates) {
  if (candidates.isEmpty) return [];
  return limitCandidates(rankCandidates(filterBelowMinConfidence(candidates)))
      .map(toRecommendation)
      .toList();
}
