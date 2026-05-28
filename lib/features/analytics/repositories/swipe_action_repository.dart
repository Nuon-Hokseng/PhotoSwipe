import 'package:background_remover/services/logger/app_logger.dart';
import 'package:background_remover/services/supabase/supabase_client.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/result.dart';
import 'package:background_remover/shared/types/swipe.dart';

class SwipeActionRepository {
  static const _tag = 'SwipeActionRepository';

  /// Inserts a swipe action row; validates action and sessionId before insert.
  Future<Result<void, AppError>> save(
    SwipeAction action,
    String sessionId,
  ) async {
    if (sessionId.isEmpty) {
      AppLogger.error(_tag, 'save: sessionId is empty');
      return Result.failure(AppError.insertFailed);
    }
    final actionStr = action.action.name;
    if (actionStr != 'keep' && actionStr != 'delete') {
      AppLogger.error(_tag, 'save: invalid action "$actionStr"');
      return Result.failure(AppError.insertFailed);
    }
    try {
      await SupabaseClientWrapper.instance.client
          .from('swipe_actions')
          .insert({
        'session_id': sessionId,
        'photo_id': action.photoId,
        'action': actionStr,
        'timestamp': action.timestamp,
      });
      return Result.success(null);
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.insertFailed);
    }
  }

  /// Returns all swipe actions for a session ordered by timestamp ascending.
  Future<Result<List<SwipeAction>, AppError>> getForSession(
    String sessionId,
  ) async {
    try {
      final data = await SupabaseClientWrapper.instance.client
          .from('swipe_actions')
          .select()
          .eq('session_id', sessionId)
          .order('timestamp', ascending: true);
      return Result.success(
        data
            .map((e) => SwipeAction.fromJson(Map<String, Object?>.from(e)))
            .toList(),
      );
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.queryFailed);
    }
  }

  /// Returns all swipe actions ordered by timestamp descending.
  /// Use only for full backup/export — prefer getForSession() for stats.
  Future<Result<List<SwipeAction>, AppError>> getAll() async {
    try {
      final data = await SupabaseClientWrapper.instance.client
          .from('swipe_actions')
          .select()
          .order('timestamp', ascending: false);
      return Result.success(
        data
            .map((e) => SwipeAction.fromJson(Map<String, Object?>.from(e)))
            .toList(),
      );
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      return Result.failure(AppError.queryFailed);
    }
  }
}
