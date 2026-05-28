import 'package:flutter/foundation.dart';

import '../../../features/ai/services/blur_detection_service.dart';
import '../../../features/ai/services/screenshot_detection_service.dart';
import '../../../models/photo_model.dart';
import '../../../services/auto_scan/auto_scan_service.dart';
import '../../../services/bin/photo_bin_service.dart';
import '../../../services/gallery/gallery_repository.dart';
import '../../../services/logger/app_logger.dart';
import '../../../shared/models/bin_item.dart';
import '../../../utils/storage_formatters.dart';

class AutoModeProvider extends ChangeNotifier {
  static const _tag = 'AutoModeProvider';

  AutoModeProvider()
      : _blurService = BlurDetectionService(),
        _screenshotService = ScreenshotDetectionService(),
        _binService = PhotoBinService(),
        _galleryRepo = GalleryRepository() {
    _autoScanService = AutoScanService(
      blurService: _blurService,
      screenshotService: _screenshotService,
    );
  }

  final BlurDetectionService _blurService;
  final ScreenshotDetectionService _screenshotService;
  final PhotoBinService _binService;
  final GalleryRepository _galleryRepo;
  late final AutoScanService _autoScanService;

  // -------------------------------------------------------------------------
  // State
  // -------------------------------------------------------------------------

  bool isScanning = false;
  double scanProgress = 0.0;
  int scannedCount = 0;
  int totalCount = 0;
  List<BinItem> candidates = [];
  List<BinItem> binItems = [];
  int retentionDays = 30;
  bool isInitialized = false;
  String? errorMessage;

  // -------------------------------------------------------------------------
  // Derived
  // -------------------------------------------------------------------------

  int get expiredCount => _binService.getExpiredItems().length;

  String get binSizeFormatted => formatStorageBytes(_binService.totalSizeBytes);

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  Future<void> init() async {
    await _binService.init();
    _reloadBin();
    isInitialized = true;
    notifyListeners();
    AppLogger.info(_tag, 'AutoModeProvider initialized');
  }

  // -------------------------------------------------------------------------
  // Scan
  // -------------------------------------------------------------------------

  Future<void> startScan(List<PhotoModel> photos) async {
    if (isScanning) return;

    isScanning = true;
    scanProgress = 0.0;
    scannedCount = 0;
    totalCount = photos.length;
    candidates = [];
    errorMessage = null;
    notifyListeners();

    try {
      await for (final progress in _autoScanService.scan(
        photos,
        retentionDays: retentionDays,
      )) {
        if (!isScanning) break; // cancelled

        scannedCount = progress.scanned;
        scanProgress =
            progress.total > 0 ? progress.scanned / progress.total : 0.0;

        if (progress.candidate != null) {
          candidates = [...candidates, progress.candidate!];
        }

        notifyListeners();
      }
    } catch (e, s) {
      AppLogger.logError(_tag, e, s);
      errorMessage = 'Scan encountered an error. Some photos may be skipped.';
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  void cancelScan() {
    if (isScanning) {
      isScanning = false;
      notifyListeners();
      AppLogger.info(_tag, 'Scan cancelled');
    }
  }

  // -------------------------------------------------------------------------
  // Bin management
  // -------------------------------------------------------------------------

  Future<void> moveAllToBin() async {
    if (candidates.isEmpty) return;
    await _binService.addAllToBin(candidates);
    candidates = [];
    _reloadBin();
    notifyListeners();
  }

  Future<void> moveSingleToBin(BinItem item) async {
    await _binService.addToBin(item);
    candidates = candidates.where((c) => c.photoId != item.photoId).toList();
    _reloadBin();
    notifyListeners();
  }

  Future<void> restoreFromBin(String photoId) async {
    await _binService.restoreFromBin(photoId);
    _reloadBin();
    notifyListeners();
  }

  Future<void> purgeExpired() async {
    final count = await _binService.purgeExpired(_galleryRepo);
    if (count > 0) {
      AppLogger.info(_tag, 'Purged $count expired items');
      _reloadBin();
      notifyListeners();
    }
  }

  void setRetentionDays(int days) {
    retentionDays = days;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  void _reloadBin() {
    binItems = List<BinItem>.from(_binService.getBinItems());
  }
}
