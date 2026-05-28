import 'package:background_remover/features/ai/ai_types.dart';
import 'package:background_remover/shared/theme/app_colors.dart';
import 'package:background_remover/shared/theme/app_spacing.dart';
import 'package:background_remover/shared/types/photo.dart';
import 'package:background_remover/utils/image_analysis/format_utils.dart';
import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.recommendation,
    required this.photoMap,
    this.onAccept,
    this.onDismiss,
  });

  final Recommendation recommendation;
  final Map<String, PhotoItem> photoMap;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;

  Color get _accentColor => switch (recommendation.type) {
        RecommendationType.blur => kColorBlurTag,
        RecommendationType.duplicate => kColorDuplicateTag,
        RecommendationType.screenshot => kColorScreenshotTag,
        RecommendationType.cluster => kColorChartPrimary,
      };

  String get _typeLabel => recommendation.type.name.toUpperCase();

  int get _totalSize => recommendation.photoIds
      .map((id) => photoMap[id]?.size ?? 0)
      .fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12)),
              )),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(kSpacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(recommendation.reason,
                              style: const TextStyle(fontWeight: FontWeight.w500))),
                          Chip(
                            label: Text(_typeLabel,
                                style: const TextStyle(fontSize: 10, color: Colors.white)),
                            backgroundColor: _accentColor,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      const SizedBox(height: kSpacingXS),
                      Text(
                        '${recommendation.photoIds.length} photos · ~${formatStorageSize(_totalSize)} to free',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: kSpacingS),
                      LinearProgressIndicator(
                        value: recommendation.confidence,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                        minHeight: 4,
                      ),
                      const SizedBox(height: kSpacingXS),
                      Text(
                        '${(recommendation.confidence * 100).round()}% confidence',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (onAccept != null || onDismiss != null) ...[
                        const SizedBox(height: kSpacingS),
                        Row(children: [
                          if (onAccept != null)
                            FilledButton(onPressed: onAccept,
                                child: const Text('Clean up')),
                          if (onAccept != null && onDismiss != null)
                            const SizedBox(width: kSpacingS),
                          if (onDismiss != null)
                            TextButton(onPressed: onDismiss,
                                child: const Text('Ignore')),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
