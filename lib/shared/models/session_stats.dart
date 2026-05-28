class SessionStats {
  final int totalReviewed;
  final int totalKept;
  final int totalDeleted;
  final int storageSaved;   
  final int sessionStart;
  final String date;        

  const SessionStats({
    this.totalReviewed = 0,
    this.totalKept = 0,
    this.totalDeleted = 0,
    this.storageSaved = 0,
    required this.sessionStart,
    required this.date,
  });
}
