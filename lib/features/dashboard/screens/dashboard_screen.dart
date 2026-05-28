import 'package:background_remover/controllers/swipe_session_controller.dart';
import 'package:background_remover/features/ai/providers/ai_provider.dart';
import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/features/analytics/providers/analytics_provider.dart';
import 'package:background_remover/features/dashboard/widgets/cleanup_history_list.dart';
import 'package:background_remover/features/dashboard/widgets/daily_chart.dart';
import 'package:background_remover/features/dashboard/widgets/recommendation_card.dart';
import 'package:background_remover/features/dashboard/widgets/stat_card.dart';
import 'package:background_remover/features/dashboard/widgets/storage_summary.dart';
import 'package:background_remover/features/dashboard/widgets/weekly_chart.dart';
import 'package:background_remover/shared/theme/app_colors.dart';
import 'package:background_remover/shared/theme/app_spacing.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:background_remover/shared/widgets/empty_state.dart';
import 'package:background_remover/shared/widgets/error_banner.dart';
import 'package:background_remover/shared/widgets/shimmer_box.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadStats();
    });
  }

  /// Builds the PhotoItem list from device photos for AI scanning.
  List<PhotoItem> _getAiPhotos() {
    return SwipeSessionController.instance.allPhotos
        .map((p) => PhotoItem(id: p.id, uri: p.uri, size: p.fileSizeBytes, createdAt: p.createdAtMillis))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final ai = context.watch<AiProvider>();
    final stats = analytics.stats;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ai),
              if (analytics.error != null)
                ErrorBanner(error: analytics.error!,
                    onRetry: () => context.read<AnalyticsProvider>().loadStats()),
              const SizedBox(height: kSpacingM),
              analytics.isLoading || stats == null
                  ? const ShimmerBox(height: 100)
                  : StorageSummary(
                      storageSavedBytes: stats.storageSaved,
                      totalPhotosDeleted: stats.totalDeleted,
                      totalPhotosReviewed: stats.totalReviewed,
                    ),
              const SizedBox(height: kSpacingL),
              analytics.isLoading || stats == null
                  ? const ShimmerBox(height: 80)
                  : _buildStatRow(stats),
              const SizedBox(height: kSpacingL),
              _buildRecommendations(context, ai),
              const SizedBox(height: kSpacingL),
              analytics.isLoading || stats == null
                  ? const ShimmerBox(height: 200)
                  : DailyChart(data: stats.dailyStats),
              const SizedBox(height: kSpacingL),
              analytics.isLoading || stats == null
                  ? const ShimmerBox(height: 220)
                  : WeeklyChart(data: stats.weeklyStats),
              const SizedBox(height: kSpacingL),
              analytics.isLoading || stats == null
                  ? Column(children: List.generate(3, (_) =>
                      const Padding(padding: EdgeInsets.only(bottom: kSpacingS),
                          child: ShimmerBox(height: 56))))
                  : CleanupHistoryList(sessions: stats.sessionHistory),
              const SizedBox(height: kSpacingXXL),
            ],
          ),
        ),
      );
  }

  Widget _buildHeader(BuildContext context, AiProvider ai) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineSmall),
          FilledButton.icon(
            onPressed: ai.isScanning
                ? null
                : () => ai.runFullScan(_getAiPhotos()),
            icon: ai.isScanning
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: Colors.white))
                : const Icon(Icons.search, size: 18),
            label: const Text('Scan Photos'),
          ),
        ],
      );

  Widget _buildStatRow(AnalyticsStats stats) => Row(
        children: [
          Expanded(child: StatCard(
              label: 'Reviewed',
              value: stats.totalReviewed.toString(),
              trend: TrendDirection.neutral)),
          const SizedBox(width: kSpacingS),
          Expanded(child: StatCard(
              label: 'Deleted',
              value: stats.totalDeleted.toString(),
              trend: TrendDirection.up,
              trendColor: kColorStatPositive)),
          const SizedBox(width: kSpacingS),
          Expanded(child: StatCard(
              label: 'Kept',
              value: stats.totalKept.toString(),
              trend: TrendDirection.neutral)),
        ],
      );

  Widget _buildRecommendations(BuildContext context, AiProvider ai) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recommendations',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: kSpacingS),
          if (ai.isScanning)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LinearProgressIndicator(value: ai.scanProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(kColorChartPrimary)),
              const SizedBox(height: kSpacingXS),
              const Text('Analysing photos...'),
            ])
          else if (ai.recommendations.isEmpty)
            const EmptyState(
                icon: Icons.auto_awesome,
                title: 'No recommendations yet',
                subtitle: 'Tap Scan Photos to analyse your library')
          else
            Column(children: [
              ...ai.recommendations.take(3).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: kSpacingS),
                    child: RecommendationCard(
                      recommendation: r,
                      photoMap: const {},
                      onAccept: () {},
                      onDismiss: () => ai.dismissRecommendation(r.id),
                    ),
                  )),
              if (ai.recommendations.length > 3)
                TextButton(
                  onPressed: () {},
                  child: Text(
                      'See all ${ai.recommendations.length} recommendations'),
                ),
            ]),
        ],
      );
}
