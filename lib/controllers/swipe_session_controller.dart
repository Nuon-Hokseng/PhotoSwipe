import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/cleanup_session.dart';
import 'analytics_controller.dart';
import '../models/photo_model.dart';
import '../models/swipe_action.dart';
import '../services/cache/thumbnail_cache.dart';
import '../services/gallery/gallery_repository.dart';
import '../services/gallery/gallery_service.dart';
import '../services/queue/queue_service.dart';
import '../services/storage/delete_queue_service.dart';
import '../services/storage/session_persistence_service.dart';
import '../services/storage/storage_service.dart';
import '../shared/models/app_session.dart';
import '../shared/models/photo_item.dart' as models;
import '../shared/models/session_stats.dart';
import '../shared/types/photo.dart';
import '../utils/errors.dart';
import '../utils/storage_formatters.dart';

class SwipeSessionController extends ChangeNotifier {
  SwipeSessionController._();

  static final SwipeSessionController instance = SwipeSessionController._();

  final List<PhotoModel> _allPhotos = <PhotoModel>[];
  final List<PhotoModel> _queue = <PhotoModel>[];
  final List<PhotoItem> _aiPhotos = <PhotoItem>[];
  final AnalyticsController _analytics = AnalyticsController.instance;
  final GalleryService _galleryService = GalleryService();
  final DeleteQueueService _deleteQueueService = DeleteQueueService();
  final SessionPersistenceService _sessionPersistenceService =
      SessionPersistenceService();
  final ThumbnailCache _thumbnailCache = ThumbnailCache();
  final QueueService _queueService = QueueService();
  final StorageService _storageService = StorageService();

  AppError? _loadError;
  bool _isLoading = false;
  int _galleryTotalPhotos = 0;
  int _galleryTotalBytes = 0;
  int _estimatedCleanupBytes = 0;
  int _generation = 0;

  List<PhotoModel> get queue => List<PhotoModel>.unmodifiable(_queue);
  List<CleanupActivity> get history => _analytics.history;

  int get generation => _generation;
  int get galleryTotalPhotos => _galleryTotalPhotos;
  int get galleryTotalBytes => _galleryTotalBytes;
  int get estimatedCleanupBytes => _estimatedCleanupBytes;
  int get totalPhotos => _allPhotos.length;
  List<PhotoModel> get allPhotos => List<PhotoModel>.unmodifiable(_allPhotos);
  int get reviewedCount => _analytics.reviewedCount;
  int get keptCount => _analytics.keptCount;
  int get deletedCount => _analytics.deletedCount;
  int get estimatedStorageSavedBytes => _analytics.storageSavedBytes;
  int get currentCardIndex => reviewedCount;
  int get remainingCount => _queue.length;
  bool get isCompleted => _queue.isEmpty;
  bool get canUndo => _analytics.canUndo;
  bool get isLoading => _isLoading;
  AppError? get loadError => _loadError;

  PhotoModel? get currentPhoto => _queue.isNotEmpty ? _queue.first : null;

  List<PhotoItem> get aiPhotos => List<PhotoItem>.unmodifiable(_aiPhotos);

  Future<void> loadFromDevice() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final stream = _galleryService.streamGallery();
      var firstBatch = true;
      await for (final progress in stream) {
        final raw = progress.photos.last;

        // Store thumbnail in LRU cache; use cached bytes if re-loading same photo.
        if (raw.thumbnailBytes != null) {
          _thumbnailCache.put(raw.id, raw.thumbnailBytes!);
        }
        final cachedBytes = _thumbnailCache.get(raw.id);

        final newPhoto = PhotoModel(
          id: raw.id,
          uri: raw.uri,
          imageBytes: cachedBytes ?? raw.thumbnailBytes,
          imageUrl: null,
          filename: raw.title,
          fileSize: formatStorageBytes(raw.sizeBytes),
          fileSizeBytes: raw.sizeBytes,
          createdAtMillis: raw.createdAt.millisecondsSinceEpoch,
          date: _formatDate(raw.createdAt),
        );
        _allPhotos.add(newPhoto);
        _queue.add(newPhoto);

        _galleryTotalPhotos = progress.totalCount;
        _galleryTotalBytes = progress.totalBytes;
        // Use StorageService for consistent cleanup estimate.
        _estimatedCleanupBytes = _storageService.calculateCleanupEstimate(_allPhotos);

        // Drop loading state after first photo so the swipe UI is usable immediately.
        if (firstBatch) {
          firstBatch = false;
          // Deduplicate on first batch to remove any duplicates that streamed in.
          final deduped = _queueService.deduplicate(_allPhotos);
          _allPhotos
            ..clear()
            ..addAll(deduped);
          _queue
            ..clear()
            ..addAll(_queueService.shuffle(deduped));
          _isLoading = false;
        }
        notifyListeners();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _loadError = const AppError(AppErrorType.galleryEmpty);
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void swipe(SwipeActionType action) {
    if (_queue.isEmpty) {
      return;
    }

    final photo = _queue.removeAt(0);
    if (action == SwipeActionType.delete) {
      _analytics.addDeleteAction(photo);
      // Enqueue to delete queue instead of calling deletePhoto directly.
      _deleteQueueService.enqueue(
        models.PhotoItem(
          id: photo.id,
          uri: photo.uri,
          size: photo.fileSizeBytes,
          createdAt: photo.createdAtMillis,
          width: 0,
          height: 0,
          mimeType: '',
        ),
      );
    } else {
      _analytics.addKeepAction(photo);
    }
    notifyListeners();
  }

  /// Swipe a photo at an arbitrary index in the queue.
  /// This is useful when the UI component reports the index of the
  /// card being swiped (e.g. `CardSwiper`) which may not always be 0.
  void swipeAt(int index, SwipeActionType action) {
    if (index < 0 || index >= _queue.length) {
      return;
    }

    final photo = _queue.removeAt(index);
    if (action == SwipeActionType.delete) {
      _analytics.addDeleteAction(photo);
      // Enqueue to delete queue instead of calling deletePhoto directly.
      _deleteQueueService.enqueue(
        models.PhotoItem(
          id: photo.id,
          uri: photo.uri,
          size: photo.fileSizeBytes,
          createdAt: photo.createdAtMillis,
          width: 0,
          height: 0,
          mimeType: '',
        ),
      );
    } else {
      _analytics.addKeepAction(photo);
    }
    notifyListeners();
  }

  void undo() {
    if (!canUndo) {
      return;
    }

    final lastAction = _analytics.undoLastAction();
    if (lastAction == null) {
      return;
    }

    // Remove from delete queue if the undone action was a delete.
    _deleteQueueService.dequeue(lastAction.photoId);

    final photo = _allPhotos.firstWhere(
      (item) => item.id == lastAction.photoId,
    );

    if (_queue.isEmpty || _queue.first.id != photo.id) {
      _queue.insert(0, photo);
    }

    notifyListeners();
  }

  void restart() {
    // Flush any pending deletes before restarting, then clear persisted session.
    commitDeletes();
    _sessionPersistenceService.clearSession();
    _thumbnailCache.clear();
    final shuffled = _queueService.shuffle(_allPhotos);
    _queue
      ..clear()
      ..addAll(shuffled);
    _analytics.resetSession(totalPhotos: _allPhotos.length);
    _generation += 1;
    notifyListeners();
  }

  /// Flushes all pending deletes to the device gallery.
  Future<void> commitDeletes() async {
    final repo = GalleryRepository();
    await _deleteQueueService.flushDeletes(repo);
  }

  /// Persists the current queue state so it can be restored on next launch.
  Future<void> saveSession() async {
    final remainingIds = _queue.map((p) => p.id).toList();
    final now = DateTime.now();
    final stats = SessionStats(
      totalReviewed: _analytics.reviewedCount,
      totalKept: _analytics.keptCount,
      totalDeleted: _analytics.deletedCount,
      storageSaved: _analytics.storageSavedBytes,
      sessionStart: now.millisecondsSinceEpoch,
      date: _formatDate(now),
    );
    final session = AppSession(
      id: const Uuid().v4(),
      startTime: now.millisecondsSinceEpoch,
      stats: stats,
    );
    await _sessionPersistenceService.saveSession(session, remainingIds);
  }

  /// Restores a previously saved session. Returns true if a session was
  /// restored and the queue was rebuilt from the saved photo ids.
  Future<bool> restoreSession(List<PhotoModel> allPhotos) async {
    final session = await _sessionPersistenceService.restoreSession();
    if (session == null) return false;

    // Rebuild allPhotos list.
    _allPhotos
      ..clear()
      ..addAll(allPhotos);

    // Reset queue to all photos (no partial restore without remaining IDs).
    _queue
      ..clear()
      ..addAll(allPhotos);

    _analytics.resetSession(totalPhotos: allPhotos.length);
    _generation += 1;
    notifyListeners();

    return true;
  }
}
