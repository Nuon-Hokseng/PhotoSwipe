# PhotoSwipe — Person 2 Implementation Plan
**Role: Gallery · Storage · Queue · Delete Workflow · Team Architecture**

> Read this before writing a single line of code.
> Your work is the backbone of the entire app — Person 1 and Person 3 both depend on your APIs.

---

## Your Role at a Glance

You own the full data pipeline:

```
Device Storage
     ↓
Gallery Service       ← scan photos, load metadata
     ↓
Queue System          ← randomize, deduplicate, persist
     ↓
[Person 1 Swipe UI]   ← you feed them photos via getNextPhoto()
     ↓
Delete Queue          ← collect "delete" decisions
     ↓
Storage Engine        ← calculate space, execute deletion
     ↓
Performance Layer     ← caching, lazy loading, prefetch
```

You also own **Shared Models** — the contracts every team member codes against.

---

## Your Folder Ownership

```
lib/
 ├── shared/
 │    └── models/
 │         ├── photo_item.dart         ← YOU CREATE THIS FIRST
 │         ├── swipe_action.dart
 │         ├── delete_queue_item.dart
 │         ├── session_stats.dart
 │         └── app_session.dart
 │
 ├── services/
 │    ├── permissions/                 ← gallery permission logic
 │    ├── gallery/                     ← device image scanning
 │    ├── queue/                       ← randomize, dedup, session
 │    ├── storage/                     ← delete queue, deletion, bytes
 │    └── cache/                       ← LRU thumbnail cache
 │
 ├── features/
 │    └── gallery/
 │         └── delete/                 ← delete workflow logic
 │
 ├── state/
 │    └── gallery/                     ← gallery + queue state
 │
 └── utils/
      ├── format_bytes.dart
      └── errors.dart                  ← error types and handling
```

**You do NOT touch:**
- `lib/features/swipe/` (Person 1)
- `lib/widgets/cards/` (Person 1)
- `lib/features/analytics/` (Person 3)
- `lib/features/ai/` (Person 3)

---

## Implementation Phases

Build in this exact order. Each phase unlocks the next one.

---

### Phase 0 — Shared Models (Day 1, MUST DO FIRST)

**Why first:** Person 1 cannot build the swipe card without `PhotoItem`.
Person 3 cannot track stats without `SwipeAction`. Do not skip this.

**Tasks:**
- Create all model files under `lib/shared/models/`
- Define all classes with `fromJson` / `toJson` (see complete code below)
- Share in group chat and get confirmation from Person 1 and Person 3
- Do not modify models after sign-off without notifying both

**Deliverable:** All model files committed and pushed before anyone else starts coding.

```dart
// lib/shared/models/photo_item.dart

class PhotoItem {
  final String id;        // unique ID (photo_manager asset ID)
  final String uri;       // local file path the Image widget can render
  final int size;         // file size in bytes
  final int createdAt;    // Unix timestamp (milliseconds)
  final int width;        // image pixel width
  final int height;       // image pixel height
  final String mimeType;  // e.g. "image/jpeg"

  const PhotoItem({
    required this.id,
    required this.uri,
    required this.size,
    required this.createdAt,
    required this.width,
    required this.height,
    required this.mimeType,
  });

  factory PhotoItem.fromJson(Map<String, dynamic> json) => PhotoItem(
        id: json['id'] as String,
        uri: json['uri'] as String,
        size: json['size'] as int,
        createdAt: json['createdAt'] as int,
        width: json['width'] as int,
        height: json['height'] as int,
        mimeType: json['mimeType'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'uri': uri,
        'size': size,
        'createdAt': createdAt,
        'width': width,
        'height': height,
        'mimeType': mimeType,
      };
}
```

```dart
// lib/shared/models/swipe_action.dart

enum SwipeDecision { keep, delete }

class SwipeAction {
  final String photoId;
  final SwipeDecision action;
  final int timestamp; // when the swipe happened (milliseconds)

  const SwipeAction({
    required this.photoId,
    required this.action,
    required this.timestamp,
  });

  factory SwipeAction.fromJson(Map<String, dynamic> json) => SwipeAction(
        photoId: json['photoId'] as String,
        action: SwipeDecision.values.byName(json['action'] as String),
        timestamp: json['timestamp'] as int,
      );

  Map<String, dynamic> toJson() => {
        'photoId': photoId,
        'action': action.name,
        'timestamp': timestamp,
      };
}
```

```dart
// lib/shared/models/delete_queue_item.dart
import 'photo_item.dart';

class DeleteQueueItem {
  final PhotoItem photo;
  final int queuedAt; // when the user swiped left (milliseconds)

  const DeleteQueueItem({required this.photo, required this.queuedAt});

  factory DeleteQueueItem.fromJson(Map<String, dynamic> json) =>
      DeleteQueueItem(
        photo: PhotoItem.fromJson(json['photo'] as Map<String, dynamic>),
        queuedAt: json['queuedAt'] as int,
      );

  Map<String, dynamic> toJson() => {
        'photo': photo.toJson(),
        'queuedAt': queuedAt,
      };
}
```

```dart
// lib/shared/models/session_stats.dart

class SessionStats {
  final int totalReviewed;
  final int totalKept;
  final int totalDeleted;
  final int storageSaved;   // bytes freed so far this session
  final int sessionStart;   // Unix timestamp (milliseconds)
  final String date;        // 'YYYY-MM-DD' for daily grouping

  const SessionStats({
    required this.totalReviewed,
    required this.totalKept,
    required this.totalDeleted,
    required this.storageSaved,
    required this.sessionStart,
    required this.date,
  });

  factory SessionStats.fromJson(Map<String, dynamic> json) => SessionStats(
        totalReviewed: json['totalReviewed'] as int,
        totalKept: json['totalKept'] as int,
        totalDeleted: json['totalDeleted'] as int,
        storageSaved: json['storageSaved'] as int,
        sessionStart: json['sessionStart'] as int,
        date: json['date'] as String,
      );

  Map<String, dynamic> toJson() => {
        'totalReviewed': totalReviewed,
        'totalKept': totalKept,
        'totalDeleted': totalDeleted,
        'storageSaved': storageSaved,
        'sessionStart': sessionStart,
        'date': date,
      };
}
```

```dart
// lib/shared/models/app_session.dart
import 'delete_queue_item.dart';
import 'session_stats.dart';

class AppSession {
  final int queueIndex;                       // how far through the queue we are
  final List<String> seenIds;                 // IDs already shown to user
  final List<DeleteQueueItem> pendingDeletes;
  final SessionStats stats;
  final int lastUpdated;

  const AppSession({
    required this.queueIndex,
    required this.seenIds,
    required this.pendingDeletes,
    required this.stats,
    required this.lastUpdated,
  });

  factory AppSession.fromJson(Map<String, dynamic> json) => AppSession(
        queueIndex: json['queueIndex'] as int,
        seenIds: List<String>.from(json['seenIds'] as List),
        pendingDeletes: (json['pendingDeletes'] as List)
            .map((e) => DeleteQueueItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        stats: SessionStats.fromJson(json['stats'] as Map<String, dynamic>),
        lastUpdated: json['lastUpdated'] as int,
      );

  Map<String, dynamic> toJson() => {
        'queueIndex': queueIndex,
        'seenIds': seenIds,
        'pendingDeletes': pendingDeletes.map((e) => e.toJson()).toList(),
        'stats': stats.toJson(),
        'lastUpdated': lastUpdated,
      };
}

// Error types
sealed class AppError {}
class PermissionDenied extends AppError {}
class ImageLoadFailed extends AppError { final String photoId; ImageLoadFailed(this.photoId); }
class StorageFull extends AppError {}
class DeleteFailed extends AppError { final List<String> photoIds; DeleteFailed(this.photoIds); }
class GalleryEmpty extends AppError {}

// Permission states
enum PermissionStatus { granted, denied, notAsked, limited }
```

---

### Phase 1 — Gallery Access (Days 2–3)

Build the ability to read the device's photo library.

**Goal:** Given permission, return a list of `PhotoItem` from the device.

**Tasks:**

1. **Permission Service**
   ```
   lib/services/permissions/permission_service.dart
   ```
   - `request()` → asks user for gallery permission, returns `PermissionStatus`
   - `getStatus()` → returns current status without asking
   - Uses `photo_manager`'s `PhotoManager.requestPermissionExtend()`
   - On Android 13+: `READ_MEDIA_IMAGES`; on iOS: `PHPhotoLibrary` authorization

2. **Gallery Service**
   ```
   lib/services/gallery/gallery_service.dart
   ```
   - `getPhotos()` → scans device, returns `List<PhotoItem>` sorted newest-first
   - Use `photo_manager` package
   - Load in pages of 200 to avoid memory spikes on large libraries
   - Filter out non-image assets (videos, documents)

3. **Error handling for this phase:**
   - If permission denied → do NOT crash → return `Left(PermissionDenied())`
   - If gallery is empty → return `Left(GalleryEmpty())`
   - Person 1 will use this to render the correct empty/denied UI screen

**Required package:**
```yaml
# pubspec.yaml
dependencies:
  photo_manager: ^3.0.0
```
```bash
flutter pub add photo_manager
```

**Android — add to `android/app/src/main/AndroidManifest.xml`:**
```xml
<!-- For Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<!-- For Android < 13 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="29" />
```

**iOS — add to `ios/Runner/Info.plist`:**
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>PhotoSwipe needs access to your photos to help you clean up your gallery.</string>
```

**Minimal implementation skeleton:**
```dart
// lib/services/gallery/gallery_service.dart
import 'package:photo_manager/photo_manager.dart';
import '../../shared/models/photo_item.dart';

class GalleryService {
  /// Returns all photos sorted newest-first, or null on permission denial / empty library.
  Future<List<PhotoItem>?> getPhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return null;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true, // "All Photos" album only — avoids duplicates across albums
    );
    if (albums.isEmpty) return null;

    final allAlbum = albums.first;
    final allPhotos = <PhotoItem>[];
    int page = 0;
    const pageSize = 200;

    while (true) {
      final assets = await allAlbum.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      if (assets.isEmpty) break;

      for (final asset in assets) {
        final file = await asset.file;
        allPhotos.add(PhotoItem(
          id: asset.id,
          uri: file?.path ?? '',
          size: asset.size,
          createdAt: asset.createDateTime.millisecondsSinceEpoch,
          width: asset.width,
          height: asset.height,
          mimeType: asset.mimeType ?? 'image/jpeg',
        ));
      }

      if (assets.length < pageSize) break;
      page++;
    }

    if (allPhotos.isEmpty) return null;
    return allPhotos;
  }

  /// Fetch a single photo by its asset ID (used by QueueService on demand).
  Future<PhotoItem?> getPhotoById(String id) async {
    final asset = await AssetEntity.fromId(id);
    if (asset == null) return null;
    final file = await asset.file;
    return PhotoItem(
      id: asset.id,
      uri: file?.path ?? '',
      size: asset.size,
      createdAt: asset.createDateTime.millisecondsSinceEpoch,
      width: asset.width,
      height: asset.height,
      mimeType: asset.mimeType ?? 'image/jpeg',
    );
  }
}
```

**Phase 1 done when:**
- ✅ Can get a list of photos from a real device
- ✅ Permission denial is handled cleanly (no crash)
- ✅ Returns `List<PhotoItem>` in the correct shape

---

### Phase 2 — Photo Queue System (Days 3–4)

Turn the raw photo list into a managed swipe queue.

**Goal:** Person 1 calls `getNextPhoto()` and always gets the next un-seen photo.

**Tasks:**

1. **Shuffle**
   - Fisher-Yates shuffle algorithm on the full photo ID list
   - Store only IDs in the queue (not full objects — saves memory)

2. **Deduplication**
   - Maintain a `Set<String>` of seen photo IDs
   - Before returning from `getNextPhoto()`, verify the ID is not in the seen set

3. **Large dataset handling**
   - Do NOT load 20,000 full `PhotoItem` objects into memory
   - Keep only the shuffled ID list in memory
   - Fetch full `PhotoItem` by ID on demand via `GalleryService.getPhotoById()`

4. **Session persistence**
   - After every swipe, save: current queue index + seen IDs + pending deletes
   - Use `SharedPreferences` for queue index/seen IDs (small, fast)
   - Use `sqflite` for delete queue items (structured, queryable)
   - On app open, check if a saved session exists → restore it

5. **Queue Service APIs:**
   ```dart
   // lib/services/queue/queue_service.dart

   Future<PhotoItem?> getNextPhoto()
   // Returns next unseen photo or null if queue is exhausted

   Future<void> submitAction(SwipeAction action)
   // Records keep/delete decision, advances queue

   Future<SwipeAction?> undoLastAction()
   // Returns and reverses the last action

   Map<String, int> getQueue()
   // { 'total': N, 'remaining': N, 'seen': N }
   // Queue status for Person 1's progress indicator

   Future<void> saveSession()
   // Force-saves current state to persistent storage
   ```

**Skeleton:**
```dart
// lib/services/queue/queue_service.dart
import 'dart:math';
import '../../shared/models/photo_item.dart';
import '../../shared/models/swipe_action.dart';
import '../gallery/gallery_service.dart';
import '../storage/storage_service.dart';

class QueueService {
  final _galleryService = GalleryService();
  final _storageService = StorageService();

  List<String> _shuffledIds = [];
  Set<String> _seenIds = {};
  List<SwipeAction> _history = [];
  int _index = 0;

  Future<void> initialize(List<PhotoItem> photos) async {
    _shuffledIds = _fisherYatesShuffle(photos.map((p) => p.id).toList());
    await _restoreSession();
  }

  Future<PhotoItem?> getNextPhoto() async {
    while (_index < _shuffledIds.length) {
      final id = _shuffledIds[_index];
      if (!_seenIds.contains(id)) {
        return _galleryService.getPhotoById(id);
      }
      _index++;
    }
    return null; // queue exhausted
  }

  Future<void> submitAction(SwipeAction action) async {
    _seenIds.add(action.photoId);
    _history.add(action);
    _index++;
    if (action.action == SwipeDecision.delete) {
      await _storageService.addToDeleteQueue(action.photoId);
    }
    await saveSession();
  }

  Future<SwipeAction?> undoLastAction() async {
    if (_history.isEmpty) return null;
    final last = _history.removeLast();
    _seenIds.remove(last.photoId);
    _index--;
    if (last.action == SwipeDecision.delete) {
      await _storageService.removeFromDeleteQueue(last.photoId);
    }
    await saveSession();
    return last;
  }

  Map<String, int> getQueue() => {
        'total': _shuffledIds.length,
        'seen': _seenIds.length,
        'remaining': _shuffledIds.length - _index,
      };

  Future<void> saveSession() async {
    // Persist _index, _seenIds.toList(), _history to SharedPreferences
  }

  Future<void> _restoreSession() async {
    // Restore _index and _seenIds from SharedPreferences on app open
  }

  List<String> _fisherYatesShuffle(List<String> list) {
    final rng = Random();
    for (int i = list.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list;
  }
}
```

**Phase 2 done when:**
- ✅ Calling `getNextPhoto()` repeatedly never returns the same photo twice
- ✅ App can be killed and re-opened — queue resumes from where it left off
- ✅ Works correctly with 100 photos (test before trying 20,000)

---

### Phase 3 — Delete Workflow (Days 5–6)

You fully own this feature end-to-end. Person 1 only renders your data.

**Goal:** Build the entire delete pipeline. Person 1 calls your APIs — they do not know how deletion works internally.

**How it integrates with Person 1:**

```
Person 1 swipes left
       ↓
QueueService.submitAction(SwipeAction(photoId, SwipeDecision.delete))
       ↓
StorageService.addToDeleteQueue(photoId)     [yours]
       ↓
...user finishes reviewing...
       ↓
Person 1 navigates to Delete Review Screen
       ↓
StorageService.getDeleteQueue()              [yours → Person 1 renders this]
StorageService.getStorageToFree()            [yours → Person 1 shows "238 MB"]
       ↓
User taps "Confirm Delete" in Person 1's UI
       ↓
StorageService.executeDeletion()             [yours]
```

**Tasks:**

1. **Delete Queue Management**
   ```dart
   // lib/services/storage/storage_service.dart

   Future<void> addToDeleteQueue(String photoId)
   Future<void> removeFromDeleteQueue(String photoId)
   Future<List<DeleteQueueItem>> getDeleteQueue()
   ```

2. **Storage Calculation**
   ```dart
   Future<String> getStorageToFree()
   // Returns formatted string: "238 MB", "1.2 GB", "45 KB"
   // Use formatBytes() helper from lib/utils/format_bytes.dart
   ```

3. **Batch Deletion**
   ```dart
   Future<Map<String, List<String>>> executeDeletion()
   // Returns { 'deleted': [...ids], 'failed': [...ids] }
   // Uses photo_manager: PhotoManager.editor.deleteWithIds(ids)
   ```

4. **Restore (pre-deletion undo)**
   ```dart
   Future<void> restorePhoto(String photoId)
   // Removes photo from delete queue (before executeDeletion is called)
   // NOT the same as recovering a file after deletion — that's not required
   ```

**Helper utility:**
```dart
// lib/utils/format_bytes.dart
String formatBytes(int bytes) {
  if (bytes == 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB'];
  final i = (log(bytes) / log(1024)).floor();
  final value = bytes / pow(1024, i);
  return '${value.toStringAsFixed(1)} ${suffixes[i]}';
}
```

**Phase 3 done when:**
- ✅ Delete queue accumulates photos correctly as user swipes left
- ✅ `getStorageToFree()` returns accurate formatted size
- ✅ `executeDeletion()` actually removes files from the device (test on real device!)
- ✅ Person 1 can call all your APIs from their Delete Review Screen

---

### Phase 4 — Storage & Performance Engine (Days 6–8)

Make the app fast enough to handle 5,000–20,000 photos without crashing.

**Goal:** The swipe experience must stay smooth (60fps) even on budget devices.

**The core problem:** Loading 20,000 full-resolution images would use gigabytes of RAM and crash the app. You must only ever keep a handful of images decoded in memory at once.

**Tasks:**

1. **Lazy Loading**
   - Only decode images when needed
   - Pre-decode: current card + next 2 cards (3 images max at full quality)
   - Everything else: load low-res thumbnail only

2. **Thumbnail Cache**
   - Generate compressed thumbnails (e.g. 300×300 JPEG, quality 60%) on first view
   - Store thumbnails on disk (not RAM) in the app's cache directory
   - On subsequent views, load thumbnail instead of full image
   - Use `photo_manager`'s `asset.thumbnailDataWithSize()` for fast generation

3. **LRU Memory Cache**
   ```
   Max 10 full-size decoded images in memory
   When #11 is added → evict the oldest one
   ```

4. **Prefetching**
   - When user is looking at photo #N, start loading #N+1, #N+2, #N+3 in background
   - Cancel prefetch if user swipes faster (avoid wasting IO)

5. **Cache Service API:**
   ```dart
   // lib/services/cache/cache_service.dart

   Future<String?> get(String photoId)
   // Returns cached file path (thumbnail or full) or null if not cached

   Future<void> preload(List<String> photoIds)
   // Background-fetch and cache these photos (non-blocking)

   Future<void> evict(String photoId)
   // Remove from cache (after deletion, to free disk space)

   Future<void> clear()
   // Wipe all cached thumbnails (useful for "reset" feature)
   ```

**Recommended packages for image display and caching:**
```yaml
dependencies:
  cached_network_image: ^3.3.0   # for network URIs if needed
  flutter_cache_manager: ^3.3.1  # disk cache management
  path_provider: ^2.1.0          # access to app cache directory
```
```bash
flutter pub add flutter_cache_manager path_provider
```

Prefer Flutter's built-in `Image.file(File(uri))` for local files — it is fast and memory-efficient. Use `ResizeImage` to limit decoded resolution:
```dart
Image(
  image: ResizeImage(
    FileImage(File(photo.uri)),
    width: 600,   // max decode width — saves RAM
  ),
)
```

**Phase 4 done when:**
- ✅ App handles 10,000 photos in the test dataset without crashing
- ✅ Memory usage stays under 200MB during normal swiping session
- ✅ Swipe transitions feel smooth — no frame drops or loading delays between cards

---

### Phase 5 — Integration & Testing (Days 8–10)

**Tasks:**

1. **Coordinate with Person 1**
   - Walk Person 1 through calling `getNextPhoto()` and `submitAction()`
   - Make sure `getDeleteQueue()` response shape matches what their UI expects
   - Test: swipe 10 photos → check delete queue → confirm deletion → verify files are gone

2. **Coordinate with Person 3**
   - Person 3 needs to listen to swipe events to count analytics
   - Give them access to call `QueueService.submitAction()` as an event they can hook into
   - Or: expose a `Stream<SwipeAction>` they can subscribe to (Flutter-idiomatic)

3. **Edge case testing checklist:**
   - [ ] User has 0 photos → show empty state, no crash
   - [ ] User denies permission → show denial screen, no crash
   - [ ] User swipes all photos without deleting → session ends gracefully
   - [ ] User kills app mid-session → queue restores correctly on re-open
   - [ ] Deletion fails on some photos (e.g. read-only file) → partial success handled
   - [ ] Device storage is full when trying to save session → handled gracefully
   - [ ] User undoes last swipe → previous photo re-appears correctly
   - [ ] Queue with 20,000 photos → no crash, reasonable startup time (< 3s)

4. **Performance benchmark (do this before submission):**
   - Create test dataset: 1,000 / 5,000 / 10,000 / 20,000 photos (or mock data)
   - Measure: startup time, memory at rest, memory after 100 swipes, time to load each photo
   - Document numbers in the report's Performance Optimization section

---

## Complete API Contracts

This is what every other person on your team can expect to call.

```dart
// ─── Permission Service ─────────────────────────────────
Future<PermissionStatus> permissionService.request()
Future<PermissionStatus> permissionService.getStatus()

// ─── Gallery Service ────────────────────────────────────
Future<List<PhotoItem>?> galleryService.getPhotos()
Future<PhotoItem?> galleryService.getPhotoById(String id)

// ─── Queue Service ──────────────────────────────────────
Future<void>           queueService.initialize(List<PhotoItem> photos)
Future<PhotoItem?>     queueService.getNextPhoto()
Future<void>           queueService.submitAction(SwipeAction action)
Future<SwipeAction?>   queueService.undoLastAction()
Map<String, int>       queueService.getQueue()
// Returns { 'total': N, 'remaining': N, 'seen': N }
Future<void>           queueService.saveSession()

// ─── Storage Service ────────────────────────────────────
Future<void>                        storageService.addToDeleteQueue(String photoId)
Future<void>                        storageService.removeFromDeleteQueue(String photoId)
Future<List<DeleteQueueItem>>       storageService.getDeleteQueue()
Future<String>                      storageService.getStorageToFree()
Future<Map<String, List<String>>>   storageService.executeDeletion()
// Returns { 'deleted': [...ids], 'failed': [...ids] }
Future<void>                        storageService.restorePhoto(String photoId)
Future<void>                        storageService.cancelDeletion()

// ─── Cache Service ──────────────────────────────────────
Future<String?>   cacheService.get(String photoId)
Future<void>      cacheService.preload(List<String> photoIds)
Future<void>      cacheService.evict(String photoId)
Future<void>      cacheService.clear()
```

---

## Recommended Packages

| Need | Package | Install |
|---|---|---|
| Gallery access + deletion | `photo_manager` | `flutter pub add photo_manager` |
| Image display (local files) | Built-in `Image.file` + `ResizeImage` | No install needed |
| Disk cache management | `flutter_cache_manager` | `flutter pub add flutter_cache_manager` |
| Local persistence (simple) | `shared_preferences` | `flutter pub add shared_preferences` |
| Local persistence (complex) | `sqflite` | `flutter pub add sqflite` |
| File system access | `path_provider` | `flutter pub add path_provider` |
| State management | `riverpod` or `provider` | `flutter pub add flutter_riverpod` |

**Use SharedPreferences for:** queue index, seen IDs, session stats (small data, fast reads)

**Use sqflite for:** delete queue items, thumbnail cache index (structured data, queryable)

**Use path_provider for:** resolving the app cache directory for thumbnail storage

---

## Report Sections You Write

| Section | What to include |
|---|---|
| System Architecture Diagram | Draw the full data pipeline: Device → Gallery → Queue → Swipe UI → Delete Queue → Deletion |
| Database Design | SharedPreferences keys, sqflite schema for queue + delete queue |
| API Documentation | All your exposed APIs with parameter types and return types |
| Performance Optimization | Lazy loading approach, LRU cache design, `ResizeImage` usage, benchmark numbers |
| Engineering Challenges | What was hard (large dataset memory, session persistence, batch deletion) |
| Personal Contribution | Your specific feature list, commit history highlights |

**You also build and share the APK** — coordinate with team on final build:
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Quick Reference — Build Order

```
Day 1    lib/shared/models/ → all model classes → sign off with team

Day 2    PermissionService → GalleryService (basic scan with photo_manager)

Day 3    QueueService (shuffle + dedup + getNextPhoto)

Day 4    Session persistence (save + restore queue state with SharedPreferences)

Day 5    StorageService (delete queue + getStorageToFree)

Day 6    StorageService.executeDeletion() — test on REAL device

Day 7    CacheService (thumbnails + LRU + prefetch)

Day 8    Performance testing with large dataset

Day 9    Integration with Person 1 (end-to-end swipe → delete flow)

Day 10   Edge case testing + documentation + APK build
```

---

> The most important thing you can do for your team is finish the shared models and `getNextPhoto()` early.
> Person 1 is completely blocked until those two things exist.
