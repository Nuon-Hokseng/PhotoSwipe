import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../animations/premium_animations.dart';
import '../../../controllers/swipe_session_controller.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/premium_ui.dart';
import '../providers/auto_mode_provider.dart';
import '../widgets/bin_item_card.dart';
import '../widgets/scan_result_card.dart';

class AutoModeScreen extends StatelessWidget {
  const AutoModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _AutoModeBackground(),
        SafeArea(
          child: Consumer<AutoModeProvider>(
            builder: (context, provider, _) => _AutoModeBody(provider: provider),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _AutoModeBody extends StatelessWidget {
  const _AutoModeBody({required this.provider});

  final AutoModeProvider provider;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumAnimations.fadeSlideIn(
            _Header(provider: provider),
          ),
          const SizedBox(height: 16),
          PremiumAnimations.fadeSlideIn(
            _ScanButton(provider: provider),
            delayMs: 60,
          ),
          if (provider.isScanning) ...[
            const SizedBox(height: 16),
            _ScanProgressSection(provider: provider),
          ],
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: provider.errorMessage!),
          ],
          if (provider.candidates.isNotEmpty) ...[
            const SizedBox(height: 20),
            _CandidatesSection(provider: provider),
          ],
          const SizedBox(height: 20),
          _BinSection(provider: provider),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.provider});

  final AutoModeProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AUTO MODE',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Auto Mode',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        IconButton(
          onPressed: () => _showRetentionSheet(context, provider),
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Retention settings',
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }

  void _showRetentionSheet(BuildContext context, AutoModeProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RetentionSheet(provider: provider),
    );
  }
}

// ---------------------------------------------------------------------------
// Retention sheet (stateful so slider can rebuild on drag)
// ---------------------------------------------------------------------------

class _RetentionSheet extends StatefulWidget {
  const _RetentionSheet({required this.provider});

  final AutoModeProvider provider;

  @override
  State<_RetentionSheet> createState() => _RetentionSheetState();
}

class _RetentionSheetState extends State<_RetentionSheet> {
  late double _days;

  @override
  void initState() {
    super.initState();
    _days = widget.provider.retentionDays.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    const steps = [7.0, 14.0, 30.0, 60.0, 90.0];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bin Retention',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Photos in the bin are automatically deleted after this many days.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${_days.round()} days',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _days,
            min: 7,
            max: 90,
            divisions: 4,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withValues(alpha: 0.2),
            onChanged: (v) {
              // Snap to allowed steps
              double snapped = steps.reduce(
                (a, b) => (v - a).abs() < (v - b).abs() ? a : b,
              );
              setState(() => _days = snapped);
              widget.provider.setRetentionDays(snapped.round());
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps
                .map(
                  (d) => Text(
                    '${d.round()}d',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _days == d
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scan button
// ---------------------------------------------------------------------------

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.provider});

  final AutoModeProvider provider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: provider.isScanning
            ? null
            : () {
                final photos =
                    SwipeSessionController.instance.allPhotos;
                context.read<AutoModeProvider>().startScan(photos);
              },
        icon: const Icon(Icons.search_rounded),
        label: Text(
          provider.isScanning ? 'Scanning…' : 'Scan for Junk Photos',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress section
// ---------------------------------------------------------------------------

class _ScanProgressSection extends StatelessWidget {
  const _ScanProgressSection({required this.provider});

  final AutoModeProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scanning ${provider.scannedCount} / ${provider.totalCount} photos…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton(
                onPressed: context.read<AutoModeProvider>().cancelScan,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PremiumGradientProgressBar(value: provider.scanProgress, height: 6),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Candidates section
// ---------------------------------------------------------------------------

class _CandidatesSection extends StatelessWidget {
  const _CandidatesSection({required this.provider});

  final AutoModeProvider provider;

  @override
  Widget build(BuildContext context) {
    return PremiumAnimations.fadeSlideIn(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Found ${provider.candidates.length} candidate${provider.candidates.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (provider.candidates.isNotEmpty)
                TextButton(
                  onPressed: context.read<AutoModeProvider>().moveAllToBin,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Move All to Bin'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.candidates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = provider.candidates[index];
              return ScanResultCard(
                item: item,
                onAddToBin: () =>
                    context.read<AutoModeProvider>().moveSingleToBin(item),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bin section
// ---------------------------------------------------------------------------

class _BinSection extends StatelessWidget {
  const _BinSection({required this.provider});

  final AutoModeProvider provider;

  @override
  Widget build(BuildContext context) {
    final isEmpty = provider.binItems.isEmpty;

    return PremiumAnimations.fadeSlideIn(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BinHeader(provider: provider),
          const SizedBox(height: 10),
          if (provider.expiredCount > 0) ...[
            _PurgeRow(provider: provider),
            const SizedBox(height: 10),
          ],
          if (isEmpty && !provider.isScanning)
            const _BinEmptyState()
          else if (!isEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.binItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = provider.binItems[index];
                return BinItemCard(
                  item: item,
                  onRestore: () =>
                      context.read<AutoModeProvider>().restoreFromBin(item.photoId),
                );
              },
            ),
        ],
      ),
      delayMs: 80,
    );
  }
}

class _BinHeader extends StatelessWidget {
  const _BinHeader({required this.provider});

  final AutoModeProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.delete_rounded, size: 20, color: AppColors.danger),
        const SizedBox(width: 8),
        Text(
          'Trash Bin',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        if (provider.binItems.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${provider.binItems.length}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            provider.binSizeFormatted,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}

class _PurgeRow extends StatelessWidget {
  const _PurgeRow({required this.provider});

  final AutoModeProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_off_rounded,
                  size: 16, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                '${provider.expiredCount} expired',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          TextButton(
            onPressed: context.read<AutoModeProvider>().purgeExpired,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Purge Now'),
          ),
        ],
      ),
    );
  }
}

class _BinEmptyState extends StatelessWidget {
  const _BinEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: PremiumEmptyState(
          icon: Icons.delete_outline_rounded,
          title: 'Bin is Empty',
          message:
              'Run a scan to find blurry photos and screenshots, then move them here.',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background
// ---------------------------------------------------------------------------

class _AutoModeBackground extends StatelessWidget {
  const _AutoModeBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.8),
          radius: 1.1,
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            AppColors.background,
          ],
          stops: const [0, 0.75],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
