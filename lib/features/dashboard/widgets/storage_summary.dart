import 'package:background_remover/shared/theme/app_colors.dart';
import 'package:background_remover/shared/theme/app_spacing.dart';
import 'package:background_remover/utils/image_analysis/format_utils.dart';
import 'package:flutter/material.dart';

class StorageSummary extends StatelessWidget {
  const StorageSummary({
    super.key,
    required this.storageSavedBytes,
    required this.totalPhotosDeleted,
    required this.totalPhotosReviewed,
  });

  final int storageSavedBytes;
  final int totalPhotosDeleted;
  final int totalPhotosReviewed;

  double get _progress {
    if (totalPhotosReviewed == 0) return 0.0;
    return (totalPhotosDeleted / totalPhotosReviewed).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(kSpacingL),
        decoration: BoxDecoration(
          color: kColorChartPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  Text(
                    '${(_progress * 100).round()}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatStorageSize(storageSavedBytes)} freed',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: kSpacingXS),
                  Text(
                    '$totalPhotosDeleted photos deleted of $totalPhotosReviewed reviewed',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
