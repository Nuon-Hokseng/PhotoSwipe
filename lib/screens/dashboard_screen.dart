import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../animations/premium_animations.dart';
import '../controllers/analytics_controller.dart';
import '../models/cleanup_session.dart';
import '../utils/app_colors.dart';
import '../utils/storage_formatters.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onStartCleanup});

  final VoidCallback? onStartCleanup;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AnalyticsController.instance,
      builder: (context, _) {
        final analytics = AnalyticsController.instance;
        final session = analytics.session;

        return SafeArea(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.35,
                colors: [Color(0x3322D3EE), AppColors.background],
                stops: [0, 0.78],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderSection(session: session)
                      .animate()
                      .fadeIn(duration: 360.ms)
                      .slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 18),
                  if (session.reviewedCount == 0)
                    _EmptyDashboardState(onStartCleanup: onStartCleanup)
                  else ...[
                    _OverviewPanel(session: session)
                        .animate()
                        .fadeIn(delay: 70.ms, duration: 360.ms)
                        .slideY(begin: 0.08, end: 0),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 520;

                        return GridView.count(
                          crossAxisCount: isWide ? 2 : 1,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: isWide ? 1.32 : 2.55,
                          children: [
                            StatCard(
                              title: 'Photos Reviewed',
                              value: '${session.reviewedCount}',
                              icon: Icons.fact_check_rounded,
                              accentColor: AppColors.accent,
                              subtitle: 'Immediate local updates',
                            ),
                            StatCard(
                              title: 'Deleted Photos',
                              value: '${session.deletedCount}',
                              icon: Icons.delete_forever_rounded,
                              accentColor: AppColors.danger,
                              subtitle: 'Marked for removal',
                            ),
                            StatCard(
                              title: 'Kept Photos',
                              value: '${session.keptCount}',
                              icon: Icons.favorite_rounded,
                              accentColor: AppColors.success,
                              subtitle: 'Retained locally',
                            ),
                            StatCard(
                              title: 'Storage Saved',
                              value: formatStorageBytes(
                                analytics.calculateStorageSaved(),
                              ),
                              icon: Icons.savings_rounded,
                              accentColor: AppColors.primary,
                              subtitle: 'Estimated local cleanup',
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _SummarySection(session: session)
                        .animate()
                        .fadeIn(delay: 140.ms, duration: 360.ms)
                        .slideY(begin: 0.08, end: 0),
                    const SizedBox(height: 18),
                    _ChartSection(weeklyActivity: analytics.weeklyActivity)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 360.ms)
                        .slideY(begin: 0.08, end: 0),
                    const SizedBox(height: 18),
                    _RecentActivitySection(history: analytics.history)
                        .animate()
                        .fadeIn(delay: 260.ms, duration: 360.ms)
                        .slideY(begin: 0.08, end: 0),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.session});

  final CleanupSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.card.withValues(alpha: 0.95),
            AppColors.cardElevated.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cleanup Analytics',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(letterSpacing: -0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.reviewedCount == 0
                          ? 'Session summary will update as soon as you start swiping.'
                          : 'Live analytics refresh immediately after every swipe and undo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Session ${session.sessionId.split('-').last}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.reviewedCount}/${session.totalPhotos} reviewed',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PremiumGradientProgressBar(value: session.completionRate, height: 10),
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.session});

  final CleanupSession session;

  @override
  Widget build(BuildContext context) {
    final completionPercent = (session.completionRate * 100).round();
    final storageSaved = formatStorageBytes(session.storageSavedBytes);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.card.withValues(alpha: 0.94),
            AppColors.cardElevated.withValues(alpha: 0.90),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            height: 108,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: session.completionRate),
                  duration: PremiumAnimations.premium,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 11,
                        backgroundColor: const Color(0xFF334155),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    );
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PremiumCountText(
                      value: '$completionPercent%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'complete',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cleanup efficiency: ${(session.cleanupEfficiency * 100).round()}%\n'
                  'Estimated storage recovered: $storageSaved\n'
                  'Average swipe speed: 1.3 s/photo\n'
                  'Session completion: $completionPercent%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.session});

  final CleanupSession session;

  @override
  Widget build(BuildContext context) {
    final efficiency = (session.cleanupEfficiency * 100).round();
    final completion = (session.completionRate * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final tileWidth = isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryMetricTile(
                    label: 'Cleanup efficiency',
                    value: '$efficiency%',
                    accentColor: AppColors.accent,
                    width: tileWidth,
                  ),
                  _SummaryMetricTile(
                    label: 'Storage recovered',
                    value: formatStorageBytes(session.storageSavedBytes),
                    accentColor: AppColors.primary,
                    width: tileWidth,
                  ),
                  _SummaryMetricTile(
                    label: 'Average swipe speed',
                    value: '1.3 s/photo',
                    accentColor: AppColors.success,
                    width: tileWidth,
                  ),
                  _SummaryMetricTile(
                    label: 'Completion',
                    value: '$completion%',
                    accentColor: AppColors.danger,
                    width: tileWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.width,
  });

  final String label;
  final String value;
  final Color accentColor;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PremiumCountText(
                    value: value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.weeklyActivity});

  final List<int> weeklyActivity;

  @override
  Widget build(BuildContext context) {
    final maxValue = math
        .max(weeklyActivity.isEmpty ? 1 : weeklyActivity.reduce(math.max), 1)
        .toDouble();
    const labels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Cleanup Chart',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Mock cleanup activity from Monday to Sunday.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                maxY: maxValue + 1,
                alignment: BarChartAlignment.spaceAround,
                groupsSpace: 10,
                barTouchData: BarTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var index = 0; index < weeklyActivity.length; index++)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: weeklyActivity[index].toDouble(),
                          width: 16,
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxValue + 1,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              swapAnimationDuration: PremiumAnimations.premium,
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.history});

  final List<CleanupActivity> history;

  @override
  Widget build(BuildContext context) {
    final visibleHistory = history.take(5).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Latest mock actions from the local cleanup session.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          if (visibleHistory.isEmpty)
            const _EmptyActivityState()
          else
            ListView.separated(
              itemCount: visibleHistory.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ActivityCard(entry: visibleHistory[index]);
              },
            ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.entry});

  final CleanupActivity entry;

  @override
  Widget build(BuildContext context) {
    final isDelete = entry.actionType == CleanupActivityType.delete;
    final isUndo = entry.actionType == CleanupActivityType.undo;
    final color = isUndo
        ? AppColors.accent
        : isDelete
        ? AppColors.danger
        : AppColors.success;
    final title = isUndo
        ? 'Undo ${entry.photoLabel}'
        : isDelete
        ? 'Deleted ${entry.photoLabel}'
        : 'Kept ${entry.photoLabel}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUndo
                  ? Icons.undo_rounded
                  : isDelete
                  ? Icons.delete_rounded
                  : Icons.favorite_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatStorageBytes(entry.photoSizeBytes)} • ${_formatRelativeTime(entry.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_graph_rounded,
            size: 44,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            'No activity recorded yet.',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState({required this.onStartCleanup});

  final VoidCallback? onStartCleanup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              gradient: AppColors.softGradient,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(
              Icons.cleaning_services_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No cleanup activity yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the swipe session to populate live analytics, storage savings, and the weekly chart.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onStartCleanup,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Start Cleanup'),
          ),
        ],
      ),
    );
  }
}

String _formatRelativeTime(DateTime timestamp) {
  final difference = DateTime.now().difference(timestamp);
  if (difference.inMinutes < 1) {
    return 'just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  return '${difference.inDays}d ago';
}
