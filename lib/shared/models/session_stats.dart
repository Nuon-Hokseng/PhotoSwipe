class SessionStats {
  final int totalReviewed;
  final int totalKept;
  final int totalDeleted;
  final int storageSaved;   
  final int sessionStart;
  final String date;        

  const SessionStats({
    required this.totalReviewed,
    required this.totalKept,
    required this.totalDeleted,
    required this.storageSaved,
    required this.sessionStart,
    required this.date,
  });

  factory SessionStats.fromJson(Map<String, dynamic> json) => SessionStats(
        totalReviewed: json['totalReviewed'] as int,
        totalKept: json['totalKept'] as int,
        totalDeleted: json['totalDeleted'] as int,
        storageSaved: json['storageSaved'] as int,
        sessionStart: json['sessionStart'] as int,
        date: json['date'] as String,
      );

  Map<String, dynamic> toJson() => {
        'totalReviewed': totalReviewed,
        'totalKept': totalKept,
        'totalDeleted': totalDeleted,
        'storageSaved': storageSaved,
        'sessionStart': sessionStart,
        'date': date,
      };
}
