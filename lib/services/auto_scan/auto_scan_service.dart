import 'package:background_remover/features/ai/ai_types.dart';
import 'package:background_remover/features/ai/services/blur_detection_service.dart';
import 'package:background_remover/features/ai/services/screenshot_detection_service.dart';
import 'package:background_remover/models/photo_model.dart';
import 'package:background_remover/services/logger/app_logger.dart';
import 'package:background_remover/shared/models/bin_item.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/result.dart';

class AutoScanProgress {
  const AutoScanProgress({
    required this.scanned,
    required this.total,
    this.candidate,
  });

  final int scanned;
  final int total;

  /// Non-null when the scanned photo is a candidate for the bin.
  final BinItem? candidate;
}

class AutoScanService {
  AutoScanService({
    required BlurDetectionService blurService,
    required ScreenshotDetectionService screenshotService,
  })  : _blurService = blurService,
        _screenshotService = screenshotService;

  static const _tag = 'AutoScanService';

  final BlurDetectionService _blurService;
  final ScreenshotDetectionService _screenshotService;

  /// Scan [photos] using blur and screenshot detection in parallel.
  ///
  /// Yields [AutoScanProgress] after every photo. [AutoScanProgress.candidate]
  /// is non-null when a photo is flagged as junk.
  Stream<AutoScanProgress> scan(
    List<PhotoModel> photos, {
    int retentionDays = 30,
  }) async* {
    final total = photos.length;

    for (var i = 0; i < total; i++) {
      final photo = photos[i];
      BinItem? candidate;

      try {
        final blurFuture = _blurService.detectBlur(photo.uri);
        final screenshotFuture = _screenshotService.detectScreenshot(photo.uri);

        final blurResult = await blurFuture;
        final screenshotResult = await screenshotFuture;

        final bool isBlurry;
        final double blurScore;
        final bool isScreenshot;
        final double screenshotConf;

        if (blurResult is Success<BlurResult, AppError>) {
          isBlurry = blurResult.data.isBlurry;
          blurScore = blurResult.data.blurScore;
        } else {
          isBlurry = false;
          blurScore = 0.0;
        }

        if (screenshotResult is Success<ScreenshotResult, AppError>) {
          isScreenshot = screenshotResult.data.isScreenshot;
          screenshotConf = screenshotResult.data.confidence;
        } else {
          isScreenshot = false;
          screenshotConf = 0.0;
        }

        if (isBlurry || isScreenshot) {
          final reason = (isBlurry && isScreenshot)
              ? 'both'
              : isBlurry
                  ? 'blur'
                  : 'screenshot';

          final confidence = blurScore > screenshotConf ? blurScore : screenshotConf;

          final now = DateTime.now().millisecondsSinceEpoch;
          candidate = BinItem(
            photoId: photo.id,
            uri: photo.uri,
            filename: photo.filename,
            fileSizeBytes: photo.fileSizeBytes,
            addedAt: now,
            expiresAt: now + retentionDays * Duration.millisecondsPerDay,
            reason: reason,
            confidence: confidence,
          );

          AppLogger.info(
            _tag,
            'Candidate: ${photo.filename} reason=$reason conf=${confidence.toStringAsFixed(2)}',
          );
        }
      } catch (e, s) {
        AppLogger.logError(_tag, e, s);
        // Skip this photo — don't crash the stream.
      }

      yield AutoScanProgress(
        scanned: i + 1,
        total: total,
        candidate: candidate,
      );
    }
  }
}
