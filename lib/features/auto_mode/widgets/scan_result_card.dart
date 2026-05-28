import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/models/bin_item.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/storage_formatters.dart';
import 'photo_preview_sheet.dart';

class ScanResultCard extends StatelessWidget {
  const ScanResultCard({
    super.key,
    required this.item,
    required this.onAddToBin,
  });

  final BinItem item;
  final VoidCallback onAddToBin;

  Color get _accentColor => switch (item.reason) {
        'blur' => const Color(0xFFF97316),
        'screenshot' => AppColors.accent,
        'both' => AppColors.primary,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => PhotoPreviewSheet.show(context, item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentColor.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            _ThumbnailOrIcon(item: item, accentColor: _accentColor),
            const SizedBox(width: 12),
            Expanded(child: _CandidateDetails(item: item, accentColor: _accentColor)),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: onAddToBin,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentColor.withValues(alpha: 0.18),
                    foregroundColor: _accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Add to Bin'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to preview',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailOrIcon extends StatelessWidget {
  const _ThumbnailOrIcon({required this.item, required this.accentColor});

  final BinItem item;
  final Color accentColor;

  IconData get _icon => switch (item.reason) {
        'blur' => Icons.blur_on_rounded,
        'screenshot' => Icons.screenshot_monitor_rounded,
        'both' => Icons.warning_amber_rounded,
        _ => Icons.help_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final hasFile = item.uri.isNotEmpty && File(item.uri).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 52,
        child: hasFile
            ? Image.file(
                File(item.uri),
                fit: BoxFit.cover,
                cacheWidth: 104,
                errorBuilder: (_, __, ___) => _iconBox(),
              )
            : _iconBox(),
      ),
    );
  }

  Widget _iconBox() => Container(
        color: accentColor.withValues(alpha: 0.12),
        child: Icon(_icon, size: 22, color: accentColor),
      );
}

class _CandidateDetails extends StatelessWidget {
  const _CandidateDetails({required this.item, required this.accentColor});

  final BinItem item;
  final Color accentColor;

  String get _reasonLabel => switch (item.reason) {
        'blur' => 'Blurry',
        'screenshot' => 'Screenshot',
        'both' => 'Blur + Screenshot',
        _ => 'Manual',
      };

  @override
  Widget build(BuildContext context) {
    final confidencePct = (item.confidence * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _reasonLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$confidencePct% confident',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          formatStorageBytes(item.fileSizeBytes),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
