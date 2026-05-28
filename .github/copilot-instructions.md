Project: PhotoSwipe — AI-Powered Photo Cleanup App
Stack: Flutter (Dart) | Supabase | FastAPI (Python)

Non-Negotiable Rules
Functions

One input → one output → pass to next function. No functions that do multiple jobs.
If a function exists already — use it. Never recreate existing logic.
All async functions return a Result type or use proper error handling — never throw silently.

Layers — never skip
Widget → Provider/Bloc → Service → Repository → Supabase/DB
No Supabase calls in widgets. No business logic in UI. No DB calls outside repositories.
Code Quality

No dynamic type — everything must be typed in Dart.
No magic numbers — all constants go in a constants/ file with a name.
No hardcoded strings — use a constants/strings file.
No duplicate code — if written twice, extract to shared utils immediately.
No print() in production — use a shared logger service.

File Length Limits — split before exceeding
File TypeMax LinesController / Route handler50Service150Repository100Utility80Widget100
Error Handling — Dart
dart// Use a Result type or sealed class pattern
Future<Result<T, AppError>> doSomething() async {
try {
final data = await someOperation();
return Result.success(data);
} catch (e) {
return Result.failure(AppError.unknown);
}
}
Error Handling — Backend (Express or FastAPI)
typescript// Express
async function handler(req, res) {
try {
const data = await service.doSomething()
res.json({ data })
} catch (e) {
res.status(500).json({ error: 'Internal error' })
}
}
python# FastAPI
@router.get("/stats")
async def get_stats():
try:
return await analytics_service.get_stats()
except AppError as e:
raise HTTPException(status_code=400, detail=str(e))
Security

Minimum permissions — request only what is needed, when needed.
No secrets hardcoded — use .env / environment variables.
All Supabase queries go through Row Level Security (RLS) — never bypass it.
Validate all inputs on the backend before any DB operation.

Git Commits
feat(scope): short description
fix(scope): short description
perf(scope): short description
test(scope): short description

Before Writing Any Code

Does this function already exist?
Does each function do exactly one thing?
Are all errors handled explicitly?
Any magic numbers or hardcoded strings?
Does this file exceed its line limit?

# CLAUDE_ARCHITECTURE.md — Structure & Contracts (Load When Planning)

**Stack:** Flutter | Supabase | FastAPI

---

## Flutter App Folder Structure

```
lib/
├── features/
│   ├── dashboard/              # Person 3 — analytics dashboard UI
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── providers/          # or bloc/
│   │   └── dashboard_types.dart
│   ├── analytics/              # Person 3 — stats, session, history
│   │   ├── services/
│   │   ├── repositories/
│   │   └── analytics_types.dart
│   ├── ai/                     # Person 3 — blur, duplicate, screenshot
│   │   ├── services/
│   │   └── ai_types.dart
│   ├── swipe/                  # Person 1 — gesture engine, swipe UI
│   ├── gallery/                # Person 2 — gallery access, permissions
│   ├── queue/                  # Person 2 — photo queue, session state
│   └── delete/                 # Person 2 — delete workflow
│
├── shared/
│   ├── widgets/                # reusable UI components
│   ├── providers/              # shared app-wide state
│   ├── utils/                  # pure Dart utility functions
│   ├── constants/              # all named constants
│   ├── types/                  # shared models agreed by all members
│   └── theme/                  # colors, spacing, text styles
│
├── services/
│   ├── supabase/               # Supabase client abstraction
│   ├── permissions/            # device permission abstraction
│   └── logger/                 # structured logger
│
└── utils/
    ├── analytics/              # Person 3
    ├── image_analysis/         # Person 3
    ├── swipe/                  # Person 1
    └── gallery/                # Person 2
```

---

## Backend Folder Structure

### Express / Node.js

```
backend/
├── src/
│   ├── routes/
│   │   └── analytics.routes.ts
│   ├── controllers/
│   │   └── analytics.controller.ts
│   ├── services/
│   │   └── analytics.service.ts
│   ├── repositories/
│   │   └── analytics.repository.ts
│   ├── middleware/
│   │   ├── auth.ts
│   │   └── validate.ts
│   ├── types/
│   └── config/
│       └── supabase.ts
```

### FastAPI (Python)

```
backend/
├── app/
│   ├── routers/
│   │   └── analytics.py
│   ├── services/
│   │   └── analytics_service.py
│   ├── repositories/
│   │   └── analytics_repository.py
│   ├── models/
│   │   └── analytics.py        # Pydantic models
│   ├── middleware/
│   └── config/
│       └── supabase.py
```

---

## Layer Rules

| Layer         | Can Call             | Cannot Call                   |
| ------------- | -------------------- | ----------------------------- |
| Widget/Screen | Provider/Bloc        | Services, Supabase directly   |
| Provider/Bloc | Services             | UI widgets, Supabase directly |
| Service       | Repository, Utils    | UI, Provider/Bloc             |
| Repository    | Supabase client only | Everything else               |
| Util          | Nothing (pure)       | Side effects                  |

---

## Supabase Rules

- All Supabase calls go inside **Repository files only**.
- Every table must have **Row Level Security (RLS)** enabled.
- Never expose the `service_role` key on the client — Flutter uses `anon` key only.
- Use Supabase **Edge Functions** for any server-side logic that needs the service key.

```dart
// ✅ Repository — only place Supabase is touched
class AnalyticsRepository {
  final SupabaseClient _client;

  Future<List<Session>> getAllSessions() async {
    final response = await _client
        .from('sessions')
        .select()
        .order('started_at', ascending: false);
    return response.map((e) => Session.fromJson(e)).toList();
  }
}

// ❌ Never do this inside a widget or service
Supabase.instance.client.from('sessions').select()
```

---

## Backend Pattern

```
Route (≤30 lines) → Controller (≤50 lines) → Service (≤150 lines) → Repository (≤100 lines) → Supabase
```

```typescript
// Express example
// repository — Supabase queries only
class AnalyticsRepository {
  async getSessions(): Promise<Session[]>;
  async saveSession(session: Session): Promise<void>;
}

// service — business logic only
class AnalyticsService {
  constructor(private repo: AnalyticsRepository) {}
  async getStats(): Promise<AnalyticsStats>;
}

// controller — ≤15 lines per handler
async function handleGetStats(req, res) {
  const result = await analyticsService.getStats();
  res.json(result);
}
```

```python
# FastAPI example
# repository
class AnalyticsRepository:
    async def get_sessions(self) -> list[Session]: ...
    async def save_session(self, session: Session) -> None: ...

# service
class AnalyticsService:
    def __init__(self, repo: AnalyticsRepository): ...
    async def get_stats(self) -> AnalyticsStats: ...

# router handler — short, delegates to service
@router.get("/stats")
async def get_stats(service: AnalyticsService = Depends()):
    return await service.get_stats()
```

---

## Shared Types — Agreed by All Members

```dart
// lib/shared/types/photo.dart
class PhotoItem {
  final String id;
  final String uri;
  final int size;         // bytes
  final int createdAt;    // unix timestamp

  const PhotoItem({
    required this.id,
    required this.uri,
    required this.size,
    required this.createdAt,
  });

  factory PhotoItem.fromJson(Map<String, dynamic> json) => ...
  Map<String, dynamic> toJson() => ...
}

// lib/shared/types/swipe.dart
class SwipeAction {
  final String photoId;
  final String action;    // 'keep' | 'delete'
  final int timestamp;
}
```

---

## Cross-Team API Contracts

| Owner    | Exposed API                                                                    |
| -------- | ------------------------------------------------------------------------------ |
| Person 1 | `getSwipeHistory()`, `getCurrentCard()`                                        |
| Person 2 | `getPhotoMetadata()`, `getDeleteQueue()`, `getTotalStorageUsed()`              |
| Person 3 | `getStats()`, `detectBlur()`, `detectDuplicate()`, `generateRecommendations()` |

```dart
// ✅ Correct — consume their service
final history = await swipeService.getSwipeHistory();

// ❌ Never — reaching into their internals
import 'package:app/features/swipe/stores/swipe_store.dart';
```

---

## Git Branch Rules

```
main          ← protected, PR only
develop       ← integration branch
feature/swipe-engine      ← Person 1
feature/gallery-engine    ← Person 2
feature/analytics-ai      ← Person 3
```

- Work only inside owned folders.
- Shared type changes → team discussion first.
- PR into `develop` only — never push to `main`.
- Never create: `utils.dart`, `helpers.dart`, `constants.dart` at root level.

---

_Return to CLAUDE.md for daily coding rules._\

# CLAUDE_PERSON3.md — Analytics, AI & Intelligence (Load When Coding)

**Stack:** Flutter (Dart) | Supabase | FastAPI
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

| Scenario               | Expected Behavior                             |
| ---------------------- | --------------------------------------------- |
| Empty photo list       | Return `[]`, no crash                         |
| Single photo           | Return empty duplicate groups                 |
| Broken image URI       | Return error result, skip gracefully          |
| Supabase offline       | Return cached local data, show offline banner |
| 0 sessions in DB       | Return zeroed `AnalyticsStats`                |
| Photo missing metadata | Use safe defaults, log warning                |

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

_Extends CLAUDE.md — all base rules still apply._
