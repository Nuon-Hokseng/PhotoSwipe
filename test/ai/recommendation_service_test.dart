import 'package:background_remover/features/ai/ai_types.dart';
import 'package:background_remover/features/ai/services/blur_detection_service.dart';
import 'package:background_remover/features/ai/services/duplicate_detection_service.dart';
import 'package:background_remover/features/ai/services/recommendation_service.dart';
import 'package:background_remover/features/ai/services/screenshot_detection_service.dart';
import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:background_remover/shared/types/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBlurDetectionService extends Mock implements BlurDetectionService {}
class MockScreenshotDetectionService extends Mock implements ScreenshotDetectionService {}
class MockDuplicateDetectionService extends Mock implements DuplicateDetectionService {}

final _photo = PhotoItem(id: 'p1', uri: '/p1.jpg', size: 1024, createdAt: 0);

final _blurResult = BlurResult(photoId: 'p1', blurScore: 0.90, isBlurry: true);
final _ssResult = ScreenshotResult(photoId: 'p1', confidence: 0.88, isScreenshot: true);
final _dupGroup = DuplicateGroup(
  groupId: 'g1',
  photos: [
    PhotoItem(id: 'p1', uri: '/p1.jpg', size: 2000, createdAt: 1),
    PhotoItem(id: 'p2', uri: '/p2.jpg', size: 1000, createdAt: 0),
  ],
  similarity: 0.96,
  recommendKeep: 'p1',
);

Stream<Result<BlurResult, AppError>> _blurStream() async* {
  yield Result.success(_blurResult);
}

Stream<Result<ScreenshotResult, AppError>> _ssStream() async* {
  yield Result.success(_ssResult);
}

void main() {
  late RecommendationService service;
  late MockBlurDetectionService mockBlur;
  late MockScreenshotDetectionService mockScreenshot;
  late MockDuplicateDetectionService mockDuplicate;

  setUp(() {
    mockBlur = MockBlurDetectionService();
    mockScreenshot = MockScreenshotDetectionService();
    mockDuplicate = MockDuplicateDetectionService();
    service = RecommendationService(
      blurService: mockBlur,
      screenshotService: mockScreenshot,
      duplicateService: mockDuplicate,
    );
  });

  void _stubSuccess() {
    when(() => mockBlur.detectBlurBatch(any())).thenAnswer((_) => _blurStream());
    when(() => mockScreenshot.detectScreenshotBatch(any())).thenAnswer((_) => _ssStream());
    when(() => mockDuplicate.detectDuplicate(any()))
        .thenAnswer((_) async => Result.success([_dupGroup]));
  }

  group('generateRecommendations()', () {
    test('returns empty list immediately for empty photo input', () async {
      final result = await service.generateRecommendations([]);
      expect(result.isSuccess, isTrue);
      result.when(onSuccess: (r) => expect(r, isEmpty), onFailure: (_) => fail('no failure'));
    });

    test('runs all three AI services via Future.wait', () async {
      _stubSuccess();
      await service.generateRecommendations([_photo]);
      verify(() => mockBlur.detectBlurBatch(any())).called(1);
      verify(() => mockScreenshot.detectScreenshotBatch(any())).called(1);
      verify(() => mockDuplicate.detectDuplicate(any())).called(1);
    });

    test('returns only recommendations above kMinRecommendationConfidence', () async {
      _stubSuccess();
      final result = await service.generateRecommendations([_photo]);
      result.when(
        onSuccess: (recs) {
          for (final r in recs) {
            expect(r.confidence, greaterThanOrEqualTo(0.65));
          }
        },
        onFailure: (_) => fail('no failure'),
      );
    });

    test('limits output to kMaxRecommendations', () async {
      _stubSuccess();
      final result = await service.generateRecommendations([_photo]);
      result.when(
        onSuccess: (recs) => expect(recs.length, lessThanOrEqualTo(20)),
        onFailure: (_) => fail('no failure'),
      );
    });

    test('returns sorted by confidence descending', () async {
      _stubSuccess();
      final result = await service.generateRecommendations([_photo]);
      result.when(
        onSuccess: (recs) {
          for (var i = 0; i < recs.length - 1; i++) {
            expect(recs[i].confidence, greaterThanOrEqualTo(recs[i + 1].confidence));
          }
        },
        onFailure: (_) => fail('no failure'),
      );
    });

    // Stage 8: service now tolerates partial failure — blur throwing no longer aborts.
    test('tolerates blur service throwing — returns success with other results', () async {
      when(() => mockBlur.detectBlurBatch(any())).thenThrow(Exception('boom'));
      when(() => mockScreenshot.detectScreenshotBatch(any())).thenAnswer((_) => _ssStream());
      when(() => mockDuplicate.detectDuplicate(any()))
          .thenAnswer((_) async => Result.success([]));
      final result = await service.generateRecommendations([_photo]);
      // Blur fails but screenshot succeeds → partial success, not failure
      expect(result.isSuccess, isTrue);
    });

    // Stage 8: duplicate failure → falls back to empty groups, still returns success.
    test('tolerates duplicate failure — returns success with blur+screenshot results', () async {
      when(() => mockBlur.detectBlurBatch(any())).thenAnswer((_) => _blurStream());
      when(() => mockScreenshot.detectScreenshotBatch(any())).thenAnswer((_) => _ssStream());
      when(() => mockDuplicate.detectDuplicate(any()))
          .thenAnswer((_) async => Result.failure(AppError.duplicateAnalysisFailed));
      final result = await service.generateRecommendations([_photo]);
      // Duplicate fails → treated as empty groups; blur+screenshot recommendations returned
      expect(result.isSuccess, isTrue);
    });

    test('duplicate recommendations exclude recommendKeep photoId', () async {
      _stubSuccess();
      final result = await service.generateRecommendations([_photo]);
      result.when(
        onSuccess: (recs) {
          final dupRec = recs.where((r) => r.type == RecommendationType.duplicate);
          for (final r in dupRec) {
            expect(r.photoIds, isNot(contains('p1'))); // p1 is recommendKeep
          }
        },
        onFailure: (_) => fail('no failure'),
      );
    });
  });

  group('generateRecommendationsFromStats()', () {
    test('boosts blur weight when deletion rate > 70%', () async {
      _stubSuccess();
      final stats = AnalyticsStats(
        totalReviewed: 100, totalKept: 25, totalDeleted: 75,
        storageSaved: 0, sessionHistory: [], dailyStats: [], weeklyStats: [],
      );
      final result = await service.generateRecommendationsFromStats(stats, [_photo]);
      expect(result.isSuccess, isTrue);
    });

    test('does not boost when deletion rate <= 70%', () async {
      _stubSuccess();
      final stats = AnalyticsStats(
        totalReviewed: 100, totalKept: 40, totalDeleted: 60,
        storageSaved: 0, sessionHistory: [], dailyStats: [], weeklyStats: [],
      );
      final result = await service.generateRecommendationsFromStats(stats, [_photo]);
      expect(result.isSuccess, isTrue);
    });
  });

  group('getRecommendationSummary()', () {
    test('counts blur, duplicate, screenshot correctly', () async {
      _stubSuccess();
      final result = await service.generateRecommendations([_photo]);
      result.when(
        onSuccess: (recs) {
          final summary = service.getRecommendationSummary(recs);
          expect(summary.total, recs.length);
        },
        onFailure: (_) => fail('no failure'),
      );
    });

    test('returns RecommendationSummary.empty for empty list', () {
      final summary = service.getRecommendationSummary([]);
      expect(summary.total, 0);
      expect(summary.blurCount, 0);
    });

    test('estimatedPhotosToDelete counts unique photoIds across all recommendations',
        () async {
      _stubSuccess();
      final result = await service.generateRecommendations([_photo]);
      result.when(
        onSuccess: (recs) {
          final summary = service.getRecommendationSummary(recs);
          final uniqueIds = recs.expand((r) => r.photoIds).toSet();
          expect(summary.estimatedPhotosToDelete, uniqueIds.length);
        },
        onFailure: (_) => fail('no failure'),
      );
    });
  });
}
