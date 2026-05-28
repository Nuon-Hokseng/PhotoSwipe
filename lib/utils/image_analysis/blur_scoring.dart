import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Raw variance above which an image is considered perfectly sharp.
const double kVarianceNormalizationFactor = 500.0;

/// Decodes raw bytes into an [img.Image]; throws [ArgumentError] if bytes are invalid.
img.Image decodeImageBytes(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) throw ArgumentError('Cannot decode image bytes');
  return image;
}

/// Converts [image] to a 2-D luminance matrix using: L = 0.299R + 0.587G + 0.114B.
/// Returns an empty list for zero-dimension images.
List<List<int>> toGrayscaleMatrix(img.Image image) {
  if (image.width == 0 || image.height == 0) return [];
  return List.generate(
    image.height,
    (r) => List.generate(image.width, (c) {
      final p = image.getPixel(c, r);
      return (0.299 * p.r.toDouble() + 0.587 * p.g.toDouble() + 0.114 * p.b.toDouble())
          .round()
          .clamp(0, 255);
    }),
  );
}

/// Applies the 3×3 Laplacian kernel [0,-1,0 / -1,4,-1 / 0,-1,0].
/// Border pixels are set to 0.0; matrices smaller than 3×3 return all zeros.
List<List<double>> applyLaplacianKernel(List<List<int>> matrix) {
  final rows = matrix.length;
  final cols = rows > 0 ? matrix[0].length : 0;
  final result = List.generate(rows, (_) => List.filled(cols, 0.0));
  if (rows < 3 || cols < 3) return result;
  for (var r = 1; r < rows - 1; r++) {
    for (var c = 1; c < cols - 1; c++) {
      result[r][c] = (4 * matrix[r][c]
              - matrix[r - 1][c]
              - matrix[r + 1][c]
              - matrix[r][c - 1]
              - matrix[r][c + 1])
          .toDouble();
    }
  }
  return result;
}

/// Computes statistical variance of all interior (non-border) values.
/// Returns 0.0 for an empty or all-border matrix.
double computeVariance(List<List<double>> convolved) {
  if (convolved.isEmpty) return 0.0;
  final values = <double>[
    for (var r = 1; r < convolved.length - 1; r++)
      for (var c = 1; c < convolved[r].length - 1; c++) convolved[r][c],
  ];
  if (values.isEmpty) return 0.0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  return values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
      values.length;
}

/// Maps raw variance to a 0.0 (sharp) – 1.0 (blurry) normalised score.
double normalizeBlurScore(double variance) =>
    1.0 - (variance / kVarianceNormalizationFactor).clamp(0.0, 1.0);

/// Convenience pipeline: grayscale matrix → Laplacian → variance → normalised score.
double computeBlurScoreFromMatrix(List<List<int>> matrix) =>
    normalizeBlurScore(computeVariance(applyLaplacianKernel(matrix)));
