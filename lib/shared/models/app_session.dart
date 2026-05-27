import 'session_stats.dart';

class AppSession {
  final String id;
  final int startTime;
  final SessionStats stats;

  const AppSession({
    required this.id,
    required this.startTime,
    required this.stats,
  });
}
