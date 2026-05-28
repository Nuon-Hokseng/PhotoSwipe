import 'package:background_remover/features/ai/ai_constants.dart';
import 'package:background_remover/utils/image_analysis/blur_scoring.dart';
import 'package:image/image.dart' as img;

/// Resizes [image] to 8×8 pixels using nearest-neighbour interpolation.
img.Image resizeImageTo8x8(img.Image image) {
  if (image.width == 0 || image.height == 0) {
    throw ArgumentError('Cannot resize zero-dimension image');
  }
  return img.copyResize(image, width: 8, height: 8,
      interpolation: img.Interpolation.nearest);
}

/// Classic Average Hash (aHash): 8×8 resize → mean threshold → 16-char hex.
String computeAverageHash(img.Image image) {
  final small = resizeImageTo8x8(image);
  final pixels = toGrayscaleMatrix(small).expand((r) => r).toList();
  final mean = pixels.reduce((a, b) => a + b) / pixels.length;
  final bits = pixels.map((p) => p >= mean ? 1 : 0).toList();
  return _encodeBitsToHex(bits);
}

/// Difference Hash (dHash): 9×8 resize → row-adjacent comparisons → 16-char hex.
/// This is the PRIMARY hash used for duplicate detection.
String computePerceptualHash(img.Image image) {
  if (image.width == 0 || image.height == 0) {
    throw ArgumentError('Cannot hash zero-dimension image');
  }
  final small = img.copyResize(image, width: 9, height: 8,
      interpolation: img.Interpolation.nearest);
  final matrix = toGrayscaleMatrix(small); // 8 rows × 9 cols
  final bits = <int>[];
  for (final row in matrix) {
    for (var c = 0; c < row.length - 1; c++) {
      bits.add(row[c] > row[c + 1] ? 1 : 0);
    }
  }
  return _encodeBitsToHex(bits);
}

/// Counts the number of differing bits between two 16-char hex hash strings.
int computeHammingDistance(String hashA, String hashB) {
  if (hashA.length != 16 || hashB.length != 16) {
    throw ArgumentError('Both hashes must be 16 characters long');
  }
  var distance = 0;
  for (var i = 0; i < hashA.length; i += 4) {
    final a = int.tryParse(hashA.substring(i, i + 4), radix: 16);
    final b = int.tryParse(hashB.substring(i, i + 4), radix: 16);
    if (a == null || b == null) throw ArgumentError('Invalid hex in hash');
    var xor = a ^ b;
    while (xor > 0) {
      distance += xor & 1;
      xor >>= 1;
    }
  }
  return distance;
}

/// Maps Hamming distance to a 0.0 (different) – 1.0 (identical) similarity score.
double computeSimilarity(String hashA, String hashB) =>
    (1.0 - computeHammingDistance(hashA, hashB) / 64.0).clamp(0.0, 1.0);

/// Returns true when [similarity] meets or exceeds [kDuplicateSimilarityThreshold].
bool areDuplicates(double similarity) =>
    similarity >= kDuplicateSimilarityThreshold;

/// Groups 64 bits (0 or 1) into a 16-character lowercase hex string.
String _encodeBitsToHex(List<int> bits) {
  final buffer = StringBuffer();
  for (var i = 0; i < 64; i += 4) {
    final nibble = (bits[i] << 3) | (bits[i + 1] << 2) |
        (bits[i + 2] << 1) | bits[i + 3];
    buffer.write(nibble.toRadixString(16));
  }
  return buffer.toString();
}
