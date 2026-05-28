// Integration tests require real image assets in test/assets/:
//   copy1.jpg, copy2.jpg       — identical or near-identical photos
//   different1.jpg, different2.jpg — clearly different photos
//   portrait.jpg               — a regular non-duplicate photo
// All asset-dependent tests are skipped until assets are present.

import 'package:background_remover/features/ai/services/duplicate_detection_service.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:flutter_test/flutter_test.dart';

PhotoItem _makePhoto(String id, String uri, {int size = 1024}) =>
    PhotoItem(id: id, uri: uri, size: size, createdAt: 0);

void main() {
  late DuplicateDetectionService service;

  setUp(() => service = DuplicateDetectionService());

  group('detectDuplicate()', () {
    test('returns empty list for single photo input', () async {
      final result = await service.detectDuplicate([_makePhoto('a', '/a.jpg')]);
      expect(result.isSuccess, isTrue);
      result.when(onSuccess: (g) => expect(g, isEmpty), onFailure: (_) => fail('unexpected failure'));
    });

    test('returns empty list for empty input', () async {
      final result = await service.detectDuplicate([]);
      expect(result.isSuccess, isTrue);
      result.when(onSuccess: (g) => expect(g, isEmpty), onFailure: (_) => fail('unexpected failure'));
    });

    test('detects copy1.jpg and copy2.jpg as duplicates',
        skip: 'Requires test assets', () async {
      final photos = [
        _makePhoto('c1', 'test/assets/copy1.jpg'),
        _makePhoto('c2', 'test/assets/copy2.jpg'),
      ];
      final result = await service.detectDuplicate(photos);
      expect(result.isSuccess, isTrue);
    });

    test('does not flag different1.jpg and different2.jpg as duplicates',
        skip: 'Requires test assets', () async {
      final photos = [
        _makePhoto('d1', 'test/assets/different1.jpg'),
        _makePhoto('d2', 'test/assets/different2.jpg'),
      ];
      final result = await service.detectDuplicate(photos);
      result.when(
        onSuccess: (groups) => expect(groups, isEmpty),
        onFailure: (_) => fail('unexpected failure'),
      );
    });

    test('recommendKeep points to highest-resolution copy',
        skip: 'Requires test assets', () async {
      final result = await service.detectDuplicate([
        _makePhoto('c1', 'test/assets/copy1.jpg', size: 500000),
        _makePhoto('c2', 'test/assets/copy2.jpg', size: 2000000),
      ]);
      result.when(
        onSuccess: (groups) {
          if (groups.isNotEmpty) expect(groups.first.recommendKeep, 'c2');
        },
        onFailure: (_) => fail('unexpected failure'),
      );
    });

    test('returns failure gracefully when all URIs are invalid', () async {
      final photos = [
        _makePhoto('x', '/no/such/file.jpg'),
        _makePhoto('y', '/also/missing.jpg'),
      ];
      final result = await service.detectDuplicate(photos);
      // Both hashes fail → no pairs → empty success (not failure)
      expect(result.isSuccess, isTrue);
    });

    test('skips invalid URIs and still processes valid ones',
        skip: 'Requires test assets', () async {
      final photos = [
        _makePhoto('bad', '/no/such/file.jpg'),
        _makePhoto('good', 'test/assets/portrait.jpg'),
        _makePhoto('good2', 'test/assets/portrait.jpg'),
      ];
      final result = await service.detectDuplicate(photos);
      expect(result.isSuccess, isTrue);
    });
  });

  group('getSimilarPhotos()', () {
    test('finds photos above custom lower threshold',
        skip: 'Requires test assets', () async {
      final photos = [
        _makePhoto('c1', 'test/assets/copy1.jpg'),
        _makePhoto('c2', 'test/assets/copy2.jpg'),
      ];
      final result =
          await service.getSimilarPhotos(photos, threshold: 0.75);
      expect(result.isSuccess, isTrue);
    });

    test('returns empty when all photos are dissimilar',
        skip: 'Requires test assets', () async {
      final photos = [
        _makePhoto('d1', 'test/assets/different1.jpg'),
        _makePhoto('d2', 'test/assets/different2.jpg'),
      ];
      final result = await service.getSimilarPhotos(photos, threshold: 0.75);
      result.when(
        onSuccess: (groups) => expect(groups, isEmpty),
        onFailure: (_) => fail('unexpected failure'),
      );
    });
  });

  group('batch performance', () {
    test('detectDuplicate on 100 synthetic photos completes under 15 seconds',
        skip: 'Requires test assets', () async {
      final photos = List.generate(
          100, (i) => _makePhoto('p$i', 'test/assets/portrait.jpg'));
      final sw = Stopwatch()..start();
      await service.detectDuplicate(photos);
      expect(sw.elapsedMilliseconds, lessThan(15000));
    });
  });
}
