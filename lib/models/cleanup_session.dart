enum CleanupActivityType { keep, delete, undo }

class CleanupActivity {
  const CleanupActivity({
    required this.photoId,
    required this.photoLabel,
    required this.actionType,
    required this.timestamp,
    required this.photoSizeBytes,
    required this.storageDeltaBytes,
  });

  final String photoId;
  final String photoLabel;
  final CleanupActivityType actionType;
  final DateTime timestamp;
  final int photoSizeBytes;
  final int storageDeltaBytes;

  bool get isUndo => actionType == CleanupActivityType.undo;
}

class CleanupSession {
  const CleanupSession({
    required this.sessionId,
    required this.startedAt,
    required this.updatedAt,
    required this.totalPhotos,
    required this.reviewedCount,
    required this.deletedCount,
    required this.keptCount,
    required this.storageSavedBytes,
    required this.recentActions,
    required this.weeklyActivity,
  });

  factory CleanupSession.initial({required int totalPhotos}) {
    final now = DateTime.now();

    return CleanupSession(
      sessionId: 'session-${now.millisecondsSinceEpoch}',
      startedAt: now,
      updatedAt: now,
      totalPhotos: totalPhotos,
      reviewedCount: 0,
      deletedCount: 0,
      keptCount: 0,
      storageSavedBytes: 0,
      recentActions: const <CleanupActivity>[],
      weeklyActivity: List<int>.unmodifiable(List<int>.filled(7, 0)),
    );
  }

  final String sessionId;
  final DateTime startedAt;
  final DateTime updatedAt;
  final int totalPhotos;
  final int reviewedCount;
  final int deletedCount;
  final int keptCount;
  final int storageSavedBytes;
  final List<CleanupActivity> recentActions;
  final List<int> weeklyActivity;

  double get completionRate =>
      totalPhotos == 0 ? 0 : reviewedCount / totalPhotos;

  double get cleanupEfficiency =>
      reviewedCount == 0 ? 0 : deletedCount / reviewedCount;

  int get remainingPhotos =>
      (totalPhotos - reviewedCount).clamp(0, totalPhotos).toInt();

  CleanupSession copyWith({
    String? sessionId,
    DateTime? startedAt,
    DateTime? updatedAt,
    int? totalPhotos,
    int? reviewedCount,
    int? deletedCount,
    int? keptCount,
    int? storageSavedBytes,
    List<CleanupActivity>? recentActions,
    List<int>? weeklyActivity,
  }) {
    return CleanupSession(
      sessionId: sessionId ?? this.sessionId,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalPhotos: totalPhotos ?? this.totalPhotos,
      reviewedCount: reviewedCount ?? this.reviewedCount,
      deletedCount: deletedCount ?? this.deletedCount,
      keptCount: keptCount ?? this.keptCount,
      storageSavedBytes: storageSavedBytes ?? this.storageSavedBytes,
      recentActions: recentActions ?? this.recentActions,
      weeklyActivity: weeklyActivity ?? this.weeklyActivity,
    );
  }
}
