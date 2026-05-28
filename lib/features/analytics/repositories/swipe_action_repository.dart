import 'package:background_remover/services/logger/app_logger.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/result.dart';
import 'package:background_remover/shared/types/swipe.dart';

class SwipeActionRepository {
  static const _tag = 'SwipeActionRepository';

  /// Local-only save (no remote persistence).
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
    return Result.success(null);
  }

  /// Local-only getForSession (returns empty).
  Future<Result<List<SwipeAction>, AppError>> getForSession(
    String sessionId,
  ) async {
    return Result.success([]);
  }

  /// Local-only getAll (returns empty).
  Future<Result<List<SwipeAction>, AppError>> getAll() async {
    return Result.success([]);
  }
}
