import 'dart:io';
import 'dart:typed_data';

import 'package:background_remover/features/ai/ai_constants.dart';
import 'package:background_remover/features/ai/ai_types.dart';
import 'package:background_remover/services/logger/app_logger.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/result.dart';
import 'package:background_remover/utils/image_analysis/blur_scoring.dart';
import 'package:flutter/foundation.dart';

// Top-level function required by compute() — must not be a class method.
double _analyzeBlurIsolate(Uint8List bytes) {
  final image = decodeImageBytes(bytes);
  final matrix = toGrayscaleMatrix(image);
  return computeBlurScoreFromMatrix(matrix);
}

class BlurDetectionService {
  static const _tag = 'BlurDetectionService';

  // In-memory LRU cache — keyed by URI.
  final Map<String, BlurResult> _cache = {};

  /// Analyses a single image at [uri]; returns cached result if available.
  Future<Result<BlurResult, AppError>> detectBlur(String uri) async {
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
      final start = DateTime.now().millisecondsSinceEpoch;
      final score = await compute(_analyzeBlurIsolate, bytes);
      final ms = DateTime.now().millisecondsSinceEpoch - start;
      AppLogger.debug(_tag, 'Blur analysed $uri in ${ms}ms → score=$score');
      final result = BlurResult(
          photoId: uri, blurScore: score, isBlurry: score > kBlurThreshold);
      _evictIfNeeded();
      _cache[uri] = result;
      return Result.success(result);
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.blurAnalysisFailed);
    }
  }

  /// Processes [uris] in batches, yielding each [BlurResult] immediately.
  Stream<Result<BlurResult, AppError>> detectBlurBatch(
      List<String> uris) async* {
    for (var i = 0; i < uris.length; i += kAiBatchSize) {
      final batch = uris.sublist(i, (i + kAiBatchSize).clamp(0, uris.length));
      for (final uri in batch) {
        yield await detectBlur(uri);
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
