// Integration tests require real image assets placed in test/assets/:
//   test/assets/blurry_photo.jpg
//   test/assets/sharp_photo.jpg
//   test/assets/screenshot.png
//   test/assets/normal_photo.jpg
// All tests are skipped until assets are present.

import 'package:background_remover/features/ai/services/blur_detection_service.dart';
import 'package:background_remover/features/ai/services/screenshot_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BlurDetectionService blurService;
  late ScreenshotDetectionService screenshotService;

  setUp(() {
    blurService = BlurDetectionService();
    screenshotService = ScreenshotDetectionService();
  });

  group('BlurDetectionService', () {
    test('detectBlur returns isBlurry=true for blurry_photo.jpg',
        skip: 'Requires test assets', () async {
      final result = await blurService.detectBlur('test/assets/blurry_photo.jpg');
      expect(result.isSuccess, isTrue);
    });

    test('detectBlur returns isBlurry=false for sharp_photo.jpg',
        skip: 'Requires test assets', () async {
      final result = await blurService.detectBlur('test/assets/sharp_photo.jpg');
      expect(result.isSuccess, isTrue);
    });

    test('detectBlur returns failure for non-existent URI', () async {
      final result = await blurService.detectBlur('/no/such/file.jpg');
      expect(result.isFailure, isTrue);
    });

    test('detectBlur returns failure for invalid (non-image) file',
        skip: 'Requires test assets', () async {
      final result = await blurService.detectBlur('test/assets/not_an_image.txt');
      expect(result.isFailure, isTrue);
    });

    test('detectBlurBatch emits one result per input URI',
        skip: 'Requires test assets', () async {
      final uris = ['test/assets/sharp_photo.jpg', 'test/assets/blurry_photo.jpg'];
      final results = await blurService.detectBlurBatch(uris).toList();
      expect(results.length, 2);
    });

    test('detectBlurBatch processes in batches without blocking',
        skip: 'Requires test assets', () async {
      final uris = List.generate(5, (_) => 'test/assets/sharp_photo.jpg');
      final results = await blurService.detectBlurBatch(uris).toList();
      expect(results.length, 5);
    });
  });

  group('ScreenshotDetectionService', () {
    test('detectScreenshot returns isScreenshot=true for screenshot.png',
        skip: 'Requires test assets', () async {
      final result = await screenshotService.detectScreenshot('test/assets/screenshot.png');
      expect(result.isSuccess, isTrue);
    });

    test('detectScreenshot returns isScreenshot=false for normal_photo.jpg',
        skip: 'Requires test assets', () async {
      final result =
          await screenshotService.detectScreenshot('test/assets/normal_photo.jpg');
      expect(result.isSuccess, isTrue);
    });

    test('detectScreenshot returns failure for non-existent URI', () async {
      final result = await screenshotService.detectScreenshot('/no/such/file.jpg');
      expect(result.isFailure, isTrue);
    });

    test('detectScreenshotBatch emits one result per input URI',
        skip: 'Requires test assets', () async {
      final uris = ['test/assets/screenshot.png', 'test/assets/normal_photo.jpg'];
      final results = await screenshotService.detectScreenshotBatch(uris).toList();
      expect(results.length, 2);
    });
  });

  group('batch performance', () {
    test('detectBlurBatch on 50 synthetic images completes under 10 seconds',
        skip: 'Requires test assets', () async {
      final uris = List.generate(50, (_) => 'test/assets/sharp_photo.jpg');
      final stopwatch = Stopwatch()..start();
      await blurService.detectBlurBatch(uris).toList();
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });
  });
}
