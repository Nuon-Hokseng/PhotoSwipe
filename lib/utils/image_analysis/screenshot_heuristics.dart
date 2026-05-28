// Local ScreenshotSignals defined here because the fields differ from ai_types.dart.
// ai_types.dart uses matchesDeviceRatio / matchesScreenResolution / hasHighDPI,
// which are placeholder fields from Stage 1.  Stage 4 detection uses the three
// signals below, which map directly to the scoring weights in this pipeline.
import 'package:background_remover/features/ai/ai_constants.dart';

class ScreenshotSignals {
  const ScreenshotSignals({
    required this.matchesCommonAspectRatio,
    required this.matchesCommonResolution,
    required this.hasUIPatterns,
  });

  final bool matchesCommonAspectRatio;
  final bool matchesCommonResolution;
  final bool hasUIPatterns;
}

const _ratios = [
  (9.0, 16.0), (9.0, 19.5), (9.0, 20.0), (3.0, 4.0), (16.0, 9.0),
];

const _resolutions = [
  (390, 844), (393, 852), (360, 800), (412, 915),
  (1170, 2532), (1179, 2556), (1080, 2400), (768, 1024),
];

/// Returns true if width:height matches a known device screen ratio within 5%.
bool checkAspectRatio(int width, int height) {
  if (width == 0 || height == 0) return false;
  final ratio = width / height;
  return _ratios.any((r) {
    final expected = r.$1 / r.$2;
    return (ratio - expected).abs() <= expected * 0.05;
  });
}

/// Returns true if dimensions match a known screen resolution within ±10 px.
bool checkCommonResolution(int width, int height) => _resolutions.any(
      (r) =>
          ((width - r.$1).abs() <= 10 && (height - r.$2).abs() <= 10) ||
          ((width - r.$2).abs() <= 10 && (height - r.$1).abs() <= 10),
    );

/// Returns true if the top 5% or bottom 10% of rows form a uniform color band.
/// Requires at least 20 rows; fewer returns false.
bool checkUIPatterns(List<List<int>> matrix) {
  final rows = matrix.length;
  if (rows < 20) return false;
  final top = (rows * 0.05).floor().clamp(1, rows);
  final bottom = (rows * 0.10).floor().clamp(1, rows);
  return _isUniformBand(matrix, 0, top) ||
      _isUniformBand(matrix, rows - bottom, rows);
}

/// Returns true when luminance variance across [from]..[to) rows is < 15.
bool _isUniformBand(List<List<int>> matrix, int from, int to) {
  final vals = [for (var r = from; r < to; r++) ...matrix[r]];
  if (vals.isEmpty) return false;
  final mean = vals.reduce((a, b) => a + b) / vals.length;
  return vals.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
          vals.length <
      15;
}

/// Returns a weighted confidence score: aspect=0.35, resolution=0.45, ui=0.20.
double scoreScreenshotLikelihood(ScreenshotSignals signals) =>
    (signals.matchesCommonAspectRatio ? 0.35 : 0.0) +
    (signals.matchesCommonResolution ? 0.45 : 0.0) +
    (signals.hasUIPatterns ? 0.20 : 0.0);

/// Returns true when [score] meets or exceeds [kScreenshotConfidenceThreshold].
bool isScreenshot(double score) => score >= kScreenshotConfidenceThreshold;
