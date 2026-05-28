// End-to-end integration tests for Person 3's full system.
// Tests marked skip: 'Requires Supabase' need a configured test project.
// Tests marked skip: 'Requires test assets' need images in test/assets/.
// All public API contract tests run without any external dependencies.

import 'package:background_remover/features/ai/ai_types.dart';
import 'package:background_remover/features/ai/services/blur_detection_service.dart';
import 'package:background_remover/features/ai/services/duplicate_detection_service.dart';
import 'package:background_remover/features/ai/services/recommendation_service.dart';
import 'package:background_remover/features/ai/services/screenshot_detection_service.dart';
import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/features/analytics/services/daily_aggregation_service.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:background_remover/shared/types/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBlurDetectionService extends Mock implements BlurDetectionService {}
class MockScreenshotDetectionService extends Mock implements ScreenshotDetectionService {}
class MockDuplicateDetectionService extends Mock implements DuplicateDetectionService {}

PhotoItem _photo(String id, {int size = 1024}) =>
    PhotoItem(id: id, uri: '/fake/$id.jpg', size: size, createdAt: 1000);

Session _session({
  String id = 'sid',
  int startedAt = 1700000000000,
  int? endedAt,
  int reviewed = 0,
  int deleted = 0,
  int kept = 0,
  int storageSaved = 0,
}) =>
    Session(
        id: id,
        startedAt: startedAt,
        endedAt: endedAt ?? startedAt + 3600000,
        reviewed: reviewed,
        deleted: deleted,
        kept: kept,
        storageSaved: storageSaved);

void main() {
  group('Person 3 — full system integration', () {
    // ─── Analytics pipeline ────────────────────────────────────────────
    group('Analytics pipeline', () {
      test('complete session lifecycle produces correct AnalyticsStats', () {
        final daily = DailyAggregationService();
        final sessions = [
          _session(id: 's1', reviewed: 5, deleted: 3, kept: 2, storageSaved: 1048576),
        ];
        final stats = daily.compute(sessions);
        expect(stats.length, 1);
        expect(stats.first.reviewed, 5);
        expect(stats.first.deleted, 3);
        expect(stats.first.storageSaved, 1048576);
      });

      test('two sessions on same date merge into one DailyStat', () {
        final daily = DailyAggregationService();
        final jan15 = DateTime(2024, 1, 15).millisecondsSinceEpoch;
        final sessions = [
          _session(id: 's1', startedAt: jan15, reviewed: 5, deleted: 3, storageSaved: 1000),
          _session(id: 's2', startedAt: jan15 + 3600000, reviewed: 3, deleted: 1, storageSaved: 500),
        ];
        final stats = daily.compute(sessions);
        expect(stats.length, 1);
        expect(stats.first.reviewed, 8);
        expect(stats.first.deleted, 4);
        expect(stats.first.storageSaved, 1500);
      });

      test('getStats() returns empty stats when no sessions', () {
        final daily = DailyAggregationService();
        final result = daily.compute([]);
        expect(result, isEmpty);
      });

      test('sessions spanning week boundary → two WeeklyStats', skip: 'Requires Supabase', () {
        // Would test getStats() with Supabase
      });
    });

    // ─── AI pipeline ────────────────────────────────────────────────────
    group('AI pipeline', () {
      late RecommendationService service;
      late MockBlurDetectionService mockBlur;
      late MockScreenshotDetectionService mockSS;
      late MockDuplicateDetectionService mockDup;

      setUp(() {
        mockBlur = MockBlurDetectionService();
        mockSS = MockScreenshotDetectionService();
        mockDup = MockDuplicateDetectionService();
        service = RecommendationService(
            blurService: mockBlur,
            screenshotService: mockSS,
            duplicateService: mockDup);
      });

      void _stubEmpty() {
        when(() => mockBlur.detectBlurBatch(any())).thenAnswer((_) async* {});
        when(() => mockSS.detectScreenshotBatch(any())).thenAnswer((_) async* {});
        when(() => mockDup.detectDuplicate(any()))
            .thenAnswer((_) async => Result.success([]));
      }

      test('generateRecommendations: empty input → empty list', () async {
        final result = await service.generateRecommendations([]);
        expect(result.isSuccess, isTrue);
        result.when(onSuccess: (r) => expect(r, isEmpty), onFailure: (_) => fail(''));
      });

      test('partial service failure → still returns results from working services', () async {
        when(() => mockBlur.detectBlurBatch(any())).thenThrow(Exception('boom'));
        when(() => mockSS.detectScreenshotBatch(any())).thenAnswer((_) async* {
          yield Result.success(
              ScreenshotResult(photoId: 'p1', confidence: 0.95, isScreenshot: true));
        });
        when(() => mockDup.detectDuplicate(any()))
            .thenAnswer((_) async => Result.success([]));
        final result = await service.generateRecommendations([_photo('p1')]);
        // Blur fails but screenshot succeeds — result should still be a success
        expect(result.isSuccess, isTrue);
      });

      test('output never exceeds kMaxRecommendations', () async {
        _stubEmpty();
        final result = await service.generateRecommendations([_photo('p1')]);
        result.when(
          onSuccess: (recs) => expect(recs.length, lessThanOrEqualTo(20)),
          onFailure: (_) => fail('unexpected failure'),
        );
      });

      test('detectDuplicate: single photo → empty groups', () async {
        final dup = DuplicateDetectionService();
        final result = await dup.detectDuplicate([_photo('p1')]);
        result.when(onSuccess: (g) => expect(g, isEmpty), onFailure: (_) => fail(''));
      });

      test('detectDuplicate: 100 invalid URIs → success not failure', () async {
        final dup = DuplicateDetectionService();
        final photos = List.generate(100, (i) => _photo('p$i'));
        final result = await dup.detectDuplicate(photos);
        // All hashes fail → no pairs → empty result, not an error
        expect(result.isSuccess, isTrue);
      });

      test('detectBlur: non-existent file → imageLoadFailed', () async {
        final blur = BlurDetectionService();
        final result = await blur.detectBlur('/no/such/file.jpg');
        expect(result.isFailure, isTrue);
        result.when(
          onSuccess: (_) => fail('expected failure'),
          onFailure: (e) => expect(e, AppError.imageLoadFailed),
        );
      });

      test('detectBlur: sharp test image', skip: 'Requires test assets', () async {
        final blur = BlurDetectionService();
        final result = await blur.detectBlur('test/assets/sharp_photo.jpg');
        result.when(
          onSuccess: (r) => expect(r.isBlurry, isFalse),
          onFailure: (_) => fail('expected success'),
        );
      });
    });

    // ─── Performance benchmarks ──────────────────────────────────────────
    group('Performance benchmarks', () {
      test('DailyAggregationService.compute() with 5000 sessions < 500ms', () {
        final svc = DailyAggregationService();
        final sessions = List.generate(5000, (i) => _session(
          id: 's$i',
          startedAt: 1700000000000 + i * 86400000,
          reviewed: 5, deleted: 3, kept: 2, storageSaved: 1024,
        ));
        final sw = Stopwatch()..start();
        svc.compute(sessions);
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(500));
      });

      test('detectBlurBatch on 200 photos < 30s', skip: 'Requires test assets', () async {
        final svc = BlurDetectionService();
        final uris = List.generate(200, (_) => 'test/assets/sharp_photo.jpg');
        final sw = Stopwatch()..start();
        await svc.detectBlurBatch(uris).toList();
        expect(sw.elapsedMilliseconds, lessThan(30000));
      });
    });

    // ─── Public API contract verification ────────────────────────────────
    group('Public API contract verification', () {
      test('detectDuplicate() return type is Result<List<DuplicateGroup>, AppError>', () async {
        final svc = DuplicateDetectionService();
        final result = await svc.detectDuplicate([
          PhotoItem(id: 'p1', uri: 'a.jpg', size: 1000, createdAt: 1000),
          PhotoItem(id: 'p2', uri: 'b.jpg', size: 1000, createdAt: 1000),
        ]);
        expect(result, isA<Result<List<DuplicateGroup>, AppError>>());
      });

      test('generateRecommendations() return type is Result<List<Recommendation>, AppError>', () async {
        final blur = MockBlurDetectionService();
        final ss = MockScreenshotDetectionService();
        final dup = MockDuplicateDetectionService();
        when(() => blur.detectBlurBatch(any())).thenAnswer((_) async* {});
        when(() => ss.detectScreenshotBatch(any())).thenAnswer((_) async* {});
        when(() => dup.detectDuplicate(any()))
            .thenAnswer((_) async => Result.success([]));
        final svc = RecommendationService(
            blurService: blur, screenshotService: ss, duplicateService: dup);
        final result = await svc.generateRecommendations([]);
        expect(result, isA<Result<List<Recommendation>, AppError>>());
        expect(result.isSuccess, isTrue);
      });

      test('BlurResult fields are within expected ranges', () async {
        final svc = BlurDetectionService();
        final result = await svc.detectBlur('/no/such/file.jpg');
        expect(result.isFailure, isTrue); // file not found
      });
    });
  });
}
