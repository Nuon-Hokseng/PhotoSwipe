# Person 3 — Analytics, AI & Intelligence

## What this system does

Person 3 owns two interconnected systems: an **analytics pipeline** that tracks
every photo review session and computes daily/weekly stats (backed by Supabase),
and an **AI pipeline** that analyses images for blur, duplicates, and screenshots
then turns those signals into ranked, actionable recommendations. Both pipelines
are crash-safe, off-main-thread, and fully covered by tests.

---

## Folder map

```
lib/features/analytics/       Analytics domain
  repositories/               Supabase queries — ONLY place DB is touched
  services/                   Business logic (session, history, aggregation)
  providers/                  ChangeNotifier state for the widget tree

lib/features/ai/              AI domain
  services/                   Blur, screenshot, duplicate, recommendation services
  providers/                  AiProvider — scan state + recommendations
  ai_types.dart               All shared AI types (BlurResult, DuplicateGroup, ...)
  ai_constants.dart           All AI thresholds and limits

lib/features/dashboard/       Dashboard UI (consumes both providers)
  screens/                    DashboardScreen (StatefulWidget, context.watch)
  widgets/                    StatCard, StorageSummary, charts, history list

lib/utils/image_analysis/     Pure Dart math utilities (no Flutter imports)
  blur_scoring.dart           Laplacian kernel → blur score
  hash_utils.dart             Perceptual hash (dHash + aHash)
  similarity_utils.dart       Pairwise comparison, clustering
  clustering_utils.dart       Union-Find
  screenshot_heuristics.dart  Aspect ratio, resolution, UI pattern scoring
  recommendation_scoring.dart Candidate scoring pipeline

lib/shared/types/             Result<T,E>, AppError, PhotoItem, SwipeAction
lib/services/logger/          AppLogger (debug-only, no production output)
lib/services/supabase/        SupabaseClientWrapper singleton
lib/utils/benchmark_utils.dart BenchmarkUtils (debug-only timing)
```

---

## 4 public APIs

| Method | Service | Description |
|--------|---------|-------------|
| `getStats()` | `AnalyticsService` | Returns full `AnalyticsStats` from Supabase |
| `detectBlur(uri)` | `BlurDetectionService` | Returns `BlurResult` for one image |
| `detectDuplicate(photos)` | `DuplicateDetectionService` | Groups similar photos |
| `generateRecommendations(photos)` | `RecommendationService` | Ranked `List<Recommendation>`, max 20 |

All return `Result<T, AppError>` — never throw.

---

## How to start a session and record swipes

```dart
final sessionSvc = AnalyticsModule.sessionService;

// Start
final session = (await sessionSvc.startSession() as Success<Session, AppError>).data;

// Record each swipe immediately (crash-safe persistence)
final swipe = SwipeAction(
  photoId: photo.id,
  action: SwipeActionType.delete,
  timestamp: DateTime.now().millisecondsSinceEpoch,
);
final updated = (await sessionSvc.recordSwipe(session, swipe, photo) as Success<Session, AppError>).data;

// End session
await sessionSvc.endSession(updated);
```

---

## How to run a full AI scan

```dart
// From a widget that has access to AiProvider
final ai = context.read<AiProvider>();
await ai.runFullScan(photos); // emits progress at 0.10 → 0.40 → 0.80 → 1.00

// Watch state
final recommendations = context.watch<AiProvider>().recommendations;
```

---

## How to display stats in a widget

```dart
// In build() — only at screen level, not inside child widgets
final stats = context.watch<AnalyticsProvider>().stats;
if (stats == null) return const ShimmerBox(height: 100);

return StorageSummary(
  storageSavedBytes: stats.storageSaved,
  totalPhotosDeleted: stats.totalDeleted,
  totalPhotosReviewed: stats.totalReviewed,
);
```

---

## Supabase tables owned by Person 3

- `sessions` — one row per cleanup session
- `swipe_actions` — one row per swipe, linked to a session

Both have RLS enabled. See [ANALYTICS_API.md](analytics/ANALYTICS_API.md) for schema.

---

## How to run tests

```bash
# Unit tests (no assets, no Supabase needed)
flutter test test/analytics/
flutter test test/ai/
flutter test test/utils/
flutter test test/dashboard/

# Full suite
flutter test test/

# With verify script
chmod +x scripts/verify_person3.sh && ./scripts/verify_person3.sh
```

---

## Known limitations

| Limitation | Impact | Mitigation |
|-----------|--------|------------|
| O(n²) pairwise comparison | Slow for > 500 photos | Chunked at `kMaxPairwiseComparisonBatch = 500`; cross-chunk near-duplicates missed |
| 5000 photo cap in `generateRecommendations` | First 5000 only | Log warning; increase constant when memory allows |
| AI cache is in-memory only | Lost on app restart | Re-analysis on next scan; acceptable given speed |
| dHash misses cross-chunk near-duplicates | Approximate results for large libraries | Exact duplicates (same hash) are always found via `buildHashIndex` |
| Supabase offline | `getStats()` fails | `AnalyticsProvider` surfaces `AppError.networkUnavailable`; show cached last value |
