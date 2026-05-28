import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared/models/bin_item.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/storage_formatters.dart';

/// Full-screen photo preview bottom sheet.
/// Call via [PhotoPreviewSheet.show].
class PhotoPreviewSheet extends StatelessWidget {
  const PhotoPreviewSheet({super.key, required this.item});

  final BinItem item;

  static Future<void> show(BuildContext context, BinItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhotoPreviewSheet(item: item),
    );
  }

  Color get _accentColor => switch (item.reason) {
        'blur' => const Color(0xFFF97316),
        'screenshot' => AppColors.accent,
        'both' => AppColors.primary,
        _ => AppColors.textSecondary,
      };

  String get _reasonLabel => switch (item.reason) {
        'blur' => 'Blurry Photo',
        'screenshot' => 'Screenshot',
        'both' => 'Blurry Screenshot',
        _ => 'Flagged',
      };

  IconData get _reasonIcon => switch (item.reason) {
        'blur' => Icons.blur_on_rounded,
        'screenshot' => Icons.screenshot_monitor_rounded,
        'both' => Icons.warning_amber_rounded,
        _ => Icons.flag_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenH * 0.88,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_reasonIcon, size: 14, color: _accentColor),
                      const SizedBox(width: 5),
                      Text(
                        _reasonLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(item.confidence * 100).round()}% confident',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                  iconSize: 22,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Photo viewer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _PhotoView(uri: item.uri),
              ),
            ),
          ),
          // File meta
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatStorageBytes(item.fileSizeBytes),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Safe-area spacer
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

class _PhotoView extends StatelessWidget {
  const _PhotoView({required this.uri});

  final String uri;

  @override
  Widget build(BuildContext context) {
    if (uri.isEmpty) {
      return _placeholder(Icons.broken_image_outlined, 'No image path');
    }

    final file = File(uri);
    if (!file.existsSync()) {
      return _placeholder(Icons.image_not_supported_outlined, 'File not found');
    }

    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4.0,
      child: Image.file(
        file,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) =>
            _placeholder(Icons.broken_image_outlined, 'Cannot load image'),
      ),
    );
  }

  Widget _placeholder(IconData icon, String message) {
    return Container(
      color: AppColors.cardElevated,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
