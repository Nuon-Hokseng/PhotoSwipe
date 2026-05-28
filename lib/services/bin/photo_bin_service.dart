import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../services/gallery/gallery_repository.dart';
import '../../services/logger/app_logger.dart';
import '../../shared/models/bin_item.dart';

class PhotoBinService {
  static const _tag = 'PhotoBinService';
  static const _prefsKey = 'photoswipe_bin';

  final List<BinItem> _items = [];

  /// Load persisted bin items from SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((e) => BinItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _items
          ..clear()
          ..addAll(list);
        AppLogger.info(_tag, 'Loaded ${_items.length} bin items from prefs');
      }
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
    }
  }

  /// Add a single item to the bin and persist.
  Future<void> addToBin(BinItem item) async {
    // Avoid duplicates
    _items.removeWhere((i) => i.photoId == item.photoId);
    _items.add(item);
    await _persist();
    AppLogger.info(_tag, 'Added ${item.filename} to bin (reason: ${item.reason})');
  }

  /// Bulk-add items to the bin and persist once.
  Future<void> addAllToBin(List<BinItem> items) async {
    for (final item in items) {
      _items.removeWhere((i) => i.photoId == item.photoId);
      _items.add(item);
    }
    await _persist();
    AppLogger.info(_tag, 'Bulk-added ${items.length} items to bin');
  }

  /// Remove an item from the bin (photo remains on device).
  Future<void> restoreFromBin(String photoId) async {
    final before = _items.length;
    _items.removeWhere((i) => i.photoId == photoId);
    if (_items.length < before) {
      await _persist();
      AppLogger.info(_tag, 'Restored $photoId from bin');
    }
  }

  /// All current bin items.
  List<BinItem> getBinItems() => List<BinItem>.unmodifiable(_items);

  /// Items whose expiry timestamp is in the past.
  List<BinItem> getExpiredItems() =>
      _items.where((i) => i.isExpired).toList();

  /// Permanently delete expired items via [GalleryRepository], then remove
  /// them from the bin. Returns the number of items deleted.
  Future<int> purgeExpired(GalleryRepository repo) async {
    final expired = getExpiredItems();
    if (expired.isEmpty) return 0;

    final ids = expired.map((i) => i.photoId).toList();
    final result = await repo.deletePhotos(ids);
    final count = result.when(
      onSuccess: (_) => ids.length,
      onFailure: (err) {
        AppLogger.error(_tag, 'purgeExpired deletePhotos failed');
        return 0;
      },
    );

    if (count > 0) {
      _items.removeWhere((i) => ids.contains(i.photoId));
      await _persist();
      AppLogger.info(_tag, 'Purged $count expired items from bin');
    }
    return count;
  }

  /// Total size in bytes of all bin items.
  int get totalSizeBytes =>
      _items.fold(0, (sum, i) => sum + i.fileSizeBytes);

  /// Number of items in the bin.
  int get count => _items.length;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.map((i) => i.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
    }
  }
}
