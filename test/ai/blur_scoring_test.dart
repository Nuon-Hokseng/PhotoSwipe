import 'package:background_remover/features/ai/ai_constants.dart';
import 'package:background_remover/utils/image_analysis/blur_scoring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

List<List<int>> _uniformMatrix(int rows, int cols, int value) =>
    List.generate(rows, (_) => List.filled(cols, value));

List<List<int>> _checkerboardMatrix(int rows, int cols) => List.generate(
      rows,
      (r) => List.generate(cols, (c) => ((r + c) % 2 == 0) ? 255 : 0),
    );

img.Image _makeUniformImage(int w, int h, int gray) {
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      image.setPixelRgb(x, y, gray, gray, gray);
    }
  }
  return image;
}

void main() {
  group('toGrayscaleMatrix()', () {
    test('returns correct dimensions for a 10x10 image', () {
      final matrix = toGrayscaleMatrix(_makeUniformImage(10, 10, 128));
      expect(matrix.length, 10);
      expect(matrix[0].length, 10);
    });

    test('returns empty list for zero-dimension image', () {
      expect(toGrayscaleMatrix(img.Image(width: 0, height: 0)), isEmpty);
    });

    test('each value is in range 0–255', () {
      final matrix = toGrayscaleMatrix(_makeUniformImage(10, 10, 200));
      for (final row in matrix) {
        for (final v in row) {
          expect(v, inInclusiveRange(0, 255));
        }
      }
    });

    test('uniform white image → all values near 255', () {
      final matrix = toGrayscaleMatrix(_makeUniformImage(10, 10, 255));
      expect(matrix.expand((r) => r).every((v) => v >= 250), isTrue);
    });

    test('uniform black image → all values near 0', () {
      final matrix = toGrayscaleMatrix(_makeUniformImage(10, 10, 0));
      expect(matrix.expand((r) => r).every((v) => v <= 5), isTrue);
    });
  });

  group('applyLaplacianKernel()', () {
    test('returns same dimensions as input matrix', () {
      final m = _uniformMatrix(8, 8, 100);
      final result = applyLaplacianKernel(m);
      expect(result.length, 8);
      expect(result[0].length, 8);
    });

    test('border pixels are 0.0', () {
      final result = applyLaplacianKernel(_uniformMatrix(8, 8, 100));
      expect(result[0][0], 0.0);
      expect(result[0][7], 0.0);
      expect(result[7][0], 0.0);
      expect(result[7][7], 0.0);
    });

    test('uniform image → all interior values are 0.0', () {
      final result = applyLaplacianKernel(_uniformMatrix(8, 8, 100));
      for (var r = 1; r < 7; r++) {
        for (var c = 1; c < 7; c++) {
          expect(result[r][c], 0.0);
        }
      }
    });

    test('image with strong edge → high values at edge location', () {
      // Left half 0, right half 255
      final matrix = List.generate(8, (_) =>
          List.generate(8, (c) => c < 4 ? 0 : 255));
      final result = applyLaplacianKernel(matrix);
      final edgeValues = [result[1][3].abs(), result[2][3].abs(), result[3][3].abs()];
      expect(edgeValues.any((v) => v > 0), isTrue);
    });

    test('matrix smaller than 3x3 → returns all zeros', () {
      final result = applyLaplacianKernel(_uniformMatrix(2, 2, 128));
      expect(result.expand((r) => r).every((v) => v == 0.0), isTrue);
    });
  });

  group('computeVariance()', () {
    test('all-zero matrix → variance is 0.0', () {
      final convolved = List.generate(8, (_) => List.filled(8, 0.0));
      expect(computeVariance(convolved), 0.0);
    });

    test('uniform non-zero matrix → variance is 0.0', () {
      final convolved = List.generate(8, (_) => List.filled(8, 5.0));
      expect(computeVariance(convolved), 0.0);
    });

    test('mixed values → variance is positive', () {
      final convolved = applyLaplacianKernel(_checkerboardMatrix(10, 10));
      expect(computeVariance(convolved), greaterThan(0.0));
    });

    test('empty matrix → returns 0.0', () {
      expect(computeVariance([]), 0.0);
    });
  });

  group('normalizeBlurScore()', () {
    test('variance 0.0 → score 1.0 (maximum blur)', () {
      expect(normalizeBlurScore(0.0), closeTo(1.0, 1e-9));
    });

    test('variance >= kVarianceNormalizationFactor → score 0.0 (sharp)', () {
      expect(normalizeBlurScore(kVarianceNormalizationFactor), closeTo(0.0, 1e-9));
      expect(normalizeBlurScore(kVarianceNormalizationFactor * 2), closeTo(0.0, 1e-9));
    });

    test('variance 250.0 → score 0.5', () {
      expect(normalizeBlurScore(250.0), closeTo(0.5, 1e-9));
    });

    test('score is always clamped between 0.0 and 1.0', () {
      expect(normalizeBlurScore(-100.0), lessThanOrEqualTo(1.0));
      expect(normalizeBlurScore(9999.0), greaterThanOrEqualTo(0.0));
    });
  });

  group('computeBlurScoreFromMatrix()', () {
    test('sharp synthetic image (checkerboard) → score < kBlurThreshold', () {
      final score = computeBlurScoreFromMatrix(_checkerboardMatrix(50, 50));
      expect(score, lessThan(kBlurThreshold));
    });

    test('blurry synthetic image (uniform) → score > kBlurThreshold', () {
      final score = computeBlurScoreFromMatrix(_uniformMatrix(50, 50, 128));
      expect(score, greaterThan(kBlurThreshold));
    });
  });
}
