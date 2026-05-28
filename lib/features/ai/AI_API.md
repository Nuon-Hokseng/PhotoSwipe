# AI Service API — Person 3

## Overview

Three detection services + one recommendation engine.
All services return `Result<T, AppError>` — they never throw.
All heavy computation runs off the main thread via `compute()`.
Results are cached in-memory (LRU, max 5000 entries per service).

---

## detectBlur(String uri) → Future<Result<BlurResult, AppError>>

**Service:** `BlurDetectionService`
**Import:** `package:background_remover/features/ai/services/blur_detection_service.dart`

**Parameters:**
- `uri` — absolute file path to the image

**Returns:**
- `Success<BlurResult>` with `{ photoId, blurScore (0.0–1.0), isBlurry }`
- `Failure(AppError.imageLoadFailed)` — file not found or unreadable
- `Failure(AppError.blurAnalysisFailed)` — image processing error

**Example:**
```dart
final result = await blurService.detectBlur('/storage/DCIM/photo.jpg');
result.when(
  onSuccess: (blur) {
    if (blur.isBlurry) print('Delete candidate: score=${blur.blurScore}');
  },
  onFailure: (e) => print('Error: ${e.message}'),
);
```

**Batch:**
```dart
blurService.detectBlurBatch(uris).listen((result) {
  // yields one result per URI as they complete
});
```

---

## detectDuplicate(List<PhotoItem> photos) → Future<Result<List<DuplicateGroup>, AppError>>

**Service:** `DuplicateDetectionService`
**Import:** `package:background_remover/features/ai/services/duplicate_detection_service.dart`

**Parameters:**
- `photos` — list of `PhotoItem` objects; **minimum 2 required**
- Single photo input returns `Result.success([])` immediately

**Returns:**
- `Success<List<DuplicateGroup>>` — groups of similar photos
- `Failure(AppError.duplicateAnalysisFailed)` — processing error

Each `DuplicateGroup`:
- `photos` — all members of the group
- `similarity` — average pairwise similarity (0.0–1.0)
- `recommendKeep` — photoId of the best copy to keep (largest file, most recent)

**Performance:** pairwise comparison is O(n²), chunked at 500 photos max. For libraries > 500 photos, cross-chunk duplicates may be missed.

**Example:**
```dart
final result = await duplicateService.detectDuplicate(photos);
result.when(
  onSuccess: (groups) {
    for (final g in groups) {
      print('Keep ${g.recommendKeep}, delete ${g.photos.length - 1} others');
    }
  },
  onFailure: (e) => print(e.message),
);
```

---

## generateRecommendations(List<PhotoItem> photos) → Future<Result<List<Recommendation>, AppError>>

**Service:** `RecommendationService`
**Import:** `package:background_remover/features/ai/services/recommendation_service.dart`

**Parameters:**
- `photos` — list of `PhotoItem`; empty input returns `Result.success([])` immediately
- Maximum 5000 photos processed; larger libraries are truncated with a warning

**Returns:**
- `Success<List<Recommendation>>` — sorted by confidence descending, max 20 items
- `Failure(AppError.recommendationFailed)` — all three services failed

**Behaviour:**
- Runs blur, screenshot, and duplicate detection **in parallel**
- Tolerates partial failure: if one service fails, the others still contribute
- Confidence threshold: only recommendations above 0.65 are returned

**Confidence weights:**
| Type       | Weight |
|------------|--------|
| duplicate  | 1.00   |
| screenshot | 0.90   |
| blur       | 0.85   |
| cluster    | 0.75   |

**Example:**
```dart
final result = await recommendationService.generateRecommendations(photos);
result.when(
  onSuccess: (recs) {
    for (final r in recs) {
      print('[${r.type.name}] ${r.reason} — ${(r.confidence * 100).round()}%');
    }
  },
  onFailure: (e) => print(e.message),
);
```

---

## Error handling pattern

```dart
final result = await service.someMethod(...);
result.when(
  onSuccess: (data) { /* use data */ },
  onFailure: (error) { /* error is AppError enum with .message getter */ },
);

// Or check inline:
if (result.isSuccess) {
  final data = (result as Success<T, AppError>).data;
}
```

---

## Performance notes

- **Never call** AI services on the main thread — all pixel work runs in isolates
- **Cache** is per-service-instance; create a single instance and reuse it
- **Batch size** for hashing: `kAiBatchSize = 20` photos per isolate call
- **Pairwise limit:** `kMaxPairwiseComparisonBatch = 500` — call on pre-filtered sets only
- **Do not** call `detectBlur()` + `detectDuplicate()` sequentially — use `RecommendationService` which runs them in parallel
