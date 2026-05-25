import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../animations/premium_animations.dart';
import '../controllers/swipe_session_controller.dart';
import '../models/photo_model.dart';
import '../models/swipe_action.dart';
import '../utils/app_colors.dart';
import '../utils/storage_formatters.dart';
import '../widgets/action_button.dart';
import '../widgets/photo_card.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _cardController = CardSwiperController();
  final SwipeSessionController _session = SwipeSessionController.instance;

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<bool> _handleSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    // Future haptic hook:
    // swipe right -> soft success vibration
    // swipe left -> stronger delete vibration
    _session.swipe(
      direction == CardSwiperDirection.left
          ? SwipeActionType.delete
          : SwipeActionType.keep,
    );
    return true;
  }

  bool _handleUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    _session.undo();
    return true;
  }

  void _swipeLeft() {
    if (_session.isCompleted) {
      return;
    }
    _cardController.swipe(CardSwiperDirection.left);
  }

  void _swipeRight() {
    if (_session.isCompleted) {
      return;
    }
    _cardController.swipe(CardSwiperDirection.right);
  }

  void _undoSwipe() {
    if (!_session.canUndo) {
      return;
    }
    _cardController.undo();
  }

  void _restartSession() {
    _session.restart();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        final queue = _session.queue;
        final totalPhotos = _session.totalPhotos;
        final reviewedCount = _session.reviewedCount;
        final progressValue = totalPhotos == 0
            ? 0.0
            : reviewedCount / totalPhotos;
        final currentNumber = queue.isEmpty ? totalPhotos : reviewedCount + 1;
        final storageSaved = formatStorageBytes(
          _session.estimatedStorageSavedBytes,
        );

        return Stack(
          children: [
            const _SwipeBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    _SwipeHeader(
                      currentNumber: currentNumber,
                      totalPhotos: totalPhotos,
                      progressValue: progressValue,
                      reviewedCount: reviewedCount,
                      keptCount: _session.keptCount,
                      deletedCount: _session.deletedCount,
                      storageSaved: storageSaved,
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: AspectRatio(
                            aspectRatio: 0.78,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: queue.isEmpty
                                  ? _CompletedState(
                                      key: const ValueKey('completed-state'),
                                      reviewedCount: reviewedCount,
                                      keptCount: _session.keptCount,
                                      deletedCount: _session.deletedCount,
                                      storageSaved: storageSaved,
                                      onRestart: _restartSession,
                                      canUndo: _session.canUndo,
                                      onUndo: _undoSwipe,
                                    )
                                  : CardSwiper(
                                      key: ValueKey(
                                        'swipe-${_session.generation}',
                                      ),
                                      controller: _cardController,
                                      cardsCount: queue.length,
                                      numberOfCardsDisplayed: queue.length >= 3
                                          ? 3
                                          : queue.length,
                                      isLoop: false,
                                      padding: EdgeInsets.zero,
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      threshold: 35,
                                      maxAngle: 24,
                                      scale: 0.92,
                                      backCardOffset: const Offset(0, 18),
                                      allowedSwipeDirection:
                                          const AllowedSwipeDirection.only(
                                            left: true,
                                            right: true,
                                          ),
                                      onSwipe: _handleSwipe,
                                      onUndo: _handleUndo,
                                      onEnd: () {},
                                      cardBuilder:
                                          (
                                            context,
                                            index,
                                            horizontalOffsetPercentage,
                                            verticalOffsetPercentage,
                                          ) {
                                            final swipeDirection =
                                                horizontalOffsetPercentage < 0
                                                ? CardSwiperDirection.left
                                                : horizontalOffsetPercentage > 0
                                                ? CardSwiperDirection.right
                                                : null;
                                            final swipeProgress =
                                                (horizontalOffsetPercentage
                                                            .abs() /
                                                        100)
                                                    .clamp(0.0, 1.0);
                                            final PhotoModel photo =
                                                queue[index];

                                            return PhotoCard(
                                              imageUrl: photo.imageUrl,
                                              filename: photo.filename,
                                              fileSize: photo.fileSize,
                                              date: photo.date,
                                              isTopCard: index == 0,
                                              stackDepth: index,
                                              swipeDirection: swipeDirection,
                                              swipeProgress: swipeProgress,
                                              dragOffsetX:
                                                  horizontalOffsetPercentage
                                                      .toDouble(),
                                              dragOffsetY:
                                                  verticalOffsetPercentage
                                                      .toDouble(),
                                            );
                                          },
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ActionButton(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          onPressed: queue.isEmpty ? null : _swipeLeft,
                          backgroundColor: AppColors.danger.withValues(
                            alpha: 0.18,
                          ),
                          iconColor: AppColors.danger,
                        ),
                        ActionButton(
                          icon: Icons.undo_rounded,
                          label: 'Undo',
                          onPressed: _session.canUndo ? _undoSwipe : null,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          iconColor: AppColors.textPrimary,
                        ),
                        ActionButton(
                          icon: Icons.favorite_outline_rounded,
                          label: 'Keep',
                          onPressed: queue.isEmpty ? null : _swipeRight,
                          backgroundColor: AppColors.success.withValues(
                            alpha: 0.18,
                          ),
                          iconColor: AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SwipeHeader extends StatelessWidget {
  const _SwipeHeader({
    required this.currentNumber,
    required this.totalPhotos,
    required this.progressValue,
    required this.reviewedCount,
    required this.keptCount,
    required this.deletedCount,
    required this.storageSaved,
  });

  final int currentNumber;
  final int totalPhotos;
  final double progressValue;
  final int reviewedCount;
  final int keptCount;
  final int deletedCount;
  final String storageSaved;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Swipe queue',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Clean up the next photo',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Text(
                  '$currentNumber / $totalPhotos',
                  key: ValueKey('$currentNumber-$totalPhotos'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final chipWidth = constraints.maxWidth >= 560
                ? (constraints.maxWidth - 30) / 4
                : (constraints.maxWidth - 10) / 2;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: chipWidth,
                  child: _HeaderChip(
                    label: 'Reviewed',
                    value: '$reviewedCount',
                  ),
                ),
                SizedBox(
                  width: chipWidth,
                  child: _HeaderChip(label: 'Kept', value: '$keptCount'),
                ),
                SizedBox(
                  width: chipWidth,
                  child: _HeaderChip(label: 'Deleted', value: '$deletedCount'),
                ),
                SizedBox(
                  width: chipWidth,
                  child: _HeaderChip(label: 'Saved', value: storageSaved),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        PremiumGradientProgressBar(value: progressValue, height: 8),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.8),
          radius: 1.1,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.background,
          ],
          stops: const [0, 0.75],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CompletedState extends StatelessWidget {
  const _CompletedState({
    super.key,
    required this.reviewedCount,
    required this.keptCount,
    required this.deletedCount,
    required this.storageSaved,
    required this.onRestart,
    required this.canUndo,
    required this.onUndo,
  });

  final int reviewedCount;
  final int keptCount;
  final int deletedCount;
  final String storageSaved;
  final VoidCallback onRestart;
  final bool canUndo;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          colors: [
            AppColors.card.withValues(alpha: 0.96),
            AppColors.cardElevated.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppColors.softGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.28),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 46,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cleanup Complete',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Every mock photo in this queue has been reviewed. Restart to run the session again or undo to step back.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryPill(
                  title: 'Reviewed',
                  value: '$reviewedCount',
                  accentColor: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryPill(
                  title: 'Kept',
                  value: '$keptCount',
                  accentColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryPill(
                  title: 'Deleted',
                  value: '$deletedCount',
                  accentColor: AppColors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryPill(
                  title: 'Saved',
                  value: storageSaved,
                  accentColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canUndo ? onUndo : null,
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Undo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Restart'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.title,
    required this.value,
    required this.accentColor,
  });

  final String title;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
