import 'package:background_remover/features/ai/ai_constants.dart';
import 'package:background_remover/features/ai/ai_types.dart';
import 'package:background_remover/features/ai/services/blur_detection_service.dart';
import 'package:background_remover/features/ai/services/duplicate_detection_service.dart';
import 'package:background_remover/features/ai/services/screenshot_detection_service.dart';
import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/services/logger/app_logger.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:background_remover/shared/types/result.dart';
import 'package:background_remover/utils/image_analysis/recommendation_scoring.dart';

class RecommendationSummary {
  const RecommendationSummary({
    required this.total,
    required this.blurCount,
    required this.duplicateCount,
    required this.screenshotCount,
    required this.estimatedPhotosToDelete,
    required this.estimatedStorageSaved,
  });

  static const empty = RecommendationSummary(
    total: 0, blurCount: 0, duplicateCount: 0, screenshotCount: 0,
    estimatedPhotosToDelete: 0, estimatedStorageSaved: 0,
  );

  final int total;
  final int blurCount;
  final int duplicateCount;
  final int screenshotCount;
  final int estimatedPhotosToDelete;
  final int estimatedStorageSaved;
}

class RecommendationService {
  RecommendationService({
    required BlurDetectionService blurService,
    required ScreenshotDetectionService screenshotService,
    required DuplicateDetectionService duplicateService,
  })  : _blur = blurService,
        _screenshot = screenshotService,
        _duplicate = duplicateService;

  final BlurDetectionService _blur;
  final ScreenshotDetectionService _screenshot;
  final DuplicateDetectionService _duplicate;
  static const _tag = 'RecommendationService';

  /// Runs all three AI analyses in parallel; tolerates partial failure.
  Future<Result<List<Recommendation>, AppError>> generateRecommendations(
    List<PhotoItem> photos,
  ) async {
    if (photos.isEmpty) return Result.success([]);
    final capped = photos.length > kMaxPhotosForRecommendation
        ? photos.sublist(0, kMaxPhotosForRecommendation)
        : photos;
    if (photos.length > kMaxPhotosForRecommendation) {
      AppLogger.warning(_tag,
          'Library too large (${photos.length}): processing first $kMaxPhotosForRecommendation');
    }
    try {
      // Tolerate partial failure — start all futures, catch errors individually.
      List<BlurResult> blurResults = [];
      List<ScreenshotResult> ssResults = [];
      Result<List<DuplicateGroup>, AppError> dupResult = Result.success([]);

      await Future.wait([
        _runBlurAnalysis(capped)
            .then((r) { blurResults = r; })
            .catchError((e) {
              AppLogger.error(_tag, 'Blur analysis failed: $e');
            }),
        _runScreenshotAnalysis(capped)
            .then((r) { ssResults = r; })
            .catchError((e) {
              AppLogger.error(_tag, 'Screenshot analysis failed: $e');
            }),
        _duplicate.detectDuplicate(capped).then((r) { dupResult = r; }),
      ], eagerError: false);

      final dupGroups = dupResult.isSuccess
          ? (dupResult as Success<List<DuplicateGroup>, AppError>).data
          : <DuplicateGroup>[];
      final raw = <RawCandidate>[
        ...blurResults.map(scoreBlurCandidate).whereType<RawCandidate>(),
        ...ssResults.map(scoreScreenshotCandidate).whereType<RawCandidate>(),
        ...dupGroups.map(scoreDuplicateCandidate).whereType<RawCandidate>(),
      ];
      final scored = raw.map(applyConfidenceWeights).toList();
      AppLogger.debug(_tag, '${raw.length} raw → ${scored.length} scored');
      return Result.success(buildRecommendationPipeline(scored));
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.recommendationFailed);
    }
  }

  /// Like [generateRecommendations] but boosts blur weight when deletion rate > 70%.
  Future<Result<List<Recommendation>, AppError>> generateRecommendationsFromStats(
    AnalyticsStats stats,
    List<PhotoItem> photos,
  ) async {
    final rate = stats.totalReviewed == 0
        ? 0.0
        : stats.totalDeleted / stats.totalReviewed;
    if (rate <= kHighDeletionRateThreshold) return generateRecommendations(photos);
    AppLogger.info(_tag, 'High deletion rate ($rate) — blur weight boosted');
    if (photos.isEmpty) return Result.success([]);
    final capped = photos.length > kMaxPhotosForRecommendation
        ? photos.sublist(0, kMaxPhotosForRecommendation)
        : photos;
    try {
      List<BlurResult> blurResults = [];
      List<ScreenshotResult> ssResults = [];
      Result<List<DuplicateGroup>, AppError> dupResult = Result.success([]);
      await Future.wait([
        _runBlurAnalysis(capped).then((r) { blurResults = r; })
            .catchError((e) { AppLogger.error(_tag, 'Blur failed: $e'); }),
        _runScreenshotAnalysis(capped).then((r) { ssResults = r; })
            .catchError((e) { AppLogger.error(_tag, 'SS failed: $e'); }),
        _duplicate.detectDuplicate(capped).then((r) { dupResult = r; }),
      ], eagerError: false);
      final dupGroups = dupResult.isSuccess
          ? (dupResult as Success<List<DuplicateGroup>, AppError>).data
          : <DuplicateGroup>[];
      final raw = <RawCandidate>[
        ...blurResults.map(scoreBlurCandidate).whereType<RawCandidate>(),
        ...ssResults.map(scoreScreenshotCandidate).whereType<RawCandidate>(),
        ...dupGroups.map(scoreDuplicateCandidate).whereType<RawCandidate>(),
      ];
      final boostedWeight =
          (kBlurConfidenceWeight + kBlurWeightBoost).clamp(0.0, 1.0);
      final scored = raw.map((c) {
        final w = c.type == RecommendationType.blur
            ? boostedWeight
            : switch (c.type) {
                RecommendationType.duplicate => kDuplicateConfidenceWeight,
                RecommendationType.screenshot => kScreenshotConfidenceWeight,
                _ => kClusterConfidenceWeight,
              };
        return ScoredCandidate(
            candidate: c, confidence: (c.rawScore * w).clamp(0.0, 1.0));
      }).toList();
      return Result.success(buildRecommendationPipeline(scored));
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.recommendationFailed);
    }
  }

  /// Builds a summary of the recommendation list.
  RecommendationSummary getRecommendationSummary(
      List<Recommendation> recommendations) {
    if (recommendations.isEmpty) return RecommendationSummary.empty;
    final allIds = recommendations.expand((r) => r.photoIds).toSet();
    return RecommendationSummary(
      total: recommendations.length,
      blurCount: recommendations
          .where((r) => r.type == RecommendationType.blur).length,
      duplicateCount: recommendations
          .where((r) => r.type == RecommendationType.duplicate).length,
      screenshotCount: recommendations
          .where((r) => r.type == RecommendationType.screenshot).length,
      estimatedPhotosToDelete: allIds.length,
      estimatedStorageSaved: 0,
    );
  }

  Future<List<BlurResult>> _runBlurAnalysis(List<PhotoItem> photos) async {
    final results = <BlurResult>[];
    await for (final r
        in _blur.detectBlurBatch(photos.map((p) => p.uri).toList())) {
      if (r.isSuccess) results.add((r as Success<BlurResult, AppError>).data);
    }
    return results;
  }

  Future<List<ScreenshotResult>> _runScreenshotAnalysis(
      List<PhotoItem> photos) async {
    final results = <ScreenshotResult>[];
    await for (final r in _screenshot
        .detectScreenshotBatch(photos.map((p) => p.uri).toList())) {
      if (r.isSuccess) {
        results.add((r as Success<ScreenshotResult, AppError>).data);
      }
    }
    return results;
  }
}
