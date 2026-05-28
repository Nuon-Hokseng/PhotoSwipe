import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/gallery_constants.dart';
import '../../shared/models/app_session.dart';
import '../../shared/models/session_stats.dart';

class SessionPersistenceService {
  /// Persists [session] and the [remainingPhotoIds] to SharedPreferences.
  Future<void> saveSession(
    AppSession session,
    List<String> remainingPhotoIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'version': kSessionPersistenceVersion,
      'sessionId': session.id,
      'startTime': session.startTime,
      'remainingIds': remainingPhotoIds,
      'stats': {
        'totalReviewed': session.stats.totalReviewed,
        'totalKept': session.stats.totalKept,
        'totalDeleted': session.stats.totalDeleted,
        'storageSaved': session.stats.storageSaved,
        'sessionStart': session.stats.sessionStart,
        'date': session.stats.date,
      },
    };
    await prefs.setString(kSessionPersistenceKey, jsonEncode(data));
  }

  /// Loads a persisted session from SharedPreferences. Returns null if no
  /// session is saved or if the persisted version does not match the current
  /// [kSessionPersistenceVersion].
  Future<AppSession?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kSessionPersistenceKey);
    if (raw == null) return null;

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    final version = data['version'] as int?;
    if (version != kSessionPersistenceVersion) return null;

    final statsMap = data['stats'] as Map<String, dynamic>? ?? {};
    final stats = SessionStats(
      totalReviewed: statsMap['totalReviewed'] as int? ?? 0,
      totalKept: statsMap['totalKept'] as int? ?? 0,
      totalDeleted: statsMap['totalDeleted'] as int? ?? 0,
      storageSaved: statsMap['storageSaved'] as int? ?? 0,
      sessionStart: statsMap['sessionStart'] as int? ?? 0,
      date: statsMap['date'] as String? ?? '',
    );

    return AppSession(
      id: data['sessionId'] as String? ?? '',
      startTime: data['startTime'] as int? ?? 0,
      stats: stats,
    );
  }

  /// Deletes the persisted session data.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kSessionPersistenceKey);
  }
}
