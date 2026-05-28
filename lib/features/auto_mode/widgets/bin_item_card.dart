import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/models/bin_item.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/storage_formatters.dart';
import 'photo_preview_sheet.dart';

class BinItemCard extends StatelessWidget {
  const BinItemCard({
    super.key,
    required this.item,
    required this.onRestore,
  });

  final BinItem item;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => PhotoPreviewSheet.show(context, item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            _ThumbnailOrIcon(item: item),
            const SizedBox(width: 12),
            Expanded(child: _ItemDetails(item: item)),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onRestore,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                    foregroundColor: AppColors.accent,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Restore'),
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
  const _ThumbnailOrIcon({required this.item});

  final BinItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.reason) {
      'blur' => (Icons.blur_on_rounded, const Color(0xFFF97316)),
      'screenshot' => (Icons.screenshot_monitor_rounded, AppColors.accent),
      'both' => (Icons.warning_amber_rounded, AppColors.primary),
      _ => (Icons.delete_outline_rounded, AppColors.textSecondary),
    };

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
                errorBuilder: (_, __, ___) => _iconFallback(icon, color),
              )
            : _iconFallback(icon, color),
      ),
    );
  }

  Widget _iconFallback(IconData icon, Color color) => Container(
        color: color.withValues(alpha: 0.12),
        child: Icon(icon, size: 22, color: color),
      );
}

class _ItemDetails extends StatelessWidget {
  const _ItemDetails({required this.item});

  final BinItem item;

  @override
  Widget build(BuildContext context) {
    final expiry = item.isExpired
        ? ('Expired', AppColors.danger)
        : ('Expires in ${item.daysRemaining}d', const Color(0xFFF59E0B));

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
            _ReasonBadge(reason: item.reason),
            const SizedBox(width: 6),
            Text(
              formatStorageBytes(item.fileSizeBytes),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          expiry.$1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: expiry.$2,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _ReasonBadge extends StatelessWidget {
  const _ReasonBadge({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (reason) {
      'blur' => ('Blurry', const Color(0xFFF97316)),
      'screenshot' => ('Screenshot', AppColors.accent),
      'both' => ('Blur+SS', AppColors.primary),
      _ => ('Manual', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
