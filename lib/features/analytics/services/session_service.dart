import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/features/analytics/repositories/analytics_repository.dart';
import 'package:background_remover/services/logger/app_logger.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:background_remover/shared/types/result.dart';
import 'package:background_remover/shared/types/swipe.dart';
import 'package:uuid/uuid.dart';

class SessionService {
  SessionService(this._repo);

  final AnalyticsRepository _repo;
  static const _tag = 'SessionService';
  static const _uuid = Uuid();

  Session? _currentSession;

  /// Returns the currently active in-memory session, or null if none is running.
  Session? get getCurrentSession => _currentSession;

  /// Creates a new session, persists it immediately, and sets it as active.
  Future<Result<Session, AppError>> startSession() async {
    final session = Session(
      id: _uuid.v4(),
      startedAt: DateTime.now().millisecondsSinceEpoch,
      reviewed: 0,
      deleted: 0,
      kept: 0,
      storageSaved: 0,
    );
    final saveResult = await _repo.saveSession(session);
    if (saveResult.isFailure) {
      AppLogger.error(_tag, 'Failed to persist new session ${session.id}');
      return Result.failure(AppError.sessionPersistFailed);
    }
    _currentSession = session;
    AppLogger.info(_tag, 'Session started: ${session.id}');
    return Result.success(session);
  }

  /// Records a swipe, updates counters, and persists after every call for crash recovery.
  Future<Result<Session, AppError>> recordSwipe(
    Session session,
    SwipeAction action,
    PhotoItem photo,
  ) async {
    final saveResult = await _repo.saveSwipeAction(action, session.id);
    if (saveResult.isFailure) {
      return Result.failure(AppError.sessionPersistFailed);
    }
    final isDelete = action.action == SwipeActionType.delete;
    final updated = session.copyWith(
      reviewed: session.reviewed + 1,
      deleted: session.deleted + (isDelete ? 1 : 0),
      kept: session.kept + (isDelete ? 0 : 1),
      storageSaved: session.storageSaved + (isDelete ? photo.size : 0),
    );
    final updateResult = await _repo.updateSession(updated);
    if (updateResult.isFailure) {
      AppLogger.error(_tag, 'Counter update failed for session ${session.id}');
      return Result.failure(AppError.sessionPersistFailed);
    }
    _currentSession = updated;
    return Result.success(updated);
  }

  /// Sets endedAt to now, persists the final session state, and clears active session.
  Future<Result<Session, AppError>> endSession(Session session) async {
    final ended = session.copyWith(
      endedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final result = await _repo.updateSession(ended);
    if (result.isFailure) {
      return Result.failure(AppError.sessionPersistFailed);
    }
    _currentSession = null;
    AppLogger.info(_tag, 'Session ended: ${ended.id}');
    return Result.success(ended);
  }

  /// Restores a previous session from Supabase, useful after an app crash.
  Future<Result<Session, AppError>> resumeSession(String sessionId) async {
    final result = await _repo.getSessionById(sessionId);
    if (result.isFailure) {
      return Result.failure(
        (result as Failure<Session, AppError>).error,
      );
    }
    final session = (result as Success<Session, AppError>).data;
    _currentSession = session;
    AppLogger.info(_tag, 'Session resumed: $sessionId');
    return Result.success(session);
  }
}
