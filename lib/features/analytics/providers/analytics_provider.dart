import 'package:flutter/foundation.dart';
import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/features/analytics/services/analytics_service.dart';
import 'package:background_remover/features/analytics/services/session_service.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:background_remover/shared/types/swipe.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider(this._analyticsService, this._sessionService);

  final AnalyticsService _analyticsService;
  final SessionService _sessionService;

  AnalyticsStats? stats;
  Session? activeSession;
  bool isLoading = false;
  AppError? error;

  /// Fetches the latest analytics stats and updates the UI state.
  Future<void> loadStats() async {
    isLoading = true;
    notifyListeners();
    final result = await _analyticsService.getStats();
    result.when(
      onSuccess: (data) {
        stats = data;
        error = null;
      },
      onFailure: (e) => error = e,
    );
    isLoading = false;
    notifyListeners();
  }

  /// Starts a new cleanup session and stores it as the active session.
  Future<void> startNewSession() async {
    final result = await _sessionService.startSession();
    result.when(
      onSuccess: (session) {
        activeSession = session;
        error = null;
      },
      onFailure: (e) => error = e,
    );
    notifyListeners();
  }

  /// Records a swipe for the active session; no-op (with error) if no session is active.
  Future<void> recordSwipe(SwipeAction action, PhotoItem photo) async {
    if (activeSession == null) {
      error = AppError.sessionNotFound;
      notifyListeners();
      return;
    }
    final result =
        await _sessionService.recordSwipe(activeSession!, action, photo);
    result.when(
      onSuccess: (session) {
        activeSession = session;
        error = null;
      },
      onFailure: (e) => error = e,
    );
    notifyListeners();
  }

  /// Ends the active session, clears it, and reloads stats.
  Future<void> endCurrentSession() async {
    if (activeSession == null) return;
    final result = await _sessionService.endSession(activeSession!);
    result.when(
      onSuccess: (_) {
        activeSession = null;
        error = null;
      },
      onFailure: (e) => error = e,
    );
    notifyListeners();
    if (error == null) await loadStats();
  }

  /// Clears the last recorded error.
  void clearError() {
    error = null;
    notifyListeners();
  }
}
