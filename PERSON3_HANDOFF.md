# Person 3 Developer Handoff — Analytics, AI & Intelligence

**Owner:** Person 3  
**Domains:** Analytics Pipeline, AI & Recommendation Engine, Dashboard  
**Status:** Complete (8 stages + Android setup)  
**Last Updated:** 2026-05-28

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Core Concepts](#core-concepts)
4. [Services & APIs](#services--apis)
5. [Integration Guide](#integration-guide)
6. [Constants & Configuration](#constants--configuration)
7. [Patterns & Constraints](#patterns--constraints)
8. [Security & Data Handling](#security--data-handling)
9. [Testing](#testing)
10. [Common Tasks](#common-tasks)
11. [Troubleshooting](#troubleshooting)
12. [Performance Notes](#performance-notes)

---

## Overview

Person 3 built two interconnected systems:

### 1. **Analytics Pipeline** — Session & Stats Tracking
Tracks every photo review session and computes daily/weekly stats. Persisted to Supabase.
- **Input:** SwipeAction events (keep/delete per photo)
- **Output:** AnalyticsStats (totals, daily breakdown, weekly breakdown)
- **Guarantees:** Crash-safe, persistent, off-main-thread

### 2. **AI Pipeline** — Image Analysis & Recommendations
Analyzes images for blur, duplicates, screenshots. Ranks actionable cleanup recommendations.
- **Input:** List of PhotoItem with URIs
- **Output:** List<Recommendation> ranked by confidence
- **Guarantees:** Off-main-thread (isolates), in-memory cached, 20-recommendation cap

**Key Feature:** Both pipelines are **crash-safe** (never throw, always return `Result<T, AppError>`) and **observable** (emit progress, state changes via providers).

---

## Architecture

### Layer 1: Repositories (Database Access)
**Location:** `lib/features/analytics/repositories/`

Only place where Supabase is touched. Each repository handles one table:
- `SessionRepository` — CRUD for sessions table
- `SwipeActionRepository` — write swipes, batch read
- `AnalyticsRepository` — facade combining both

**Design:** No async/await chains; all SQLs are single-statement for clarity.

```
Supabase DB
    ↓
Repositories (validated queries)
    ↓
Services (business logic)
```

### Layer 2: Services (Business Logic)
**Location:** `lib/features/analytics/services/` + `lib/features/ai/services/`

Pure Dart, no Flutter imports (except AI services which use `compute()`).

**Analytics Services:**
- `SessionService` — start/end sessions, record swipes
- `HistoryService` — list past sessions
- `DailyAggregationService` — compute daily stats for date range
- `WeeklyAggregationService` — compute weekly stats
- `AnalyticsService` — facade, calls all above via `BenchmarkUtils.measure()`

**AI Services:**
- `BlurDetectionService` — blur scoring (Laplacian kernel)
- `ScreenshotDetectionService` — screenshot heuristics (aspect ratio, resolution, UI patterns)
- `DuplicateDetectionService` — perceptual hashing + clustering
- `RecommendationService` — combines all three, ranks by confidence

**Pattern:** All return `Result<T, AppError>`. Services don't catch exceptions; let them propagate to providers.

### Layer 3: Providers (State & Observation)
**Location:** `lib/features/*/providers/`

`ChangeNotifier` subclasses for reactive state.

- `AnalyticsProvider` — holds `stats`, `isLoading`, `error`; exposes `loadStats()`
- `AiProvider` — holds `recommendations`, `isScanning`, `scanProgress`, `error`; exposes `runFullScan()`

**Pattern:** Providers catch service errors, map to `AppError`, emit state. Widgets use `context.watch()`.

### Layer 4: UI (Widgets)
**Location:** `lib/features/dashboard/`

- `DashboardScreen` — StatefulWidget, calls both providers in `initState`
- `StatCard`, `StorageSummary`, `DailyChart`, `WeeklyChart`, etc. — Stateless display widgets

**Pattern:** Only `DashboardScreen` watches providers; child widgets receive data via constructor params.

### Layer 5: Utilities (Pure Math)
**Location:** `lib/utils/image_analysis/`

No Flutter imports, no side effects. Pure Dart.

- `blur_scoring.dart` — Laplacian kernel → blur score (0.0–1.0)
- `hash_utils.dart` — dHash (primary), aHash (secondary), Hamming distance
- `screenshot_heuristics.dart` — Aspect ratio / resolution / UI pattern scoring
- `similarity_utils.dart` — Pairwise comparison, O(n²) with chunking
- `clustering_utils.dart` — Union-Find with path compression + union by rank
- `recommendation_scoring.dart` — Candidate scoring with weights

**Why pure Dart?** Testable without Flutter context, usable in isolates for `compute()`.

---

## Core Concepts

### 1. Result<T, E> Pattern
**Never throw. Always return Result.**

```dart
sealed class Result<T, E> {
  factory Result.success(T data) => Success(data);
  factory Result.failure(E error) => Failure(error);
  
  R when<R>({
    required R Function(T) onSuccess,
    required R Function(E) onFailure,
  }) => switch (this) { ... };
}
```

**Usage:**
```dart
final result = await service.doSomething();
result.when(
  onSuccess: (data) => print('Success: $data'),
  onFailure: (error) => print('Error: ${error.message}'),
);
```

### 2. AppError Enum
**Location:** `lib/shared/types/app_error.dart`

All possible errors. Each has a `.message` getter.

| Error | Meaning |
|-------|---------|
| `sessionNotFound` | Session ID doesn't exist in DB |
| `statsUnavailable` | No sessions in date range |
| `imageLoadFailed` | Could not decode image bytes |
| `duplicateAnalysisFailed` | Clustering failed |
| `networkUnavailable` | Supabase unreachable |
| `invalidInput` | Bad parameter (e.g., empty photo list) |

### 3. PhotoItem
**Location:** `lib/shared/types/photo.dart`

```dart
class PhotoItem {
  final String id;          // Device photo library ID or app ID
  final String uri;         // file:// or network URL
  final int size;           // bytes
  final int createdAt;      // millisecondsSinceEpoch
}
```

### 4. SwipeAction
**Location:** `lib/shared/types/swipe_action.dart`

```dart
class SwipeAction {
  final String photoId;
  final String action;      // 'keep' or 'delete' only
  final int timestamp;      // millisecondsSinceEpoch
}
```

### 5. Session & AnalyticsStats
**Location:** `lib/features/analytics/analytics_types.dart`

- `Session` — one cleanup session (startedAt, endedAt, counts)
- `DailyStat` — stats for one calendar day
- `WeeklyStat` — stats for one 7-day week (Sun–Sat)
- `AnalyticsStats` — aggregated totals + daily + weekly

### 6. AI Result Types
**Location:** `lib/features/ai/ai_types.dart`

- `BlurResult` → `{ photoId, blurScore, isBlurry }`
- `ScreenshotResult` → `{ photoId, confidence, isScreenshot }`
- `DuplicateGroup` → `{ groupId, photos[], similarity, recommendKeep }`
- `Recommendation` → `{ type, confidence, photoIds, action, explanation }`

### 7. Perceptual Hashing
Two algorithms, complementary:

| Algorithm | Resolution | Use | Strength |
|-----------|-----------|-----|----------|
| **dHash** | 9×8 = 64 bits | Primary duplicate detection | Robust to brightness |
| **aHash** | 8×8 = 64 bits | Secondary/fallback | Robust to contrast |

**Process:**
1. Decode image bytes → RGB
2. Downscale to hash resolution
3. Convert to grayscale (luminance = 0.299R + 0.587G + 0.114B)
4. Compute hash bits
5. Compare: Hamming distance ≤ 8 = duplicate (threshold = 0.92 similarity)

**Edge Case:** Uniform images (any single color) produce `ffffffffffffffff` for aHash because every pixel equals the mean.

### 8. Blur Detection
Laplacian kernel variance:

```
Kernel:    [  0  -1   0 ]
           [ -1   4  -1 ]
           [  0  -1   0 ]
```

**Process:**
1. Decode image → RGB
2. Convert to grayscale
3. Apply Laplacian kernel (edge detection)
4. Compute variance of result
5. Normalize: `1.0 - clamp(variance / 500.0, 0, 1)`
6. Compare against `kBlurThreshold = 0.35`

**Why 500?** Empirically tuned; high-variance images (sharp) → low blur score.

### 9. Screenshot Detection
Three heuristics, weighted:

| Signal | Detection | Weight |
|--------|-----------|--------|
| Aspect Ratio | Common phone ratios (9:16, 3:4, etc.) ±5% | 0.35 |
| Resolution | Common phone resolutions ±10px | 0.45 |
| UI Patterns | Low variance in top 5% or bottom 10% (status/nav bars) | 0.20 |

**Score:** 0.0–1.0. Threshold: `kScreenshotConfidenceThreshold = 0.75`.

### 10. Recommendation Scoring
Combines blur, duplicate, screenshot signals into ranked recommendations:

```
RawCandidate (type, photoId, reason)
    ↓ add confidence scores ↓
ScoredCandidate (score)
    ↓ filter min confidence, cap 20 ↓
Recommendation (type, confidence, photoIds, action, explanation)
```

**Weights (per kAiConstants.dart):**
- Blur: 0.85
- Duplicate: 1.00
- Screenshot: 0.90
- Cluster: 0.75

**Boost:** If deletion rate > 70%, blur weight += 0.10.

---

## Services & APIs

### AnalyticsService
**Returns:** `Result<AnalyticsStats, AppError>`

```dart
final service = AnalyticsModule.analyticsService;

// Get all-time stats
final result = await service.getStats();
result.when(
  onSuccess: (stats) {
    print('Total deleted: ${stats.totalDeleted}');
    print('Daily breakdown: ${stats.dailyStats}');
    print('Weekly breakdown: ${stats.weeklyStats}');
  },
  onFailure: (error) => print('Error: ${error.message}'),
);
```

**What it does:**
1. Calls `SessionRepository.getAll()`
2. Calls `DailyAggregationService.computeAll()`
3. Calls `WeeklyAggregationService.computeAll()`
4. Wraps execution time in `BenchmarkUtils.measure('getStats()', ...)`
5. Returns `AnalyticsStats` with all three

**Performance:** O(n sessions × m days). Cached in memory within a screen session.

---

### SessionService
**Returns:** `Result<Session, AppError>`

```dart
final service = AnalyticsModule.sessionService;

// Start session
final startResult = await service.startSession();
final session = (startResult as Success).data;

// Record a swipe (crash-safe: persists immediately)
final swipeResult = await service.recordSwipe(
  session,
  SwipeAction(photoId: 'p1', action: 'delete', timestamp: now),
  photoItem,
);

// End session
final endResult = await service.endSession(session);
```

**Guarantees:**
- Sessions are immediately persisted to Supabase
- Swipes are persisted one-by-one (crash-safe)
- `recordSwipe()` updates session counts in real time
- If session creation fails, returns `Result.failure(AppError.networkUnavailable)`

---

### BlurDetectionService
**Returns:** `Stream<Result<BlurResult, AppError>>`

```dart
final service = BlurDetectionService();

// Single image
final result = await service.detectBlur('file:///photo.jpg');

// Batch (streaming)
final stream = service.detectBlurBatch([photo1, photo2, photo3]);
await for (final result in stream) {
  result.when(
    onSuccess: (blur) => print('Score: ${blur.blurScore}'),
    onFailure: (error) => print('Failed: ${error.message}'),
  );
}
```

**Details:**
- Uses `compute()` to run Laplacian on background isolate
- Caches results in-memory (LRU, max 5000)
- Streaming API emits results as they complete
- Batch size up to 20 (chunked in `RecommendationService`)

---

### DuplicateDetectionService
**Returns:** `Result<List<DuplicateGroup>, AppError>`

```dart
final service = DuplicateDetectionService();

final result = await service.detectDuplicate([photo1, photo2, ...]);
result.when(
  onSuccess: (groups) {
    for (final group in groups) {
      print('Group ${group.groupId}: ${group.photos.length} photos, similarity ${group.similarity}');
      print('Keep: ${group.recommendKeep}');
    }
  },
  onFailure: (error) => print('Error: ${error.message}'),
);
```

**Algorithm:**
1. Build exact-match hash index (O(n))
2. Group exact matches
3. Chunk remaining by 500, run pairwise O(n²) on each chunk
4. Union-Find clustering
5. Rank best photo per group (largest size → most recent → first)

**Limitation:** Near-duplicates across chunks may be missed; exact duplicates always found.

---

### RecommendationService
**Returns:** `Result<List<Recommendation>, AppError>`

```dart
final service = RecommendationService(
  blurService: BlurDetectionService(),
  screenshotService: ScreenshotDetectionService(),
  duplicateService: DuplicateDetectionService(),
);

// Full scan
final result = await service.generateRecommendations([photo1, photo2, ...]);
result.when(
  onSuccess: (recs) {
    for (final rec in recs) {
      print('${rec.type}: ${rec.confidence.toStringAsFixed(2)} → ${rec.photoIds}');
    }
  },
  onFailure: (error) => print('Error: ${error.message}'),
);

// With stats context (boosts blur if high deletion rate)
final statsResult = await service.generateRecommendationsFromStats(stats, photos);
```

**Details:**
- Cap: 5000 photos (logs warning if exceeded)
- Runs 3 services in parallel via `Future.wait(eagerError: false)`
- Partial failure tolerance: if blur fails but screenshot succeeds, still returns success
- Max 20 recommendations (sorted by confidence descending)
- Min confidence: 0.65 (`kMinRecommendationConfidence`)

---

### AnalyticsProvider
**State:** `ChangeNotifier`

```dart
final provider = context.watch<AnalyticsProvider>();

// Properties
print('Stats: ${provider.stats}');                  // AnalyticsStats?
print('Loading: ${provider.isLoading}');            // bool
print('Error: ${provider.error?.message}');         // AppError?

// Load stats
await provider.loadStats();
```

**Lifecycle:**
1. `loadStats()` sets `isLoading = true`
2. Calls `AnalyticsService.getStats()`
3. On success: `stats = result`, `error = null`
4. On failure: `error = result`, `stats = null`
5. Sets `isLoading = false`, notifies listeners

---

### AiProvider
**State:** `ChangeNotifier`

```dart
final provider = context.watch<AiProvider>();

// Properties
print('Recommendations: ${provider.recommendations}');  // List<Recommendation>
print('Scanning: ${provider.isScanning}');              // bool
print('Progress: ${provider.scanProgress}');            // 0.0–1.0
print('Error: ${provider.error?.message}');             // AppError?

// Start scan
await provider.runFullScan(photos);  // emits checkpoints at 0.10, 0.40, 0.80, 1.00
```

**Lifecycle:**
1. Check double-scan guard: if `isScanning`, return
2. Set `isScanning = true`, `scanProgress = 0.10`, launch futures
3. After `Future.wait` returns: `scanProgress = 0.40`
4. Collect and score results: `scanProgress = 0.80`
5. On completion: `scanProgress = 1.00`, `isScanning = false`, notify listeners
6. On error: `error = result`, recommendations remain from last successful scan

---

## Integration Guide

### For Person 1 (UI/UX):
Person 1 handles `HomeScreen`, `SwipeScreen`, navigation.

**Integration points:**
1. **Start cleanup session:**
   ```dart
   final sessionSvc = AnalyticsModule.sessionService;
   final result = await sessionSvc.startSession();
   // Start SwipeScreen with session
   ```

2. **Record each swipe immediately:**
   ```dart
   final swipeResult = await sessionSvc.recordSwipe(session, swipe, photoItem);
   session = (swipeResult as Success).data; // Update session state
   ```

3. **End session when user exits:**
   ```dart
   await sessionSvc.endSession(session);
   ```

**Do NOT:**
- Call `getStats()` from SwipeScreen — it's O(n) and will block
- Persist sessions yourself; SessionService handles DB
- Throw errors; always handle `Result.when()`

---

### For Person 2 (Photo Library/Storage):
Person 2 handles photo picking, deletion, storage management.

**Integration points:**
1. **Provide PhotoItem with size & createdAt:**
   ```dart
   final photo = PhotoItem(
     id: nativePhotoId,
     uri: 'file://...',
     size: fileSize,
     createdAt: photo.dateTime.millisecondsSinceEpoch,
   );
   ```

2. **Delete photos via recommendations:**
   ```dart
   // Person 3 provides: recommendation.photoIds
   // Person 2 deletes them and reports storage freed
   final (deletedCount, freedBytes) = await deletionService.deletePhotos(recommendation.photoIds);
   ```

3. **Query storage stats:**
   Don't call `AnalyticsService.getStats()` for storage; it's session-based stats, not device storage.

**Do NOT:**
- Ignore recommendation action; it tells you delete vs. keep
- Delete without confirming via recommendation.action == 'delete'

---

### For Person 3 Extensions:
Adding new AI signal? Follow the pattern:

1. **Create utility (pure Dart):** `lib/utils/image_analysis/new_signal.dart`
   ```dart
   double computeNewSignal(Uint8List bytes) { ... }
   ```

2. **Create service:** `lib/features/ai/services/new_service.dart`
   ```dart
   class NewService {
     Future<Result<NewResult, AppError>> detect(String uri) async { ... }
   }
   ```

3. **Add to RecommendationService:**
   ```dart
   final newResult = await newService.detect(photoUri);
   // Fold into recommendations
   ```

4. **Update constants:** `lib/features/ai/ai_constants.dart`
   ```dart
   const double kNewSignalWeight = 0.75;
   const double kNewSignalThreshold = 0.6;
   ```

5. **Add tests:** `test/ai/new_service_test.dart`

---

## Constants & Configuration

### Analytics Constants
**File:** `lib/features/analytics/analytics_constants.dart`

| Constant | Value | Meaning |
|----------|-------|---------|
| `kDateFormat` | `'yyyy-MM-dd'` | Date parsing format |
| `kMaxSessionHistory` | 100 | Max sessions to fetch in history |
| `kWeeklyStatsDays` | 7 | Days per week |
| `kMaxWeeksHistory` | 104 | Max weeks (~2 years) |
| `kLargeSessionListWarningThreshold` | 10000 | Log warning if > N sessions |

### AI Constants
**File:** `lib/features/ai/ai_constants.dart`

| Constant | Value | Meaning |
|----------|-------|---------|
| `kBlurThreshold` | 0.35 | Blur score below this = blurry |
| `kDuplicateSimilarityThreshold` | 0.92 | Similarity >= this = duplicate |
| `kScreenshotConfidenceThreshold` | 0.75 | Confidence >= this = screenshot |
| `kMinRecommendationConfidence` | 0.65 | Min recommendation score |
| `kMaxRecommendations` | 20 | Cap per scan |
| `kMaxPhotosForRecommendation` | 5000 | Input cap (log warning if exceeded) |
| `kMaxPairwiseComparisonBatch` | 500 | Chunk size for duplicate detection |
| `kMaxAiCacheSize` | 5000 | In-memory cache limit (LRU eviction) |
| `kBlurConfidenceWeight` | 0.85 | Scoring weight |
| `kDuplicateConfidenceWeight` | 1.00 | Scoring weight |
| `kScreenshotConfidenceWeight` | 0.90 | Scoring weight |
| `kClusterConfidenceWeight` | 0.75 | Scoring weight |
| `kHighDeletionRateThreshold` | 0.70 | Deletion % above which to boost blur |
| `kBlurWeightBoost` | 0.10 | Amount to boost blur weight |
| `kAiBatchSize` | 20 | Photos per batch in `detectBlurBatch()` |

**Tuning:** All thresholds are empirical. Increase `kBlurThreshold` to catch more blurry photos (less false negatives); decrease to reduce false positives.

---

## Patterns & Constraints

### 1. Never Throw, Always Return Result
```dart
// ❌ BAD
Future<BlurResult> detectBlur(String uri) async {
  final bytes = await _loadImage(uri);  // throws if load fails!
  return computeBlur(bytes);
}

// ✅ GOOD
Future<Result<BlurResult, AppError>> detectBlur(String uri) async {
  try {
    final bytes = await _loadImage(uri);
    return Result.success(computeBlur(bytes));
  } catch (e) {
    return Result.failure(AppError.imageLoadFailed);
  }
}
```

### 2. Isolates for Heavy Computation
```dart
// ❌ BAD (blocks main thread for blur detection)
final result = _analyzeBlur(imageBytes);

// ✅ GOOD (off-main-thread)
final result = await compute(_analyzeBlurIsolate, imageBytes);

// Top-level function (required for compute())
BlurResult _analyzeBlurIsolate(Uint8List bytes) { ... }
```

### 3. Streaming for Large Batches
```dart
// ✅ GOOD (emit as complete, don't wait for all)
Stream<Result<BlurResult, AppError>> detectBlurBatch(List<PhotoItem> photos) async* {
  for (final photo in photos) {
    final result = await detectBlur(photo.uri);
    yield result;
  }
}

// Consumer: process results as they arrive
await for (final result in service.detectBlurBatch(photos)) {
  result.when(onSuccess: (r) => print(r), onFailure: (_) => {});
}
```

### 4. In-Memory Caching with LRU Eviction
```dart
// When cache reaches 5000 items, remove first 500
if (_cache.length >= kMaxAiCacheSize) {
  final keysToRemove = _cache.keys.toList().sublist(0, 500);
  keysToRemove.forEach(_cache.remove);
}
```

### 5. Partial Failure Tolerance
```dart
// Blur fails, but screenshot+duplicate succeed → still return results
final results = await Future.wait([
  blurService.detectBlurBatch(photos).catch((e) => []),
  screenshotService.detectScreenshotBatch(photos).catch((e) => []),
  duplicateService.detectDuplicate(photos).catchError((e) => Result.failure(error)),
], eagerError: false);
// eagerError: false = continue even if one future rejects
```

### 6. Line Limits (from CLAUDE.md)
- **Widget:** ≤ 100 lines
- **Service:** ≤ 150 lines
- **Repository:** ≤ 100 lines
- **Utility:** ≤ 80 lines

Refactor beyond limits; don't comment out code.

### 7. Supabase Anon Key Only
```dart
// ❌ NEVER
const serviceRoleKey = '...';  // Private key = data leak

// ✅ ONLY
const anonKey = '...';  // Public, user-scoped
```

---

## Security & Data Handling

### 1. No Hardcoded Credentials
Credentials loaded from `.env` via `flutter_dotenv`:

```dart
await dotenv.load(fileName: '.env');
final url = dotenv.env['SUPABASE_URL'];
```

`.env` must be in `.gitignore`.

### 2. RLS (Row-Level Security)
All tables have RLS enabled in Supabase. Queries use **anon key** (public scope).

- Users see only their own sessions/swipes
- No cross-user data leakage

### 3. No PII in Logs
`AppLogger` only outputs in debug mode:

```dart
if (kDebugMode) log('User: $userId');  // Safe
// In release: nothing logged
```

### 4. Image Data Never Persisted
Blur/screenshot/duplicate results cached in memory only. Never written to DB.

- Image bytes are not sent to any external service
- Analysis is local only

### 5. Storage Freed Calculation
When a photo is deleted:
- Update session: `session.storageSaved += photo.size`
- Write to `sessions.storage_saved`
- Never delete from DB before deleting file (Person 2 handles file deletion)

---

## Testing

### Unit Tests (No Assets, No Supabase)
```bash
flutter test test/ai/blur_scoring_test.dart
flutter test test/ai/hash_utils_test.dart
flutter test test/ai/screenshot_heuristics_test.dart
flutter test test/ai/similarity_utils_test.dart
flutter test test/utils/clustering_utils_test.dart
flutter test test/analytics/daily_aggregation_service_test.dart
flutter test test/analytics/weekly_aggregation_service_test.dart
flutter test test/utils/format_utils_test.dart
```

### Widget Tests
```bash
flutter test test/dashboard/stat_card_test.dart
flutter test test/dashboard/storage_summary_test.dart
flutter test test/dashboard/cleanup_history_list_test.dart
flutter test test/dashboard/recommendation_card_test.dart
```

### Service Tests (Mocked)
```bash
flutter test test/ai/recommendation_service_test.dart
flutter test test/ai/duplicate_detection_service_test.dart
```

### Integration Tests (Requires Assets/Supabase)
```bash
flutter test test/integration/person3_e2e_test.dart
```

### Full Suite
```bash
flutter test test/
```

### Verification Script
```bash
chmod +x scripts/verify_person3.sh && ./scripts/verify_person3.sh
```

---

## Common Tasks

### Task 1: Add a New Recommendation Type
1. Add to `RecommendationType` enum in `ai_types.dart`
2. Update `RecommendationAction` enum if needed
3. Add scoring function to `recommendation_scoring.dart`
4. Update `generateRecommendations()` in `RecommendationService`
5. Add test cases in `recommendation_service_test.dart`

### Task 2: Increase Blur Threshold
```dart
// In ai_constants.dart
const double kBlurThreshold = 0.40;  // Was 0.35, stricter
```
Result: More photos marked as blurry (fewer false negatives).

### Task 3: Cache a New Service
```dart
class MyService {
  final _cache = <String, MyResult>{};
  
  MyResult? _getCached(String key) => _cache[key];
  
  void _cacheResult(String key, MyResult result) {
    if (_cache.length >= kMaxAiCacheSize) {
      final keys = _cache.keys.toList().sublist(0, 500);
      keys.forEach(_cache.remove);
    }
    _cache[key] = result;
  }
}
```

### Task 4: Modify Recommendation Weights
```dart
// In ai_constants.dart
const double kBlurConfidenceWeight = 0.90;      // Was 0.85
const double kDuplicateConfidenceWeight = 0.95; // Was 1.00

// Recommendations will now weigh blur higher relative to duplicates
```

### Task 5: Add a New Stat to Dashboard
1. Add field to `AnalyticsStats`
2. Compute in `DailyAggregationService` or `WeeklyAggregationService`
3. Create widget in `lib/features/dashboard/widgets/`
4. Use in `DashboardScreen`
5. Add test in `test/dashboard/`

---

## Troubleshooting

### "Supabase offline" Error
**Symptom:** `AppError.networkUnavailable` when calling `getStats()`

**Solution:**
```dart
result.when(
  onSuccess: (stats) => displayStats(stats),
  onFailure: (error) {
    if (error == AppError.networkUnavailable) {
      showDialog('No internet. Using cached stats.');
      displayCachedStats();
    }
  },
);
```

**Root cause:** No internet or Supabase down. Show cached last value in UI.

---

### "Blur score doesn't match expectation"
**Symptom:** Sharp image gets high blur score (expected low)

**Check:**
1. Is the image actually sharp? (visual inspection)
2. What's the Laplacian variance? (Add debug log: `print('Variance: $variance')`)
3. Adjust `kBlurThreshold` upward if too permissive

**Example:** If threshold is 0.35 and your image has variance = 600 (normalized to 0.0), it's marked not blurry (good). If variance = 150 (normalized to 0.70), it's marked blurry.

---

### "Duplicates not detected"
**Symptom:** Near-duplicate photos not grouped

**Reason:**
- Similarity < 0.92? Increase `kDuplicateSimilarityThreshold` to 0.88 (more permissive)
- Photos in different chunks (> 500 apart)? Check logs, near-duplicates across chunks are missed

**Solution:**
```dart
// In ai_constants.dart
const double kDuplicateSimilarityThreshold = 0.88;  // Was 0.92, more permissive
```

---

### "Tests fail with 'was not in the initial set'"
**Symptom:** Union-Find UnionFind error in `clustering_utils_test.dart`

**Fix:** Ensure all photo IDs used in test are in the initial set passed to `UnionFind()`.

```dart
final uf = UnionFind(['p1', 'p2', 'p3']);
uf.union('p1', 'p2');  // ✓ Both in set
uf.union('p1', 'p4');  // ❌ p4 not in set → error
```

---

### "Widget tests fail: context.watch() throws"
**Symptom:** `ProviderNotFoundException` in dashboard tests

**Fix:** Wrap test widget in `MultiProvider`:

```dart
testWidgets('dashboard renders stats', (tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AnalyticsProvider>(
          create: (_) => AnalyticsProvider(...),
        ),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  
  expect(find.byType(StorageSummary), findsOneWidget);
});
```

---

### "Recommendation scores all same"
**Symptom:** All 20 recommendations have confidence 0.65

**Check:**
1. Are all three services returning results? (Logs should show)
2. Are scoring weights calibrated? (See `recommendation_scoring.dart`)
3. Sample raw candidate scores before filtering (add debug log)

**Fix:** Adjust weights or thresholds in `ai_constants.dart`.

---

### "Performance: recommendation scan slow"
**Symptom:** `runFullScan()` takes > 5 seconds for 1000 photos

**Reason:**
- Pairwise comparison O(n²) for duplicates
- Blur detection on main thread? (should use `compute()`)

**Solution:**
1. Cap photos: `const int kMaxPhotosForRecommendation = 3000;` (reduce from 5000)
2. Verify `compute()` is used (check `blur_detection_service.dart`)
3. Increase batch chunk size: `const int kMaxPairwiseComparisonBatch = 1000;` (was 500)

**Trade-off:** Larger chunks = faster but more memory; near-duplicates across chunks missed.

---

## Performance Notes

### Bottlenecks
1. **Blur detection:** O(n) image decoding + Laplacian per photo
   - Mitigation: Batch streaming, `compute()` isolates

2. **Duplicate detection:** O(n²) pairwise comparison
   - Mitigation: Exact match index first, chunk by 500

3. **Weekly aggregation:** O(n sessions × 52 weeks) grouping
   - Mitigation: Caching at provider level

4. **Recommendation scoring:** O(n candidates × weights)
   - Mitigation: Simple computation, not a bottleneck

### Memory Usage
- **Blur cache:** Up to 5000 BlurResult (≈200 bytes each) = ~1 MB
- **Duplicate cache:** Same
- **Recommendation cache:** Single list of 20 items (negligible)
- **Total:** ~2 MB max, safe for mobile

### Caching Strategy
- **Blur/screenshot:** In-memory, persist until cache full (LRU eviction)
- **Duplicates:** In-memory only, per-scan
- **Stats:** In-memory at provider level, persisted to Supabase
- **Recommendations:** Single result, in-memory, cleared on new scan

### Optimization Opportunities (Future)
1. Parallel chunk processing for duplicate detection (multiple isolates)
2. GPU acceleration for Laplacian (using Flutter GPU APIs if available)
3. SQLite for session caching (instead of memory-only)
4. Incremental scans (only new/modified photos, skip cache hits)

---

## File Structure Summary

```
lib/
├── features/
│   ├── analytics/
│   │   ├── repositories/         ← DB access only
│   │   │   ├── analytics_repository.dart
│   │   │   ├── session_repository.dart
│   │   │   └── swipe_action_repository.dart
│   │   ├── services/              ← Business logic
│   │   │   ├── analytics_service.dart
│   │   │   ├── session_service.dart
│   │   │   ├── history_service.dart
│   │   │   ├── daily_aggregation_service.dart
│   │   │   └── weekly_aggregation_service.dart
│   │   ├── providers/             ← State management
│   │   │   ├── analytics_provider.dart
│   │   │   └── analytics_module.dart
│   │   ├── analytics_types.dart
│   │   ├── analytics_constants.dart
│   │   └── ANALYTICS_API.md
│   ├── ai/
│   │   ├── services/              ← AI business logic
│   │   │   ├── blur_detection_service.dart
│   │   │   ├── screenshot_detection_service.dart
│   │   │   ├── duplicate_detection_service.dart
│   │   │   └── recommendation_service.dart
│   │   ├── providers/             ← State management
│   │   │   ├── ai_provider.dart
│   │   │   └── ai_module.dart
│   │   ├── ai_types.dart
│   │   ├── ai_constants.dart
│   │   └── AI_API.md
│   └── dashboard/
│       ├── screens/
│       │   └── dashboard_screen.dart
│       ├── widgets/
│       │   ├── stat_card.dart
│       │   ├── storage_summary.dart
│       │   ├── daily_chart.dart
│       │   ├── weekly_chart.dart
│       │   ├── cleanup_history_list.dart
│       │   └── recommendation_card.dart
├── utils/
│   ├── image_analysis/            ← Pure Dart math
│   │   ├── blur_scoring.dart
│   │   ├── hash_utils.dart
│   │   ├── screenshot_heuristics.dart
│   │   ├── similarity_utils.dart
│   │   ├── clustering_utils.dart
│   │   └── recommendation_scoring.dart
│   ├── benchmark_utils.dart
│   ├── format_utils.dart
│   ├── app_colors.dart
│   └── app_theme.dart
├── shared/
│   ├── types/
│   │   ├── result.dart
│   │   ├── app_error.dart
│   │   ├── photo.dart
│   │   └── swipe_action.dart
│   └── widgets/
│       ├── shimmer_box.dart
│       ├── error_banner.dart
│       └── empty_state.dart
├── services/
│   ├── logger/
│   │   └── app_logger.dart
│   └── supabase/
│       └── supabase_client.dart
├── main.dart
└── lib/screens/ (Person 1/2)

test/
├── ai/
├── analytics/
├── dashboard/
├── utils/
├── integration/
└── widget_test.dart

scripts/
└── verify_person3.sh

supabase/
└── migrations/
    ├── 001_create_sessions.sql
    └── 002_create_swipe_actions.sql
```

---

## Summary for Handoff

**What Person 3 built:**
- Full analytics pipeline: session tracking, daily/weekly stats (Supabase-backed)
- Full AI pipeline: blur, screenshot, duplicate detection, recommendation scoring
- Dashboard UI consuming both pipelines
- Test suite (95+ passing tests)

**What other devs need to know:**
1. Always use `Result<T, AppError>` — never throw
2. Call services via `AnalyticsModule` and `AiModule` singletons
3. Use `context.watch()` to observe provider state in widgets
4. Extend by adding new services (blur/screenshot pattern) and wiring to `RecommendationService`
5. All constants in `*_constants.dart` files — tune thresholds there, not in code

**Contact Person 3 if:**
- You need to add a new AI signal
- Recommendation scores seem off (tune weights)
- Performance bottlenecks appear (cache strategy tweaks)
- Supabase schema changes needed (coordinate schema migrations)

---

**Generated:** 2026-05-28  
**Status:** All 8 stages complete, Android setup done, ready for production testing.
