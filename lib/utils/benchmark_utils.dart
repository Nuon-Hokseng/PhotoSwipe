import 'package:background_remover/services/logger/app_logger.dart';
import 'package:flutter/foundation.dart';

class BenchmarkUtils {
  BenchmarkUtils._();

  /// Measures and logs execution time of an async [operation]. No-op in release mode.
  static Future<T> measure<T>(
    String label,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) return operation();
    final sw = Stopwatch()..start();
    try {
      final result = await operation();
      sw.stop();
      AppLogger.debug('Benchmark', '$label: ${sw.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      sw.stop();
      AppLogger.error('Benchmark',
          '$label failed after ${sw.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  /// Measures synchronous [operation]. No-op in release mode.
  static T measureSync<T>(String label, T Function() operation) {
    if (!kDebugMode) return operation();
    final sw = Stopwatch()..start();
    final result = operation();
    sw.stop();
    AppLogger.debug('Benchmark', '$label: ${sw.elapsedMilliseconds}ms');
    return result;
  }
}
