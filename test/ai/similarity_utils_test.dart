import 'package:background_remover/shared/types/photo.dart';
import 'package:background_remover/utils/image_analysis/similarity_utils.dart';
import 'package:flutter_test/flutter_test.dart';

PhotoItem _makePhoto({required String id, int size = 1000, int createdAt = 0}) =>
    PhotoItem(id: id, uri: '/fake/$id.jpg', size: size, createdAt: createdAt);

void main() {
  group('buildHashIndex()', () {
    test('groups photos with identical hashes under one key', () {
      final index = buildHashIndex({'a': 'hash1', 'b': 'hash1', 'c': 'hash2'});
      expect(index['hash1']?.length, 2);
      expect(index['hash2']?.length, 1);
    });

    test('photos with unique hashes each get their own key', () {
      final index = buildHashIndex({'a': 'h1', 'b': 'h2', 'c': 'h3'});
      expect(index.length, 3);
    });

    test('empty input → empty map', () {
      expect(buildHashIndex({}), isEmpty);
    });
  });

  group('findSimilarPairs()', () {
    // Two hashes identical → similarity 1.0 ≥ any threshold
    const identical = {'a': 'aaaaaaaaaaaaaaaa', 'b': 'aaaaaaaaaaaaaaaa'};
    const different = {'a': 'ffffffffffffffff', 'b': '0000000000000000'};

    test('returns empty list when fewer than 2 photos', () {
      expect(findSimilarPairs({'a': 'aaaa'}, 0.5), isEmpty);
      expect(findSimilarPairs({}, 0.5), isEmpty);
    });

    test('returns empty list when no photos exceed threshold', () {
      expect(findSimilarPairs(different, 0.99), isEmpty);
    });

    test('finds pair when similarity >= threshold', () {
      final pairs = findSimilarPairs(identical, 0.5);
      expect(pairs.length, 1);
      expect(pairs.first.similarity, 1.0);
    });

    test('does not return duplicate pairs (A,B and B,A)', () {
      final pairs = findSimilarPairs(identical, 0.5);
      final ids = pairs.map((p) => '${p.photoIdA}:${p.photoIdB}').toSet();
      expect(ids.length, pairs.length); // no duplicates
    });

    test('sorts result by similarity descending', () {
      // Two pairs: one with sim=1.0, one with intermediate sim
      final hashMap = {
        'a': 'aaaaaaaaaaaaaaaa',
        'b': 'aaaaaaaaaaaaaaaa',
        'c': 'aaaaaaaaffff0000', // fewer matching bits with a/b
      };
      final pairs = findSimilarPairs(hashMap, 0.0);
      for (var i = 0; i < pairs.length - 1; i++) {
        expect(pairs[i].similarity,
            greaterThanOrEqualTo(pairs[i + 1].similarity));
      }
    });
  });

  group('groupIntoClusters() via UnionFind', () {
    test('A~B and B~C → one cluster {A, B, C}', () {
      final pairs = [
        SimilarPair(photoIdA: 'A', photoIdB: 'B', similarity: 1.0),
        SimilarPair(photoIdA: 'B', photoIdB: 'C', similarity: 1.0),
      ];
      final clusters = groupIntoClusters(pairs);
      expect(clusters.length, 1);
      expect(clusters.first.toSet(), {'A', 'B', 'C'});
    });

    test('A~B and C~D → two clusters', () {
      final pairs = [
        SimilarPair(photoIdA: 'A', photoIdB: 'B', similarity: 1.0),
        SimilarPair(photoIdA: 'C', photoIdB: 'D', similarity: 1.0),
      ];
      expect(groupIntoClusters(pairs).length, 2);
    });

    test('no similar pairs → empty list', () {
      expect(groupIntoClusters([]), isEmpty);
    });

    test('single photo with no pairs → excluded from clusters', () {
      // Only (A,B) pair — C is alone and excluded
      final pairs = [
        SimilarPair(photoIdA: 'A', photoIdB: 'B', similarity: 1.0),
      ];
      final clusters = groupIntoClusters(pairs);
      final allIds = clusters.expand((c) => c).toSet();
      expect(allIds.contains('C'), isFalse);
    });
  });

  group('rankBestInGroup()', () {
    test('picks photo with largest file size', () {
      final photoMap = {
        'a': _makePhoto(id: 'a', size: 500),
        'b': _makePhoto(id: 'b', size: 2000),
        'c': _makePhoto(id: 'c', size: 1000),
      };
      expect(rankBestInGroup(['a', 'b', 'c'], photoMap), 'b');
    });

    test('picks most recent when sizes are equal', () {
      final photoMap = {
        'a': _makePhoto(id: 'a', size: 1000, createdAt: 100),
        'b': _makePhoto(id: 'b', size: 1000, createdAt: 200),
      };
      expect(rankBestInGroup(['a', 'b'], photoMap), 'b');
    });

    test('returns stable fallback when all metadata is identical', () {
      final photoMap = {
        'a': _makePhoto(id: 'a'),
        'b': _makePhoto(id: 'b'),
      };
      expect(['a', 'b'], contains(rankBestInGroup(['a', 'b'], photoMap)));
    });

    test('throws ArgumentError on empty cluster', () {
      expect(() => rankBestInGroup([], {}), throwsArgumentError);
    });

    test('skips photoId not found in photoMap', () {
      final photoMap = {'a': _makePhoto(id: 'a', size: 500)};
      // 'missing' is not in photoMap — should still return 'a'
      expect(rankBestInGroup(['missing', 'a'], photoMap), 'a');
    });
  });
}
