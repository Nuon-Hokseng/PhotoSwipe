import 'package:background_remover/shared/theme/app_colors.dart';
import 'package:background_remover/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum TrendDirection { up, down, neutral }

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
    this.unit,
    this.trendColor,
    this.icon,
  });

  final String label;
  final String value;
  final String? unit;
  final TrendDirection trend;
  final Color? trendColor;
  final IconData? icon;

  Color get _trendColor {
    if (trendColor != null) return trendColor!;
    return switch (trend) {
      TrendDirection.up => kColorStatPositive,
      TrendDirection.down => kColorStatNegative,
      TrendDirection.neutral => kColorStatNeutral,
    };
  }

  IconData get _trendIcon => switch (trend) {
        TrendDirection.up => Icons.trending_up,
        TrendDirection.down => Icons.trending_down,
        TrendDirection.neutral => Icons.remove,
      };

  @override
  Widget build(BuildContext context) => Card(
        elevation: 1.5,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100),
          child: Padding(
            padding: const EdgeInsets.all(kSpacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (icon != null) Icon(icon, size: 18, color: kColorStatNeutral),
                    const Spacer(),
                    Icon(_trendIcon, size: 18, color: _trendColor),
                  ],
                ),
                const SizedBox(height: kSpacingS),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: kSpacingXS),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                if (unit != null)
                  Text(unit!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: kColorStatNeutral)),
              ],
            ),
          ),
        ),
      );
}
