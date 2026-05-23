import 'dart:collection';

import 'package:flutter/foundation.dart';

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
  final List<SwipeActionRecord> _history = <SwipeActionRecord>[];

  int _generation = 0;

  List<PhotoModel> get queue => List<PhotoModel>.unmodifiable(_queue);
  List<SwipeActionRecord> get history =>
      List<SwipeActionRecord>.unmodifiable(_history);

  int get generation => _generation;
  int get totalPhotos => _allPhotos.length;
  int get reviewedCount => _history.length;
  int get keptCount =>
      _history.where((record) => record.action == SwipeActionType.keep).length;
  int get deletedCount => _history
      .where((record) => record.action == SwipeActionType.delete)
      .length;
  int get estimatedStorageSavedBytes => _history
      .where((record) => record.action == SwipeActionType.delete)
      .fold<int>(0, (total, record) => total + record.photoSizeBytes);
  int get currentCardIndex => reviewedCount;
  int get remainingCount => _queue.length;
  bool get isCompleted => _queue.isEmpty;
  bool get canUndo => _history.isNotEmpty;

  PhotoModel? get currentPhoto => _queue.isNotEmpty ? _queue.first : null;

  SwipeActionRecord? swipe(SwipeActionType action) {
    if (_queue.isEmpty) {
      return null;
    }

    final photo = _queue.removeAt(0);
    final record = SwipeActionRecord(
      photoId: photo.id,
      action: action,
      timestamp: DateTime.now(),
      photoSizeBytes: photo.fileSizeBytes,
    );
    _history.add(record);
    notifyListeners();
    return record;
  }

  SwipeActionRecord? undo() {
    if (_history.isEmpty) {
      return null;
    }

    final lastAction = _history.removeLast();
    final photo = _allPhotos.firstWhere(
      (item) => item.id == lastAction.photoId,
    );

    if (_queue.isEmpty || _queue.first.id != photo.id) {
      _queue.insert(0, photo);
    }

    notifyListeners();
    return lastAction;
  }

  void restart() {
    _queue
      ..clear()
      ..addAll(_allPhotos);
    _history.clear();
    _generation += 1;
    notifyListeners();
  }
}
