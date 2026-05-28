import 'dart:io';
import 'dart:typed_data';

import 'package:background_remover/features/ai/ai_constants.dart';
import 'package:background_remover/features/ai/ai_types.dart';
import 'package:background_remover/services/logger/app_logger.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/result.dart';
import 'package:background_remover/utils/image_analysis/blur_scoring.dart';
import 'package:background_remover/utils/image_analysis/screenshot_heuristics.dart'
    as heuristics;
import 'package:flutter/foundation.dart';

// Top-level for compute() — returns [width, height, hasUIPatterns].
List<Object> _analyzeScreenshotIsolate(Uint8List bytes) {
  final image = decodeImageBytes(bytes);
  final matrix = toGrayscaleMatrix(image);
  return [image.width, image.height, heuristics.checkUIPatterns(matrix)];
}

class ScreenshotDetectionService {
  static const _tag = 'ScreenshotDetectionService';

  // In-memory LRU cache — keyed by URI.
  final Map<String, ScreenshotResult> _cache = {};

  /// Analyses a single image at [uri]; returns cached result if available.
  Future<Result<ScreenshotResult, AppError>> detectScreenshot(
      String uri) async {
    if (_cache.containsKey(uri)) {
      AppLogger.debug(_tag, 'Cache hit for $uri');
      return Result.success(_cache[uri]!);
    }
    final Uint8List bytes;
    try {
      bytes = await File(uri).readAsBytes();
    } catch (_) {
      return Result.failure(AppError.imageLoadFailed);
    }
    try {
      final data = await compute(_analyzeScreenshotIsolate, bytes);
      final width = data[0] as int;
      final height = data[1] as int;
      final hasUI = data[2] as bool;
      final signals = _buildSignals(width, height, hasUI);
      final score = heuristics.scoreScreenshotLikelihood(signals);
      AppLogger.debug(_tag, 'Screenshot analysed $uri → score=$score');
      final result = ScreenshotResult(
          photoId: uri,
          confidence: score,
          isScreenshot: heuristics.isScreenshot(score));
      _evictIfNeeded();
      _cache[uri] = result;
      return Result.success(result);
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.screenshotAnalysisFailed);
    }
  }

  /// Processes [uris] in batches, yielding each [ScreenshotResult] immediately.
  Stream<Result<ScreenshotResult, AppError>> detectScreenshotBatch(
      List<String> uris) async* {
    for (var i = 0; i < uris.length; i += kAiBatchSize) {
      final batch = uris.sublist(i, (i + kAiBatchSize).clamp(0, uris.length));
      for (final uri in batch) {
        yield await detectScreenshot(uri);
      }
      await _yieldToMainThread();
    }
  }

  /// Clears the analysis cache.
  void clearCache() {
    _cache.clear();
    AppLogger.debug(_tag, 'Cache cleared');
  }

  /// Number of cached results.
  int get cacheSize => _cache.length;

  heuristics.ScreenshotSignals _buildSignals(
          int width, int height, bool hasUIPatterns) =>
      heuristics.ScreenshotSignals(
        matchesCommonAspectRatio: heuristics.checkAspectRatio(width, height),
        matchesCommonResolution:
            heuristics.checkCommonResolution(width, height),
        hasUIPatterns: hasUIPatterns,
      );

  void _evictIfNeeded() {
    if (_cache.length >= kMaxAiCacheSize) {
      final toRemove = _cache.keys.take(500).toList();
      for (final k in toRemove) {
        _cache.remove(k);
      }
      AppLogger.debug(_tag, 'LRU eviction: removed 500 oldest entries');
    }
  }

  Future<void> _yieldToMainThread() => Future.delayed(Duration.zero);
}
