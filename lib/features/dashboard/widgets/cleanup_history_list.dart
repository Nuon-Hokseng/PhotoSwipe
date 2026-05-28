import 'package:background_remover/features/analytics/analytics_types.dart';
import 'package:background_remover/shared/theme/app_colors.dart';
import 'package:background_remover/shared/theme/app_spacing.dart';
import 'package:background_remover/shared/widgets/empty_state.dart';
import 'package:background_remover/shared/widgets/shimmer_box.dart';
import 'package:background_remover/utils/image_analysis/format_utils.dart';
import 'package:flutter/material.dart';

class CleanupHistoryList extends StatelessWidget {
  const CleanupHistoryList({
    super.key,
    required this.sessions,
    this.maxItems = 10,
    this.onSeeAll,
    this.isLoading = false,
  });

  final List<Session> sessions;
  final int maxItems;
  final VoidCallback? onSeeAll;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(3,
            (_) => const Padding(
                padding: EdgeInsets.only(bottom: kSpacingS),
                child: ShimmerBox(height: 56))),
      );
    }
    if (sessions.isEmpty) {
      return const EmptyState(
          icon: Icons.history, title: 'No cleanup sessions yet');
    }
    final shown = sessions.take(maxItems).toList();
    return Column(
      children: [
        ...List.generate(shown.length, (i) => Column(children: [
          SessionListItem(session: shown[i]),
          if (i < shown.length - 1) const Divider(height: 1),
        ])),
        if (sessions.length > maxItems)
          ListTile(
            title: Text('See all ${sessions.length} sessions',
                style: const TextStyle(color: kColorChartPrimary)),
            trailing: const Icon(Icons.chevron_right, color: kColorChartPrimary),
            onTap: onSeeAll,
          ),
      ],
    );
  }
}

class SessionListItem extends StatelessWidget {
  const SessionListItem({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: kSpacingM, vertical: kSpacingS),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: kColorStatNeutral),
              const SizedBox(width: kSpacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatDate(session.startedAt),
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      formatDuration(
                          session.startedAt, session.endedAt ?? session.startedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text('${session.reviewed} reviewed · ${session.deleted} deleted',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Text(
                formatStorageSize(session.storageSaved),
                style: const TextStyle(
                    color: kColorStatPositive, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
}
