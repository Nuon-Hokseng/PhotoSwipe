import 'package:background_remover/features/ai/ai_constants.dart';
import 'package:background_remover/utils/image_analysis/hash_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

img.Image _makeUniformImage(int width, int height, int r, int g, int b) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return image;
}

img.Image _makeCheckerboardImage(int size) {
  final image = img.Image(width: size, height: size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final val = ((x + y) % 2 == 0) ? 255 : 0;
      image.setPixelRgb(x, y, val, val, val);
    }
  }
  return image;
}

void main() {
  group('computePerceptualHash()', () {
    test('returns a 16-character hex string', () {
      final hash = computePerceptualHash(_makeUniformImage(100, 100, 128, 128, 128));
      expect(hash.length, 16);
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(hash), isTrue);
    });

    test('same image bytes → same hash every time (deterministic)', () {
      final img1 = _makeCheckerboardImage(64);
      final img2 = _makeCheckerboardImage(64);
      expect(computePerceptualHash(img1), computePerceptualHash(img2));
    });

    test('very similar images → Hamming distance ≤ 5', () {
      final base = _makeUniformImage(100, 100, 200, 200, 200);
      final slight = _makeUniformImage(100, 100, 201, 201, 201);
      final dist = computeHammingDistance(
          computePerceptualHash(base), computePerceptualHash(slight));
      expect(dist, lessThanOrEqualTo(5));
    });

    test('completely different images → Hamming distance > 20', () {
      final white = _makeUniformImage(100, 100, 255, 255, 255);
      final checker = _makeCheckerboardImage(100);
      final dist = computeHammingDistance(
          computePerceptualHash(white), computePerceptualHash(checker));
      expect(dist, greaterThan(20));
    });
  });

  group('computeAverageHash()', () {
    test('returns a 16-character hex string', () {
      final hash = computeAverageHash(_makeUniformImage(100, 100, 128, 128, 128));
      expect(hash.length, 16);
      expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(hash), isTrue);
    });

    test('uniform white image → hash is ffffffffffffffff', () {
      final hash = computeAverageHash(_makeUniformImage(64, 64, 255, 255, 255));
      expect(hash, 'ffffffffffffffff');
    });

    // All-same-value images: every pixel equals the mean → p >= mean is always
    // true → all bits = 1. Both black and white uniform images hash identically.
    test('uniform black image → hash is ffffffffffffffff', () {
      final hash = computeAverageHash(_makeUniformImage(64, 64, 0, 0, 0));
      expect(hash, 'ffffffffffffffff');
    });
  });

  group('computeHammingDistance()', () {
    test('identical hashes → distance 0', () {
      expect(computeHammingDistance('abcdef0123456789', 'abcdef0123456789'), 0);
    });

    test('completely inverted hashes → distance 64', () {
      expect(computeHammingDistance('ffffffffffffffff', '0000000000000000'), 64);
    });

    test('one bit difference → distance 1', () {
      // f = 1111, e = 1110 → one bit difference
      expect(computeHammingDistance('f000000000000000', 'e000000000000000'), 1);
    });

    test('invalid hash length → throws ArgumentError', () {
      expect(() => computeHammingDistance('abc', 'abc'), throwsArgumentError);
    });

    test('invalid hex characters → throws ArgumentError', () {
      expect(
          () => computeHammingDistance('zzzzzzzzzzzzzzzz', 'ffffffffffffffff'),
          throwsArgumentError);
    });
  });

  group('computeSimilarity()', () {
    test('distance 0 → similarity 1.0', () {
      expect(computeSimilarity('aaaaaaaaaaaaaaaa', 'aaaaaaaaaaaaaaaa'), 1.0);
    });

    test('distance 64 → similarity 0.0', () {
      expect(computeSimilarity('ffffffffffffffff', '0000000000000000'), 0.0);
    });

    test('distance 32 → similarity 0.5', () {
      // ffffffff00000000 XOR 0000000000000000 = ffffffff00000000 → 32 bits set
      expect(
        computeSimilarity('ffffffff00000000', '0000000000000000'),
        closeTo(0.5, 1e-9),
      );
    });

    test('result is always clamped to [0.0, 1.0]', () {
      final sim = computeSimilarity('ffffffffffffffff', '0000000000000000');
      expect(sim, greaterThanOrEqualTo(0.0));
      expect(sim, lessThanOrEqualTo(1.0));
    });
  });

  group('areDuplicates()', () {
    test('similarity >= kDuplicateSimilarityThreshold → true', () {
      expect(areDuplicates(kDuplicateSimilarityThreshold), isTrue);
      expect(areDuplicates(1.0), isTrue);
    });

    test('similarity < kDuplicateSimilarityThreshold → false', () {
      expect(areDuplicates(kDuplicateSimilarityThreshold - 0.01), isFalse);
    });

    test('similarity exactly equal to threshold → true', () {
      expect(areDuplicates(kDuplicateSimilarityThreshold), isTrue);
    });
  });
}
