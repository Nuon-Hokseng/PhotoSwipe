import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/features/analytics/repositories/session_repository.dart';
import 'package:background_remover/features/analytics/repositories/swipe_action_repository.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/result.dart';
import 'package:background_remover/shared/types/swipe.dart';

/// Facade that exposes a unified analytics data API to the service layer.
class AnalyticsRepository {
  AnalyticsRepository()
      : _sessions = SessionRepository(),
        _swipes = SwipeActionRepository();

  final SessionRepository _sessions;
  final SwipeActionRepository _swipes;

  /// Upserts a session row.
  Future<Result<void, AppError>> saveSession(Session s) => _sessions.save(s);

  /// Updates an existing session row matched by id.
  Future<Result<void, AppError>> updateSession(Session s) =>
      _sessions.update(s);

  /// Returns all sessions ordered by started_at descending.
  Future<Result<List<Session>, AppError>> getAllSessions() =>
      _sessions.getAll();

  /// Returns a single session by id.
  Future<Result<Session, AppError>> getSessionById(String id) =>
      _sessions.getById(id);

  /// Inserts a swipe action linked to the given sessionId.
  Future<Result<void, AppError>> saveSwipeAction(
    SwipeAction action,
    String sessionId,
  ) =>
      _swipes.save(action, sessionId);

  /// Returns all swipe actions for a session ordered by timestamp ascending.
  Future<Result<List<SwipeAction>, AppError>> getSwipeActionsForSession(
    String sessionId,
  ) =>
      _swipes.getForSession(sessionId);

  /// Returns sessions with started_at >= [fromTimestamp] for incremental refresh.
  Future<Result<List<Session>, AppError>> getSessionsSince(int fromTimestamp) =>
      _sessions.getSessionsSince(fromTimestamp);

  /// Returns all swipe actions. Use only for backup/export — not for stats.
  Future<Result<List<SwipeAction>, AppError>> getAllSwipeActions() =>
      _swipes.getAll();
}
