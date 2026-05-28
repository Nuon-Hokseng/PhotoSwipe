class Session {
  const Session({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.reviewed,
    required this.deleted,
    required this.kept,
    required this.storageSaved,
  });

  factory Session.fromJson(Map<String, Object?> json) => Session(
        id: json['id'] as String,
        startedAt: json['started_at'] as int,
        endedAt: json['ended_at'] as int?,
        reviewed: json['reviewed'] as int,
        deleted: json['deleted'] as int,
        kept: json['kept'] as int,
        storageSaved: json['storage_saved'] as int,
      );

  final String id;
  final int startedAt;
  final int? endedAt;
  final int reviewed;
  final int deleted;
  final int kept;
  final int storageSaved;

  Map<String, Object?> toJson() => {
        'id': id,
        'started_at': startedAt,
        'ended_at': endedAt,
        'reviewed': reviewed,
        'deleted': deleted,
        'kept': kept,
        'storage_saved': storageSaved,
      };

  Session copyWith({
    String? id,
    int? startedAt,
    int? endedAt,
    int? reviewed,
    int? deleted,
    int? kept,
    int? storageSaved,
  }) =>
      Session(
        id: id ?? this.id,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        reviewed: reviewed ?? this.reviewed,
        deleted: deleted ?? this.deleted,
        kept: kept ?? this.kept,
        storageSaved: storageSaved ?? this.storageSaved,
      );
}

class DailyStat {
  const DailyStat({
    required this.date,
    required this.reviewed,
    required this.deleted,
    required this.storageSaved,
  });

  factory DailyStat.fromJson(Map<String, Object?> json) => DailyStat(
        date: json['date'] as String,
        reviewed: json['reviewed'] as int,
        deleted: json['deleted'] as int,
        storageSaved: json['storage_saved'] as int,
      );

  final String date;
  final int reviewed;
  final int deleted;
  final int storageSaved;

  Map<String, Object?> toJson() => {
        'date': date,
        'reviewed': reviewed,
        'deleted': deleted,
        'storage_saved': storageSaved,
      };
}

class WeeklyStat {
  const WeeklyStat({
    required this.weekStart,
    required this.weekEnd,
    required this.totalReviewed,
    required this.totalDeleted,
    required this.storageSaved,
  });

  factory WeeklyStat.fromJson(Map<String, Object?> json) => WeeklyStat(
        weekStart: json['week_start'] as String,
        weekEnd: json['week_end'] as String,
        totalReviewed: json['total_reviewed'] as int,
        totalDeleted: json['total_deleted'] as int,
        storageSaved: json['storage_saved'] as int,
      );

  final String weekStart;
  final String weekEnd;
  final int totalReviewed;
  final int totalDeleted;
  final int storageSaved;

  Map<String, Object?> toJson() => {
        'week_start': weekStart,
        'week_end': weekEnd,
        'total_reviewed': totalReviewed,
        'total_deleted': totalDeleted,
        'storage_saved': storageSaved,
      };
}

class AnalyticsStats {
  const AnalyticsStats({
    required this.totalReviewed,
    required this.totalKept,
    required this.totalDeleted,
    required this.storageSaved,
    required this.sessionHistory,
    required this.dailyStats,
    required this.weeklyStats,
  });

  factory AnalyticsStats.empty() => const AnalyticsStats(
        totalReviewed: 0,
        totalKept: 0,
        totalDeleted: 0,
        storageSaved: 0,
        sessionHistory: [],
        dailyStats: [],
        weeklyStats: [],
      );

  final int totalReviewed;
  final int totalKept;
  final int totalDeleted;
  final int storageSaved;
  final List<Session> sessionHistory;
  final List<DailyStat> dailyStats;
  final List<WeeklyStat> weeklyStats;

  AnalyticsStats copyWith({
    int? totalReviewed,
    int? totalKept,
    int? totalDeleted,
    int? storageSaved,
    List<Session>? sessionHistory,
    List<DailyStat>? dailyStats,
    List<WeeklyStat>? weeklyStats,
  }) =>
      AnalyticsStats(
        totalReviewed: totalReviewed ?? this.totalReviewed,
        totalKept: totalKept ?? this.totalKept,
        totalDeleted: totalDeleted ?? this.totalDeleted,
        storageSaved: storageSaved ?? this.storageSaved,
        sessionHistory: sessionHistory ?? this.sessionHistory,
        dailyStats: dailyStats ?? this.dailyStats,
        weeklyStats: weeklyStats ?? this.weeklyStats,
      );
}
