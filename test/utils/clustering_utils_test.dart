import 'package:background_remover/utils/image_analysis/clustering_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnionFind', () {
    test('each id starts in its own group', () {
      final uf = UnionFind(['a', 'b', 'c']);
      expect(uf.find('a'), 'a');
      expect(uf.find('b'), 'b');
      expect(uf.find('c'), 'c');
    });

    test('union merges two groups correctly', () {
      final uf = UnionFind(['a', 'b', 'c']);
      uf.union('a', 'b');
      expect(uf.find('a'), uf.find('b'));
      expect(uf.find('c'), 'c'); // unaffected
    });

    test('find returns root after multiple unions', () {
      final uf = UnionFind(['a', 'b', 'c', 'd']);
      uf.union('a', 'b');
      uf.union('c', 'd');
      uf.union('b', 'c');
      final root = uf.find('a');
      expect(uf.find('b'), root);
      expect(uf.find('c'), root);
      expect(uf.find('d'), root);
    });

    test('path compression: find is consistent after compression', () {
      final uf = UnionFind(['a', 'b', 'c', 'd', 'e']);
      uf.union('a', 'b');
      uf.union('b', 'c');
      uf.union('c', 'd');
      uf.union('d', 'e');
      final root = uf.find('a');
      // After find(), path is compressed — all should return same root
      expect(uf.find('b'), root);
      expect(uf.find('c'), root);
      expect(uf.find('e'), root);
    });

    test('union by rank keeps tree shallow', () {
      final uf = UnionFind(['a', 'b', 'c', 'd']);
      uf.union('a', 'b');
      uf.union('c', 'd');
      uf.union('a', 'c'); // merges two rank-1 trees
      final root = uf.find('a');
      // All four should share one root
      expect(uf.find('b'), root);
      expect(uf.find('c'), root);
      expect(uf.find('d'), root);
    });

    test('getGroups returns only groups with 2+ members', () {
      final uf = UnionFind(['a', 'b', 'c']);
      uf.union('a', 'b');
      final groups = uf.getGroups();
      expect(groups.length, 1); // only {a,b}; c is alone
      expect(groups.values.first.toSet(), {'a', 'b'});
    });

    test('find on unknown id throws ArgumentError', () {
      final uf = UnionFind(['a', 'b']);
      expect(() => uf.find('z'), throwsArgumentError);
    });

    group('transitive grouping', () {
      test('A-B union + B-C union → A,B,C in same group', () {
        final uf = UnionFind(['A', 'B', 'C']);
        uf.union('A', 'B');
        uf.union('B', 'C');
        expect(uf.find('A'), uf.find('C'));
      });

      test('A-B union + C-D union → two separate groups', () {
        final uf = UnionFind(['A', 'B', 'C', 'D']);
        uf.union('A', 'B');
        uf.union('C', 'D');
        expect(uf.find('A'), isNot(equals(uf.find('C'))));
        expect(uf.getGroups().length, 2);
      });

      test('5 items all unioned → one group of 5', () {
        final uf = UnionFind(['1', '2', '3', '4', '5']);
        uf.union('1', '2');
        uf.union('2', '3');
        uf.union('3', '4');
        uf.union('4', '5');
        final groups = uf.getGroups();
        expect(groups.length, 1);
        expect(groups.values.first.length, 5);
      });
    });
  });
}
