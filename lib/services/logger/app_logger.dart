import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static bool get enabled => kDebugMode;

  static void debug(String tag, String message) {
    if (!enabled) return;
    _log('DEBUG', tag, message);
  }

  static void info(String tag, String message) {
    if (!enabled) return;
    _log('INFO', tag, message);
  }

  static void warning(String tag, String message) {
    if (!enabled) return;
    _log('WARNING', tag, message);
  }

  static void error(String tag, String message) {
    if (!enabled) return;
    _log('ERROR', tag, message);
  }

  static void logError(String tag, Object error, StackTrace? stack) {
    if (!enabled) return;
    _log('ERROR', tag, error.toString());
    if (stack != null) {
      debugPrint('[ERROR] [$tag] $stack');
    }
  }

  static void _log(String level, String tag, String message) {
    final ts = DateTime.now().toIso8601String();
    debugPrint('[$level] [$ts] $tag: $message');
  }
}
