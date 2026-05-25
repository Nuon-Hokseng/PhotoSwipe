import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../animations/premium_animations.dart';
import '../controllers/swipe_session_controller.dart';
import '../models/swipe_action.dart';
import '../utils/app_colors.dart';
import '../utils/storage_formatters.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SwipeSessionController.instance,
      builder: (context, _) {
        final session = SwipeSessionController.instance;
        final reviewed = session.reviewedCount;
        final total = session.totalPhotos;
        final completion = total == 0 ? 0.0 : reviewed / total;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Track cleanup progress and storage savings.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 390;

                    return GridView.count(
                      crossAxisCount: isWide ? 2 : 1,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 1.22 : 2.6,
                      children: [
                        StatCard(
                          title: 'Reviewed',
                          value: '$reviewed',
                          icon: Icons.fact_check_rounded,
                          accentColor: AppColors.accent,
                          subtitle: 'Mock swipe decisions',
                        ),
                        StatCard(
                          title: 'Kept',
                          value: '${session.keptCount}',
                          icon: Icons.favorite_rounded,
                          accentColor: AppColors.success,
                          subtitle: 'Photos kept locally',
                        ),
                        StatCard(
                          title: 'Deleted',
                          value: '${session.deletedCount}',
                          icon: Icons.delete_forever_rounded,
                          accentColor: AppColors.danger,
                          subtitle: 'Marked for removal',
                        ),
                        StatCard(
                          title: 'Saved',
                          value: formatStorageBytes(
                            session.estimatedStorageSavedBytes,
                          ),
                          icon: Icons.savings_rounded,
                          accentColor: AppColors.primary,
                          subtitle: 'Mock storage estimate',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                PremiumAnimations.fadeSlideIn(
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 92,
                          height: 92,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: completion),
                                duration: PremiumAnimations.premium,
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) {
                                  return CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 10,
                                    backgroundColor: const Color(0xFF334155),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.accent,
                                        ),
                                    strokeCap: StrokeCap.round,
                                  );
                                },
                              ),
                              Center(
                                child: PremiumCountText(
                                  value: '${(completion * 100).round()}%',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
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
                                'Cleanup completion',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Completed $reviewed of $total mock photos with all state kept locally in memory.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PremiumAnimations.fadeSlideIn(
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Swipe history',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: session.history.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const PremiumMetricSkeleton(
                                          height: 14,
                                          width: 160,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'No local swipe actions yet.',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: session.history.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final record = session.history[index];
                                      final isDelete =
                                          record.action ==
                                          SwipeActionType.delete;

                                      return _ActivityTile(
                                        title: isDelete
                                            ? 'Deleted photo'
                                            : 'Kept photo',
                                        subtitle:
                                            '${record.photoId} • ${formatStorageBytes(record.photoSizeBytes)} • ${record.timestamp.toIso8601String().substring(11, 19)}',
                                        color: isDelete
                                            ? AppColors.danger
                                            : AppColors.success,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PremiumAnimations.fadeSlideIn(const _TrendChartPlaceholder()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardElevated.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _TrendChartPlaceholder extends StatelessWidget {
  const _TrendChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    final heights = <double>[0.32, 0.48, 0.78, 0.58, 0.86, 0.74];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trend preview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < heights.length; index++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: index == 0 ? 0 : 4,
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: heights[index]),
                        duration: Duration(milliseconds: 420 + (index * 70)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 120 * value,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
