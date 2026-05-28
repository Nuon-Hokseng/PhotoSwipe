import 'package:background_remover/features/ai/ai_constants.dart';
import 'package:background_remover/features/ai/ai_types.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:background_remover/utils/image_analysis/recommendation_scoring.dart';
import 'package:flutter_test/flutter_test.dart';

BlurResult _makeBlurResult({
  String photoId = 'photo1',
  double blurScore = 0.8,
  bool isBlurry = true,
}) =>
    BlurResult(photoId: photoId, blurScore: blurScore, isBlurry: isBlurry);

ScreenshotResult _makeScreenshotResult({
  String photoId = 'photo1',
  double confidence = 0.85,
  bool isScreenshot = true,
}) =>
    ScreenshotResult(
        photoId: photoId, confidence: confidence, isScreenshot: isScreenshot);

DuplicateGroup _makeDuplicateGroup({
  String groupId = 'group1',
  double similarity = 0.95,
  String recommendKeep = 'photo1',
  List<PhotoItem>? photos,
}) =>
    DuplicateGroup(
      groupId: groupId,
      photos: photos ??
          [
            PhotoItem(id: 'photo1', uri: '/p1.jpg', size: 2000000, createdAt: 1000),
            PhotoItem(id: 'photo2', uri: '/p2.jpg', size: 1000000, createdAt: 900),
          ],
      similarity: similarity,
      recommendKeep: recommendKeep,
    );

ScoredCandidate _makeScoredCandidate({
  RecommendationType type = RecommendationType.blur,
  double confidence = 0.80,
}) {
  final c = RawCandidate(
    id: 'c1',
    type: type,
    photoIds: ['p1'],
    rawScore: confidence,
    reason: 'test',
    action: RecommendationAction.delete,
  );
  return ScoredCandidate(candidate: c, confidence: confidence);
}

void main() {
  group('scoreBlurCandidate()', () {
    test('returns null when isBlurry is false', () {
      expect(scoreBlurCandidate(_makeBlurResult(isBlurry: false)), isNull);
    });

    test('returns RawCandidate when isBlurry is true', () {
      expect(scoreBlurCandidate(_makeBlurResult()), isNotNull);
    });

    test('score > 0.80 → reason contains "Very blurry"', () {
      final c = scoreBlurCandidate(_makeBlurResult(blurScore: 0.85))!;
      expect(c.reason, contains('Very blurry'));
    });

    test('score > 0.60 → reason contains "Noticeably blurry"', () {
      final c = scoreBlurCandidate(_makeBlurResult(blurScore: 0.70))!;
      expect(c.reason, contains('Noticeably blurry'));
    });

    test('score just above threshold → reason contains "Slightly blurry"', () {
      final c = scoreBlurCandidate(_makeBlurResult(blurScore: 0.40))!;
      expect(c.reason, contains('Slightly blurry'));
    });

    test('type is RecommendationType.blur', () {
      expect(scoreBlurCandidate(_makeBlurResult())!.type, RecommendationType.blur);
    });

    test('action is RecommendationAction.delete', () {
      expect(scoreBlurCandidate(_makeBlurResult())!.action, RecommendationAction.delete);
    });

    test('photoIds contains exactly the result photoId', () {
      final c = scoreBlurCandidate(_makeBlurResult(photoId: 'px'))!;
      expect(c.photoIds, ['px']);
    });
  });

  group('scoreScreenshotCandidate()', () {
    test('returns null when isScreenshot is false', () {
      expect(scoreScreenshotCandidate(_makeScreenshotResult(isScreenshot: false)), isNull);
    });

    test('returns RawCandidate when isScreenshot is true', () {
      expect(scoreScreenshotCandidate(_makeScreenshotResult()), isNotNull);
    });

    test('confidence > 0.90 → reason contains "Almost certainly"', () {
      final c = scoreScreenshotCandidate(_makeScreenshotResult(confidence: 0.95))!;
      expect(c.reason, contains('Almost certainly'));
    });

    test('confidence above threshold → reason contains "Likely"', () {
      final c = scoreScreenshotCandidate(_makeScreenshotResult(confidence: 0.80))!;
      expect(c.reason, contains('Likely'));
    });

    test('type is RecommendationType.screenshot', () {
      expect(scoreScreenshotCandidate(_makeScreenshotResult())!.type,
          RecommendationType.screenshot);
    });
  });

  group('scoreDuplicateCandidate()', () {
    test('returns null when group has fewer than 2 photos', () {
      final group = _makeDuplicateGroup(
          photos: [PhotoItem(id: 'p1', uri: '/p1.jpg', size: 1, createdAt: 0)]);
      expect(scoreDuplicateCandidate(group), isNull);
    });

    test('similarity >= 0.99 → reason contains "Exact duplicate"', () {
      final c = scoreDuplicateCandidate(_makeDuplicateGroup(similarity: 0.99))!;
      expect(c.reason, contains('Exact duplicate'));
    });

    test('similarity >= 0.95 → reason contains "Near-identical"', () {
      final c = scoreDuplicateCandidate(_makeDuplicateGroup(similarity: 0.96))!;
      expect(c.reason, contains('Near-identical'));
    });

    test('photoIds excludes the recommendKeep photo', () {
      final c = scoreDuplicateCandidate(
          _makeDuplicateGroup(recommendKeep: 'photo1'))!;
      expect(c.photoIds, isNot(contains('photo1')));
    });

    test('photoIds includes all other photos in the group', () {
      final c = scoreDuplicateCandidate(
          _makeDuplicateGroup(recommendKeep: 'photo1'))!;
      expect(c.photoIds, contains('photo2'));
    });

    test('type is RecommendationType.duplicate', () {
      expect(scoreDuplicateCandidate(_makeDuplicateGroup())!.type,
          RecommendationType.duplicate);
    });
  });

  group('applyConfidenceWeights()', () {
    RawCandidate _raw(RecommendationType t, double score) => RawCandidate(
        id: 'x', type: t, photoIds: [], rawScore: score,
        reason: '', action: RecommendationAction.delete);

    test('duplicate weight = 1.00 → confidence equals rawScore', () {
      final s = applyConfidenceWeights(_raw(RecommendationType.duplicate, 0.90));
      expect(s.confidence, closeTo(0.90, 1e-9));
    });

    test('blur weight = 0.85 → confidence is rawScore * 0.85', () {
      final s = applyConfidenceWeights(_raw(RecommendationType.blur, 0.90));
      expect(s.confidence, closeTo(0.90 * kBlurConfidenceWeight, 1e-9));
    });

    test('screenshot weight = 0.90 → confidence is rawScore * 0.90', () {
      final s = applyConfidenceWeights(_raw(RecommendationType.screenshot, 0.90));
      expect(s.confidence, closeTo(0.90 * kScreenshotConfidenceWeight, 1e-9));
    });

    test('result is always clamped to [0.0, 1.0]', () {
      final s = applyConfidenceWeights(_raw(RecommendationType.duplicate, 2.0));
      expect(s.confidence, lessThanOrEqualTo(1.0));
    });
  });

  group('filterBelowMinConfidence()', () {
    test('removes candidates below kMinRecommendationConfidence', () {
      final low = _makeScoredCandidate(confidence: kMinRecommendationConfidence - 0.01);
      expect(filterBelowMinConfidence([low]), isEmpty);
    });

    test('keeps candidates at or above threshold', () {
      final ok = _makeScoredCandidate(confidence: kMinRecommendationConfidence);
      expect(filterBelowMinConfidence([ok]).length, 1);
    });

    test('empty list → empty list', () {
      expect(filterBelowMinConfidence([]), isEmpty);
    });
  });

  group('rankCandidates()', () {
    test('sorts by confidence descending', () {
      final a = _makeScoredCandidate(confidence: 0.70);
      final b = _makeScoredCandidate(confidence: 0.90);
      final ranked = rankCandidates([a, b]);
      expect(ranked.first.confidence, 0.90);
    });

    test('duplicate ranks above blur when confidence is equal', () {
      final blur = _makeScoredCandidate(type: RecommendationType.blur, confidence: 0.80);
      final dup = _makeScoredCandidate(type: RecommendationType.duplicate, confidence: 0.80);
      final ranked = rankCandidates([blur, dup]);
      expect(ranked.first.candidate.type, RecommendationType.duplicate);
    });

    test('screenshot ranks above blur when confidence is equal', () {
      final blur = _makeScoredCandidate(type: RecommendationType.blur, confidence: 0.80);
      final ss = _makeScoredCandidate(type: RecommendationType.screenshot, confidence: 0.80);
      final ranked = rankCandidates([blur, ss]);
      expect(ranked.first.candidate.type, RecommendationType.screenshot);
    });

    test('empty list → empty list', () {
      expect(rankCandidates([]), isEmpty);
    });
  });

  group('limitCandidates()', () {
    test('returns all when count <= kMaxRecommendations', () {
      final five = List.generate(5, (_) => _makeScoredCandidate());
      expect(limitCandidates(five).length, 5);
    });

    test('truncates to kMaxRecommendations when over limit', () {
      final over = List.generate(25, (_) => _makeScoredCandidate());
      expect(limitCandidates(over).length, kMaxRecommendations);
    });

    test('empty list → empty list', () {
      expect(limitCandidates([]), isEmpty);
    });
  });

  group('buildRecommendationPipeline()', () {
    test('empty input → empty list', () {
      expect(buildRecommendationPipeline([]), isEmpty);
    });

    test('candidates below threshold are excluded', () {
      final low = _makeScoredCandidate(confidence: kMinRecommendationConfidence - 0.01);
      expect(buildRecommendationPipeline([low]), isEmpty);
    });

    test('output is limited to kMaxRecommendations', () {
      final over = List.generate(25, (i) =>
          _makeScoredCandidate(confidence: 0.90));
      expect(buildRecommendationPipeline(over).length, kMaxRecommendations);
    });

    test('output is sorted by confidence descending', () {
      final recs = buildRecommendationPipeline([
        _makeScoredCandidate(confidence: 0.70),
        _makeScoredCandidate(confidence: 0.90),
        _makeScoredCandidate(confidence: 0.80),
      ]);
      for (var i = 0; i < recs.length - 1; i++) {
        expect(recs[i].confidence, greaterThanOrEqualTo(recs[i + 1].confidence));
      }
    });

    test('each output item is a valid Recommendation', () {
      final recs = buildRecommendationPipeline([_makeScoredCandidate(confidence: 0.90)]);
      expect(recs.first, isA<Recommendation>());
      expect(recs.first.confidence, closeTo(0.90, 1e-9));
    });
  });
}
