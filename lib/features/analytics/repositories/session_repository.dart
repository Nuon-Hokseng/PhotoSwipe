import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/services/logger/app_logger.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/result.dart';

class SessionRepository {
  static const _tag = 'SessionRepository';

  /// Local-only save (no remote persistence).
  Future<Result<void, AppError>> save(Session session) async {
    if (session.id.isEmpty) {
      AppLogger.error(_tag, 'saveSession: id is empty');
      return Result.failure(AppError.insertFailed);
    }
    if (session.startedAt <= 0) {
      AppLogger.error(_tag, 'saveSession: startedAt must be > 0');
      return Result.failure(AppError.insertFailed);
    }
    return Result.success(null);
  }

  /// Local-only update (no remote persistence).
  Future<Result<void, AppError>> update(Session session) async {
    return Result.success(null);
  }

  /// Local-only getAll (returns empty — no persistence).
  Future<Result<List<Session>, AppError>> getAll() async {
    return Result.success([]);
  }

  /// Returns a single session by id (local-only, always not found).
  Future<Result<Session, AppError>> getById(String id) async {
    return Result.failure(AppError.sessionNotFound);
  }

  /// Returns sessions since timestamp (local-only, always empty).
  Future<Result<List<Session>, AppError>> getSessionsSince(
      int fromTimestamp) async {
    return Result.success([]);
  }
}
