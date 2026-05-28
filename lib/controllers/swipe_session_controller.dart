import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/cleanup_session.dart';
import 'analytics_controller.dart';
import '../models/photo_model.dart';
import '../models/swipe_action.dart';

class SwipeSessionController extends ChangeNotifier {
  SwipeSessionController._()
    : _allPhotos = List<PhotoModel>.unmodifiable(
        LinkedHashMap<String, PhotoModel>.fromEntries(
          PhotoModel.mockPhotos.map((photo) => MapEntry(photo.id, photo)),
        ).values,
      ) {
    restart();
  }

  static final SwipeSessionController instance = SwipeSessionController._();

  final List<PhotoModel> _allPhotos;
  final List<PhotoModel> _queue = <PhotoModel>[];
  final AnalyticsController _analytics = AnalyticsController.instance;

  int _generation = 0;

  List<PhotoModel> get queue => List<PhotoModel>.unmodifiable(_queue);
  List<CleanupActivity> get history => _analytics.history;

  int get generation => _generation;
  int get totalPhotos => _allPhotos.length;
  int get reviewedCount => _analytics.reviewedCount;
  int get keptCount => _analytics.keptCount;
  int get deletedCount => _analytics.deletedCount;
  int get estimatedStorageSavedBytes => _analytics.storageSavedBytes;
  int get currentCardIndex => reviewedCount;
  int get remainingCount => _queue.length;
  bool get isCompleted => _queue.isEmpty;
  bool get canUndo => _analytics.canUndo;

  PhotoModel? get currentPhoto => _queue.isNotEmpty ? _queue.first : null;

  void swipe(SwipeActionType action) {
    if (_queue.isEmpty) {
      return;
    }

    final photo = _queue.removeAt(0);
    if (action == SwipeActionType.delete) {
      _analytics.addDeleteAction(photo);
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

    final photo = _allPhotos.firstWhere(
      (item) => item.id == lastAction.photoId,
    );

    if (_queue.isEmpty || _queue.first.id != photo.id) {
      _queue.insert(0, photo);
    }

    notifyListeners();
  }

  void restart() {
    _queue
      ..clear()
      ..addAll(_allPhotos);
    _analytics.resetSession(totalPhotos: _allPhotos.length);
    _generation += 1;
    notifyListeners();
  }
}
