# CLAUDE_PERSON3.md — Analytics, AI & Intelligence (Load When Coding)

**Stack:** Flutter (Dart) | Supabase | Express or FastAPI
**Branch:** `feature/analytics-ai`

---

## Owned Folders

```
lib/features/dashboard/
lib/features/analytics/
lib/features/ai/
lib/utils/image_analysis/
tests/
```

**Never touch:** `swipe/`, `gallery/`, `queue/`, `delete/`
**Cross-team:** consume exposed service APIs only — never import their internal files.

---

## My Public API Contracts

```dart
Future<AnalyticsStats> getStats();
Future<BlurResult> detectBlur(String uri);
Future<List<DuplicateGroup>> detectDuplicate(List<PhotoItem> photos);
Future<List<Recommendation>> generateRecommendations(AnalyticsStats stats);
```

---

## My Types

```dart
// lib/features/analytics/analytics_types.dart

class AnalyticsStats {
  final int totalReviewed;
  final int totalKept;
  final int totalDeleted;
  final int storageSaved;       // bytes
  final List<Session> sessionHistory;
  final List<DailyStat> dailyStats;
  final List<WeeklyStat> weeklyStats;
}

class Session {
  final String id;
  final int startedAt;          // unix timestamp
  final int endedAt;
  final int reviewed;
  final int deleted;
  final int kept;
  final int storageSaved;
}

class DailyStat {
  final String date;            // 'YYYY-MM-DD'
  final int reviewed;
  final int deleted;
  final int storageSaved;
}

class WeeklyStat {
  final String weekStart;
  final String weekEnd;
  final int totalReviewed;
  final int totalDeleted;
  final int storageSaved;
}

// lib/features/ai/ai_types.dart

class BlurResult {
  final String photoId;
  final double blurScore;       // 0.0 (sharp) → 1.0 (blurry)
  final bool isBlurry;
}

class DuplicateGroup {
  final String groupId;
  final List<PhotoItem> photos;
  final double similarity;      // 0.0 → 1.0
  final String recommendKeep;  // photoId of best copy
}

class Recommendation {
  final String type;            // 'blur' | 'duplicate' | 'screenshot' | 'cluster'
  final List<String> photoIds;
  final String reason;
  final double confidence;      // 0.0 → 1.0
  final String action;          // 'delete' | 'review'
}
```

---

## Supabase Tables (Person 3 owns these)

```sql
-- sessions
create table sessions (
  id uuid primary key default gen_random_uuid(),
  started_at bigint not null,
  ended_at bigint,
  reviewed int default 0,
  deleted int default 0,
  kept int default 0,
  storage_saved bigint default 0,
  created_at timestamp default now()
);

-- swipe_actions
create table swipe_actions (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references sessions(id),
  photo_id text not null,
  action text check (action in ('keep','delete')),
  timestamp bigint not null
);

-- Enable RLS on both tables
alter table sessions enable row level security;
alter table swipe_actions enable row level security;
```

Repository wraps all Supabase queries — no widget or service touches Supabase directly.

```dart
// lib/features/analytics/repositories/analytics_repository.dart
class AnalyticsRepository {
  final SupabaseClient _client;

  Future<List<Session>> getAllSessions() async {
    final data = await _client
        .from('sessions')
        .select()
        .order('started_at', ascending: false);
    return data.map((e) => Session.fromJson(e)).toList();
  }

  Future<void> saveSession(Session session) async {
    await _client.from('sessions').upsert(session.toJson());
  }
}
```

---

## AI Pipelines

### Blur Detection
```
uri → loadImagePixels() → applyLaplacianKernel() → computeVariance() → BlurResult
```
```dart
// lib/utils/image_analysis/blur_scoring.dart
const double kBlurThreshold = 0.35;

double computeBlurScore(List<int> pixels) { ... }
bool isBlurry(double score) => score > kBlurThreshold;
```

### Duplicate Detection
```
List<PhotoItem> → computePerceptualHash() → buildHashIndex() → findSimilarPairs() → List<DuplicateGroup>
```
```dart
// lib/utils/image_analysis/hash_utils.dart
const double kDuplicateSimilarityThreshold = 0.92;

Future<String> computePerceptualHash(String uri) async { ... }
double computeSimilarity(String hashA, String hashB) { ... }
bool areDuplicates(double similarity) => similarity >= kDuplicateSimilarityThreshold;
```

### Screenshot Detection
```
PhotoItem → checkAspectRatio() → checkDPI() → checkResolution() → double score → bool
```
```dart
// lib/utils/image_analysis/screenshot_heuristics.dart
const double kScreenshotConfidenceThreshold = 0.75;

double scoreScreenshotLikelihood(ScreenshotSignals signals) { ... }
bool isScreenshot(double score) => score >= kScreenshotConfidenceThreshold;
```

### Recommendation Engine
```
stats + AI results → collectCandidates() → scoreByConfidence() → rankRecommendations() → List<Recommendation>
```
```dart
const int kMaxRecommendations = 20;
const double kMinRecommendationConfidence = 0.65;
```

---

## Analytics Rules

- Sessions persist **after every swipe** — not on app close. Crash recovery required.
- `getStats()` always reads from Supabase — never from in-memory state.
- Stats pipeline:
```dart
// SwipeAction[] → groupByDate() → computeDailyStats() → aggregateWeeklyStats() → AnalyticsStats
```

---

## Dashboard UI Rules (Flutter)

- Use `fl_chart` or `syncfusion_flutter_charts` for charts — no manual Canvas hacks.
- Widgets receive **pre-computed display data only** — zero logic inside `build()`.
- Every chart must have a loading skeleton (`Shimmer`) and an empty state widget.

```dart
// ✅
DailyChart(data: dailyStats)
WeeklyChart(data: weeklyStats)
StorageSummaryCard(saved: storageSaved)

// ❌ — compute before passing, not inside widget
DailyChart(sessions: rawSessions)
```

```dart
// StatCard — one card, one metric
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final TrendDirection? trend;  // up | down | neutral
}
```

---

## Performance — AI on 20k Photos

Never run AI analysis on the main thread. Use Dart `Isolate` or `compute()`.

```dart
const int kAiBatchSize = 20;

Future<List<BlurResult>> analyzePhotos(List<PhotoItem> photos) async {
  final results = <BlurResult>[];
  final batches = chunk(photos, kAiBatchSize);

  for (final batch in batches) {
    // Run in isolate to avoid UI jank
    final batchResults = await compute(_processBatch, batch);
    results.addAll(batchResults);
  }
  return results;
}

// Top-level function required for compute()
List<BlurResult> _processBatch(List<PhotoItem> batch) {
  return batch.map((p) => runBlurDetection(p)).toList();
}
```

- AI runs **after** swipe queue is ready — never blocks initial load.
- Cache results by photo ID — never re-analyze the same photo.
- Show `LinearProgressIndicator` during analysis — no silent waiting.

---

## Edge Cases — Always Handle

| Scenario | Expected Behavior |
|---|---|
| Empty photo list | Return `[]`, no crash |
| Single photo | Return empty duplicate groups |
| Broken image URI | Return error result, skip gracefully |
| Supabase offline | Return cached local data, show offline banner |
| 0 sessions in DB | Return zeroed `AnalyticsStats` |
| Photo missing metadata | Use safe defaults, log warning |

---

## Testing

```dart
// test/ai/blur_detection_test.dart
void main() {
  group('Blur Detection', () {
    test('returns high score for blurry image', () { ... });
    test('returns low score for sharp image', () { ... });
    test('flags images above kBlurThreshold', () { ... });
    test('handles corrupt URI gracefully', () { ... });
  });
}

// test/analytics/analytics_service_test.dart
void main() {
  group('Analytics Service', () {
    test('getStats returns zeroed stats when no sessions exist', () { ... });
    test('session persists after each swipe', () { ... });
    test('daily stats grouped correctly by date', () { ... });
  });
}
```

---

## My Pre-Commit Checklist

- [ ] No `dynamic` types — everything is typed in Dart
- [ ] Every threshold is a named constant with `k` prefix (`kBlurThreshold`)
- [ ] AI processing uses `compute()` or `Isolate` — never runs on main thread
- [ ] All chart widgets receive pre-computed data only
- [ ] All 4 public APIs match agreed contracts
- [ ] Supabase queries are only inside Repository files
- [ ] RLS is enabled on my Supabase tables
- [ ] Edge cases handled — empty list, broken URI, offline, zero sessions
- [ ] Sessions persist after every swipe — not just on app close
- [ ] No imports from Person 1 or Person 2 internal folders

---

*Extends CLAUDE.md — all base rules still apply.*