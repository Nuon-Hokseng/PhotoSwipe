import 'dart:collection';
import 'dart:typed_data';

import '../../constants/gallery_constants.dart';

class ThumbnailCache {
  final LinkedHashMap<String, Uint8List> _cache =
      LinkedHashMap<String, Uint8List>();

  Uint8List? get(String id) {
    final bytes = _cache.remove(id);
    if (bytes == null) return null;
    // Re-insert to mark as most recently used.
    _cache[id] = bytes;
    return bytes;
  }

  void put(String id, Uint8List bytes) {
    // Remove first to reset insertion order if already present.
    _cache.remove(id);
    _cache[id] = bytes;
    // Evict oldest entries when over capacity.
    while (_cache.length > kThumbnailCacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  void evict(String id) {
    _cache.remove(id);
  }

  void clear() {
    _cache.clear();
  }

  int get size => _cache.length;
}
