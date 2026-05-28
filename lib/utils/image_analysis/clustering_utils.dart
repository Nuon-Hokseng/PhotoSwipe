/// Union-Find (disjoint set) with path compression and union by rank.
class UnionFind {
  UnionFind(List<String> ids)
      : _parent = {for (final id in ids) id: id},
        _rank = {for (final id in ids) id: 0};

  final Map<String, String> _parent;
  final Map<String, int> _rank;

  /// Returns the root representative of [id]'s group, applying path compression.
  String find(String id) {
    if (!_parent.containsKey(id)) {
      throw ArgumentError('UnionFind: id "$id" was not in the initial set');
    }
    if (_parent[id] != id) _parent[id] = find(_parent[id]!);
    return _parent[id]!;
  }

  /// Merges the groups containing [idA] and [idB]; no-op when idA == idB.
  void union(String idA, String idB) {
    if (idA == idB) return; // explicit self-union guard
    final rootA = find(idA);
    final rootB = find(idB);
    if (rootA == rootB) return;
    final rankA = _rank[rootA]!;
    final rankB = _rank[rootB]!;
    if (rankA < rankB) {
      _parent[rootA] = rootB;
    } else if (rankA > rankB) {
      _parent[rootB] = rootA;
    } else {
      _parent[rootB] = rootA;
      _rank[rootA] = rankA + 1;
    }
  }

  /// Returns defensive copies of all groups with 2+ members.
  Map<String, List<String>> getGroups() {
    if (_parent.isEmpty) return {};
    final groups = <String, List<String>>{};
    for (final id in _parent.keys) {
      groups.putIfAbsent(find(id), () => []).add(id);
    }
    return Map.fromEntries(
      groups.entries
          .where((e) => e.value.length >= 2)
          .map((e) => MapEntry(e.key, List<String>.from(e.value))),
    );
  }
}
