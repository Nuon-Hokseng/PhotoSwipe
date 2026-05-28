import 'package:background_remover/features/ai/providers/ai_provider.dart';
import 'package:background_remover/features/ai/services/blur_detection_service.dart';
import 'package:background_remover/features/ai/services/duplicate_detection_service.dart';
import 'package:background_remover/features/ai/services/recommendation_service.dart';
import 'package:background_remover/features/ai/services/screenshot_detection_service.dart';

/// Wires the full AI dependency chain. Use instead of manual instantiation in widgets.
class AiModule {
  AiModule._();

  static BlurDetectionService get blurService => BlurDetectionService();

  static ScreenshotDetectionService get screenshotService =>
      ScreenshotDetectionService();

  static DuplicateDetectionService get duplicateService =>
      DuplicateDetectionService();

  static RecommendationService get recommendationService => RecommendationService(
        blurService: blurService,
        screenshotService: screenshotService,
        duplicateService: duplicateService,
      );

  static AiProvider get provider => AiProvider(recommendationService);
}
