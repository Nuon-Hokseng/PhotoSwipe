# Analytics Service API — Person 3

## Overview

Session-based stats system backed by Supabase.
Every swipe is persisted immediately — crash-safe by design.
Stats are always read from the database, never from in-memory state.

---

## getStats() → Future<Result<AnalyticsStats, AppError>>

**Service:** `AnalyticsService`
**Import:** `package:background_remover/features/analytics/services/analytics_service.dart`

Always reads from Supabase. Returns fully computed `AnalyticsStats`:

```dart
class AnalyticsStats {
  final int totalReviewed;    // all photos reviewed across all sessions
  final int totalKept;        // photos marked keep
  final int totalDeleted;     // photos marked delete
  final int storageSaved;     // bytes freed by deletions
  final List<Session> sessionHistory;   // capped at kMaxSessionHistory (100)
  final List<DailyStat> dailyStats;     // grouped by yyyy-MM-dd, desc
  final List<WeeklyStat> weeklyStats;   // ISO calendar weeks, desc, max 104
}
```

**Example:**
```dart
final result = await analyticsService.getStats();
result.when(
  onSuccess: (stats) {
    print('${stats.totalDeleted} photos deleted');
    print('${formatStorageSize(stats.storageSaved)} freed');
  },
  onFailure: (e) => print('Stats unavailable: ${e.message}'),
);
```

---

## Session lifecycle

Sessions persist after **every single swipe** — not just on app close.

```dart
// 1. Start a session
final sessionResult = await sessionService.startSession();
final session = (sessionResult as Success<Session, AppError>).data;

// 2. Record each swipe immediately
final swipeAction = SwipeAction(
  photoId: photo.id,
  action: SwipeActionType.delete,
  timestamp: DateTime.now().millisecondsSinceEpoch,
);
final updatedResult = await sessionService.recordSwipe(session, swipeAction, photo);
final updatedSession = (updatedResult as Success<Session, AppError>).data;
// updatedSession.deleted is now incremented — already in Supabase

// 3. End the session
await sessionService.endSession(updatedSession);

// 4. Crash recovery — resume a session after an unexpected kill
await sessionService.resumeSession(savedSessionId);
```

---

## Types reference

### Session
```dart
class Session {
  final String id;          // UUID
  final int startedAt;      // unix ms timestamp
  final int? endedAt;       // null if session is still active
  final int reviewed;       // swipes recorded
  final int deleted;        // delete swipes
  final int kept;           // keep swipes
  final int storageSaved;   // bytes (from deleted photo sizes)
}
```

### DailyStat
```dart
class DailyStat {
  final String date;        // 'yyyy-MM-dd'
  final int reviewed;       // sum across all sessions on this date
  final int deleted;
  final int storageSaved;
}
```

### WeeklyStat
```dart
class WeeklyStat {
  final String weekStart;   // 'yyyy-MM-dd' (always a Monday)
  final String weekEnd;     // 'yyyy-MM-dd' (always a Sunday)
  final int totalReviewed;
  final int totalDeleted;
  final int storageSaved;
}
```

### AnalyticsStats.empty()
Returns a zeroed stats object with empty lists. Use when no sessions exist yet.

---

## Supabase tables (owned by Person 3)

### `sessions`
| Column         | Type      | Notes                        |
|----------------|-----------|------------------------------|
| id             | uuid PK   | auto-generated               |
| started_at     | bigint    | unix ms timestamp, not null  |
| ended_at       | bigint    | null while session is active |
| reviewed       | int       | default 0                    |
| deleted        | int       | default 0                    |
| kept           | int       | default 0                    |
| storage_saved  | bigint    | bytes, default 0             |
| created_at     | timestamp | default now()                |

### `swipe_actions`
| Column     | Type   | Notes                              |
|------------|--------|------------------------------------|
| id         | uuid PK| auto-generated                     |
| session_id | uuid FK| → sessions.id, on delete cascade   |
| photo_id   | text   | not null                           |
| action     | text   | check: 'keep' or 'delete'          |
| timestamp  | bigint | unix ms timestamp                  |

Both tables have RLS enabled. Current policy: allow all (tighten with auth).

---

## How to run tests

```bash
# Pure unit tests (no Supabase needed)
flutter test test/analytics/

# Full suite including integration
flutter test test/
```
