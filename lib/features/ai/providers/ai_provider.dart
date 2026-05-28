import 'package:background_remover/features/ai/ai_types.dart';
import 'package:background_remover/features/ai/services/recommendation_service.dart';
import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/shared/types/app_error.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:flutter/foundation.dart';

class AiProvider extends ChangeNotifier {
  AiProvider(this._service);

  final RecommendationService _service;

  List<Recommendation> recommendations = [];
  RecommendationSummary? summary;
  bool isScanning = false;
  double scanProgress = 0.0;
  AppError? error;

  /// Runs a full AI scan; no-op if already scanning. Emits progress at 4 checkpoints.
  Future<void> runFullScan(List<PhotoItem> photos) async {
    if (isScanning) return;
    isScanning = true;
    scanProgress = 0.10;       // checkpoint 1 — started
    notifyListeners();

    // Start analysis; emit 0.40 after the future is launched (blur+ss phase)
    final scanFuture = _service.generateRecommendations(photos);
    await Future.delayed(Duration.zero); // yield so UI can render
    scanProgress = 0.40;       // checkpoint 2 — analysis running
    notifyListeners();

    final result = await scanFuture;
    scanProgress = 0.80;       // checkpoint 3 — processing complete
    notifyListeners();

    result.when(
      onSuccess: (recs) {
        recommendations = recs;
        summary = _service.getRecommendationSummary(recs);
        error = null;
      },
      onFailure: (e) => error = e,
    );
    scanProgress = 1.00;       // checkpoint 4 — done
    isScanning = false;
    notifyListeners();
  }

  /// Like [runFullScan] but personalises weights using historical [stats].
  Future<void> runScanWithStats(
      List<PhotoItem> photos, AnalyticsStats stats) async {
    if (isScanning) return;
    isScanning = true;
    scanProgress = 0.10;
    notifyListeners();

    final scanFuture =
        _service.generateRecommendationsFromStats(stats, photos);
    await Future.delayed(Duration.zero);
    scanProgress = 0.40;
    notifyListeners();

    final result = await scanFuture;
    scanProgress = 0.80;
    notifyListeners();

    result.when(
      onSuccess: (recs) {
        recommendations = recs;
        summary = _service.getRecommendationSummary(recs);
        error = null;
      },
      onFailure: (e) => error = e,
    );
    scanProgress = 1.00;
    isScanning = false;
    notifyListeners();
  }

  /// Removes a recommendation by id — does NOT delete any photos.
  void dismissRecommendation(String recommendationId) {
    recommendations =
        recommendations.where((r) => r.id != recommendationId).toList();
    notifyListeners();
  }

  /// Resets recommendations and summary.
  void clearRecommendations() {
    recommendations = [];
    summary = null;
    notifyListeners();
  }

  /// Clears the last recorded error.
  void clearError() {
    error = null;
    notifyListeners();
  }
}
