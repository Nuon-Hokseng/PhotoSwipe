import 'package:background_remover/features/analytics/analytics_types.dart';

const _kB = 1024;
const _kMB = 1048576;
const _kGB = 1073741824;

const _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// Converts bytes to a human-readable size string (B / KB / MB / GB).
String formatStorageSize(int bytes) {
  if (bytes < _kB) return '$bytes B';
  if (bytes < _kMB) return '${(bytes / _kB).toStringAsFixed(1)} KB';
  if (bytes < _kGB) return '${(bytes / _kMB).toStringAsFixed(1)} MB';
  return '${(bytes / _kGB).toStringAsFixed(2)} GB';
}

/// Converts a unix timestamp (ms) to a 'dd MMM yyyy' display string.
String formatDate(int unixTimestamp) {
  final dt = DateTime.fromMillisecondsSinceEpoch(unixTimestamp);
  final d = dt.day.toString().padLeft(2, '0');
  return '$d ${_monthAbbr[dt.month - 1]} ${dt.year}';
}

/// Returns a human-readable elapsed duration between two unix timestamps (ms).
String formatDuration(int startMs, int endMs) {
  final minutes = ((endMs - startMs) / 60000).floor();
  if (minutes < 1) return 'less than a minute';
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h}h ${m}min';
}

/// Groups sessions by formatted date key; supports 'yyyy-MM-dd' pattern.
Map<String, List<Session>> groupByDate(
  List<Session> sessions,
  String dateFormat,
) {
  final result = <String, List<Session>>{};
  for (final session in sessions) {
    final key = _toYmd(DateTime.fromMillisecondsSinceEpoch(session.startedAt));
    result.putIfAbsent(key, () => []).add(session);
  }
  return result;
}

/// Converts unix ms timestamp to local [DateTime].
DateTime timestampToDate(int unixMs) =>
    DateTime.fromMillisecondsSinceEpoch(unixMs);

/// Formats a week range with context-aware separators.
/// Same month: '15–21 Jan 2024'; different months: '28 Jan – 3 Feb 2024';
/// different years: '30 Dec 2023 – 5 Jan 2024'.
String getWeekRangeLabel(String weekStart, String weekEnd) {
  final s = _parseYmd(weekStart);
  final e = _parseYmd(weekEnd);
  if (s.year != e.year) {
    return '${s.day} ${_monthAbbr[s.month - 1]} ${s.year} – '
        '${e.day} ${_monthAbbr[e.month - 1]} ${e.year}';
  }
  if (s.month != e.month) {
    return '${s.day} ${_monthAbbr[s.month - 1]} – '
        '${e.day} ${_monthAbbr[e.month - 1]} ${e.year}';
  }
  return '${s.day}–${e.day} ${_monthAbbr[s.month - 1]} ${s.year}';
}

/// Returns a human-friendly label for a 'yyyy-MM-dd' date string relative to today.
String getDayLabel(String dateString) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dt = _parseYmd(dateString);
  final diff = today.difference(dt).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  final mondayOfCurrentWeek = today.subtract(Duration(days: today.weekday - 1));
  if (!dt.isBefore(mondayOfCurrentWeek) && diff > 1) {
    return _weekdayNames[dt.weekday - 1];
  }
  return '${dt.day.toString().padLeft(2, '0')} ${_monthAbbr[dt.month - 1]}';
}

/// Returns '+n', '-n', or '—' for a numeric delta value.
String formatStatDelta(int delta) {
  if (delta == 0) return '—';
  return delta > 0 ? '+$delta' : '$delta';
}

DateTime _parseYmd(String date) {
  final p = date.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String _toYmd(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';
