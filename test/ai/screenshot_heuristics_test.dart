import 'package:background_remover/features/ai/ai_constants.dart';
import 'package:background_remover/utils/image_analysis/screenshot_heuristics.dart';
import 'package:flutter_test/flutter_test.dart';

List<List<int>> _uniformRows(int rows, int cols, int value) =>
    List.generate(rows, (_) => List.filled(cols, value));

List<List<int>> _variedRows(int rows, int cols) =>
    List.generate(rows, (r) => List.generate(cols, (c) => (r * cols + c) % 256));

// Matrix with a uniform top band and varied content elsewhere.
List<List<int>> _matrixWithUniformTop(int rows, int cols) {
  final m = _variedRows(rows, cols);
  final topRows = (rows * 0.05).floor().clamp(1, rows);
  for (var r = 0; r < topRows; r++) {
    m[r] = List.filled(cols, 180);
  }
  return m;
}

List<List<int>> _matrixWithUniformBottom(int rows, int cols) {
  final m = _variedRows(rows, cols);
  final botRows = (rows * 0.10).floor().clamp(1, rows);
  for (var r = rows - botRows; r < rows; r++) {
    m[r] = List.filled(cols, 30);
  }
  return m;
}

void main() {
  group('checkAspectRatio()', () {
    test('9:16 portrait → true', () => expect(checkAspectRatio(9, 16), isTrue));
    test('16:9 landscape → true', () => expect(checkAspectRatio(16, 9), isTrue));
    test('1:1 square → false', () => expect(checkAspectRatio(1, 1), isFalse));
    test('1:3 arbitrary → false', () => expect(checkAspectRatio(1, 3), isFalse));
    test('width or height 0 → false', () {
      expect(checkAspectRatio(0, 16), isFalse);
      expect(checkAspectRatio(9, 0), isFalse);
    });
    test('ratio within 5% tolerance → true', () {
      // 9:16 = 0.5625; 5% tolerance = ±0.028125
      expect(checkAspectRatio(900, 1590), isTrue); // ~0.566 ≈ 0.5625
    });
  });

  group('checkCommonResolution()', () {
    test('390x844 (iPhone 14) → true', () =>
        expect(checkCommonResolution(390, 844), isTrue));
    test('1080x2400 (Android) → true', () =>
        expect(checkCommonResolution(1080, 2400), isTrue));
    test('landscape flip 844x390 → true', () =>
        expect(checkCommonResolution(844, 390), isTrue));
    test('completely custom size 999x1234 → false', () =>
        expect(checkCommonResolution(999, 1234), isFalse));
    test('within ±10px tolerance → true', () =>
        expect(checkCommonResolution(393 + 10, 852 + 10), isTrue));
  });

  group('checkUIPatterns()', () {
    test('uniform top band → true', () {
      expect(checkUIPatterns(_matrixWithUniformTop(100, 50)), isTrue);
    });
    test('uniform bottom band → true', () {
      expect(checkUIPatterns(_matrixWithUniformBottom(100, 50)), isTrue);
    });
    test('varied pixels throughout → false', () {
      expect(checkUIPatterns(_variedRows(100, 50)), isFalse);
    });
    test('matrix with fewer than 20 rows → false', () {
      expect(checkUIPatterns(_uniformRows(10, 50, 200)), isFalse);
    });
  });

  group('scoreScreenshotLikelihood()', () {
    const t = ScreenshotSignals(
        matchesCommonAspectRatio: true,
        matchesCommonResolution: true,
        hasUIPatterns: true);
    const f = ScreenshotSignals(
        matchesCommonAspectRatio: false,
        matchesCommonResolution: false,
        hasUIPatterns: false);

    test('all signals true → score 1.0', () =>
        expect(scoreScreenshotLikelihood(t), closeTo(1.0, 1e-9)));
    test('all signals false → score 0.0', () =>
        expect(scoreScreenshotLikelihood(f), closeTo(0.0, 1e-9)));
    test('only aspect ratio true → score 0.35', () {
      const s = ScreenshotSignals(matchesCommonAspectRatio: true, matchesCommonResolution: false, hasUIPatterns: false);
      expect(scoreScreenshotLikelihood(s), closeTo(0.35, 1e-9));
    });
    test('only resolution true → score 0.45', () {
      const s = ScreenshotSignals(matchesCommonAspectRatio: false, matchesCommonResolution: true, hasUIPatterns: false);
      expect(scoreScreenshotLikelihood(s), closeTo(0.45, 1e-9));
    });
    test('only ui patterns true → score 0.20', () {
      const s = ScreenshotSignals(matchesCommonAspectRatio: false, matchesCommonResolution: false, hasUIPatterns: true);
      expect(scoreScreenshotLikelihood(s), closeTo(0.20, 1e-9));
    });
    test('aspect + resolution true → score 0.80', () {
      const s = ScreenshotSignals(matchesCommonAspectRatio: true, matchesCommonResolution: true, hasUIPatterns: false);
      expect(scoreScreenshotLikelihood(s), closeTo(0.80, 1e-9));
    });
  });

  group('isScreenshot()', () {
    test('score >= kScreenshotConfidenceThreshold → true', () =>
        expect(isScreenshot(kScreenshotConfidenceThreshold + 0.1), isTrue));
    test('score < kScreenshotConfidenceThreshold → false', () =>
        expect(isScreenshot(kScreenshotConfidenceThreshold - 0.1), isFalse));
    test('score exactly equal to threshold → true', () =>
        expect(isScreenshot(kScreenshotConfidenceThreshold), isTrue));
  });
}
