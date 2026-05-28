import 'package:flutter/foundation.dart';

import '../models/cleanup_session.dart';
import '../models/photo_model.dart';

class AnalyticsController extends ChangeNotifier {
  AnalyticsController._({required int totalPhotos})
    : _session = CleanupSession.initial(totalPhotos: totalPhotos);

  static final AnalyticsController instance = AnalyticsController._(
    totalPhotos: 0,
  );

  CleanupSession _session;
  final List<CleanupActivity> _actionStack = <CleanupActivity>[];

  CleanupSession get session => _session;
  List<CleanupActivity> get history =>
      List<CleanupActivity>.unmodifiable(_session.recentActions);
  int get totalPhotos => _session.totalPhotos;
  int get reviewedCount => _session.reviewedCount;
  int get deletedCount => _session.deletedCount;
  int get keptCount => _session.keptCount;
  int get storageSavedBytes => _session.storageSavedBytes;
  bool get canUndo => _actionStack.isNotEmpty;
  double get completionRate => _session.completionRate;
  double get cleanupEfficiency => _session.cleanupEfficiency;
  List<int> get weeklyActivity =>
      List<int>.unmodifiable(_session.weeklyActivity);

  void configureSession({required int totalPhotos}) {
    if (_session.totalPhotos == totalPhotos) {
      return;
    }

    resetSession(totalPhotos: totalPhotos);
  }

  CleanupActivity addKeepAction(PhotoModel photo) {
    return _recordAction(photo, CleanupActivityType.keep);
  }

  CleanupActivity addDeleteAction(PhotoModel photo) {
    return _recordAction(photo, CleanupActivityType.delete);
  }

  CleanupActivity? undoLastAction() {
    if (_actionStack.isEmpty) {
      return null;
    }

    final lastAction = _actionStack.removeLast();
    final updatedWeeklyActivity = List<int>.from(_session.weeklyActivity);
    final weekIndex = lastAction.timestamp.weekday - 1;
    updatedWeeklyActivity[weekIndex] = (updatedWeeklyActivity[weekIndex] - 1)
        .clamp(0, 9999)
        .toInt();

    final undoEntry = CleanupActivity(
      photoId: lastAction.photoId,
      photoLabel: lastAction.photoLabel,
      actionType: CleanupActivityType.undo,
      timestamp: DateTime.now(),
      photoSizeBytes: lastAction.photoSizeBytes,
      storageDeltaBytes: -lastAction.storageDeltaBytes,
    );

    final updatedRecentActions = <CleanupActivity>[
      undoEntry,
      ..._session.recentActions,
    ];

    _session = _session.copyWith(
      reviewedCount: (_session.reviewedCount - 1)
          .clamp(0, _session.totalPhotos)
          .toInt(),
      deletedCount: lastAction.actionType == CleanupActivityType.delete
          ? (_session.deletedCount - 1).clamp(0, _session.totalPhotos).toInt()
          : _session.deletedCount,
      keptCount: lastAction.actionType == CleanupActivityType.keep
          ? (_session.keptCount - 1).clamp(0, _session.totalPhotos).toInt()
          : _session.keptCount,
      storageSavedBytes:
          (calculateStorageSaved() - lastAction.storageDeltaBytes)
              .clamp(0, 1 << 62)
              .toInt(),
      updatedAt: undoEntry.timestamp,
      recentActions: updatedRecentActions,
      weeklyActivity: updatedWeeklyActivity,
    );

    notifyListeners();
    return undoEntry;
  }

  int calculateStorageSaved() => _session.storageSavedBytes;

  void resetSession({int? totalPhotos}) {
    final newTotalPhotos = totalPhotos ?? _session.totalPhotos;
    _actionStack.clear();
    _session = CleanupSession.initial(totalPhotos: newTotalPhotos);
    notifyListeners();
  }

  CleanupActivity _recordAction(PhotoModel photo, CleanupActivityType type) {
    final timestamp = DateTime.now();
    final storageDeltaBytes = type == CleanupActivityType.delete
        ? photo.fileSizeBytes
        : 0;
    final activity = CleanupActivity(
      photoId: photo.id,
      photoLabel: photo.filename,
      actionType: type,
      timestamp: timestamp,
      photoSizeBytes: photo.fileSizeBytes,
      storageDeltaBytes: storageDeltaBytes,
    );

    _actionStack.add(activity);

    final updatedRecentActions = <CleanupActivity>[
      activity,
      ..._session.recentActions,
    ];

    final updatedWeeklyActivity = List<int>.from(_session.weeklyActivity);
    updatedWeeklyActivity[timestamp.weekday - 1] += 1;

    _session = _session.copyWith(
      reviewedCount: _session.reviewedCount + 1,
      deletedCount: type == CleanupActivityType.delete
          ? _session.deletedCount + 1
          : _session.deletedCount,
      keptCount: type == CleanupActivityType.keep
          ? _session.keptCount + 1
          : _session.keptCount,
      storageSavedBytes: type == CleanupActivityType.delete
          ? _session.storageSavedBytes + photo.fileSizeBytes
          : _session.storageSavedBytes,
      updatedAt: timestamp,
      recentActions: updatedRecentActions,
      weeklyActivity: updatedWeeklyActivity,
    );

    notifyListeners();
    return activity;
  }
}
