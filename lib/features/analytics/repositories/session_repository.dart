import 'package:background_remover/features/analytics/analytics_constants.dart';
import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/services/logger/app_logger.dart';
import 'package:background_remover/services/supabase/supabase_client.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/result.dart';

const _kColumns =
    'id,started_at,ended_at,reviewed,deleted,kept,storage_saved';

class SessionRepository {
  static const _tag = 'SessionRepository';

  /// Upserts a session row; validates id and startedAt before insert.
  Future<Result<void, AppError>> save(Session session) async {
    if (session.id.isEmpty) {
      AppLogger.error(_tag, 'saveSession: id is empty');
      return Result.failure(AppError.insertFailed);
    }
    if (session.startedAt <= 0) {
      AppLogger.error(_tag, 'saveSession: startedAt must be > 0');
      return Result.failure(AppError.insertFailed);
    }
    try {
      await SupabaseClientWrapper.instance.client
          .from('sessions')
          .upsert(session.toJson());
      return Result.success(null);
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.insertFailed);
    }
  }

  /// Updates an existing session row matched by id.
  Future<Result<void, AppError>> update(Session session) async {
    try {
      await SupabaseClientWrapper.instance.client
          .from('sessions')
          .update(session.toJson())
          .eq('id', session.id);
      return Result.success(null);
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.insertFailed);
    }
  }

  /// Returns all sessions ordered by started_at descending, capped at kMaxSessionHistory.
  Future<Result<List<Session>, AppError>> getAll() async {
    try {
      final data = await SupabaseClientWrapper.instance.client
          .from('sessions')
          .select(_kColumns)
          .order('started_at', ascending: false)
          .limit(kMaxSessionHistory);
      return Result.success(
        data
            .map((e) => Session.fromJson(Map<String, Object?>.from(e)))
            .toList(),
      );
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.queryFailed);
    }
  }

  /// Returns a single session by id, or sessionNotFound if absent.
  Future<Result<Session, AppError>> getById(String id) async {
    try {
      final data = await SupabaseClientWrapper.instance.client
          .from('sessions')
          .select(_kColumns)
          .eq('id', id)
          .limit(1);
      if (data.isEmpty) return Result.failure(AppError.sessionNotFound);
      return Result.success(
        Session.fromJson(Map<String, Object?>.from(data.first)),
      );
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.queryFailed);
    }
  }

  /// Returns sessions with started_at >= [fromTimestamp] for incremental refresh.
  Future<Result<List<Session>, AppError>> getSessionsSince(
      int fromTimestamp) async {
    try {
      final data = await SupabaseClientWrapper.instance.client
          .from('sessions')
          .select(_kColumns)
          .gte('started_at', fromTimestamp)
          .order('started_at', ascending: false);
      return Result.success(
        data
            .map((e) => Session.fromJson(Map<String, Object?>.from(e)))
            .toList(),
      );
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.queryFailed);
    }
  }
}
