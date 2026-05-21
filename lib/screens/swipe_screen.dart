import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../models/photo_model.dart';
import '../utils/app_colors.dart';
import '../widgets/action_button.dart';
import '../widgets/photo_card.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _controller = CardSwiperController();
  final List<PhotoModel> _photos = PhotoModel.mockPhotos;

  int _visibleIndex = 0;
  bool _isCompleted = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<bool> _handleSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    setState(() {
      _visibleIndex = currentIndex ?? (_photos.length - 1);
      _isCompleted = currentIndex == null;
    });
    return true;
  }

  bool _handleUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    setState(() {
      _visibleIndex = currentIndex;
      _isCompleted = false;
    });
    return true;
  }

  void _swipeLeft() {
    if (_isCompleted) {
      return;
    }
    _controller.swipe(CardSwiperDirection.left);
  }

  void _swipeRight() {
    if (_isCompleted) {
      return;
    }
    _controller.swipe(CardSwiperDirection.right);
  }

  void _undoSwipe() {
    _controller.undo();
  }

  @override
  Widget build(BuildContext context) {
    final totalPhotos = _photos.length;
    final progressValue = totalPhotos == 0
        ? 0.0
        : (_visibleIndex + 1).clamp(1, totalPhotos) / totalPhotos;

    return Stack(
      children: [
        const _SwipeBackground(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                _SwipeHeader(
                  currentNumber: totalPhotos == 0 ? 0 : _visibleIndex + 1,
                  totalPhotos: totalPhotos,
                  progressValue: progressValue,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: AspectRatio(
                        aspectRatio: 0.78,
                        child: _isCompleted
                            ? _CompletedState(onReset: _undoSwipe)
                            : CardSwiper(
                                controller: _controller,
                                cardsCount: _photos.length,
                                numberOfCardsDisplayed: 3,
                                isLoop: false,
                                padding: EdgeInsets.zero,
                                duration: const Duration(milliseconds: 260),
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
                                onEnd: () {
                                  if (mounted) {
                                    setState(() {
                                      _isCompleted = true;
                                    });
                                  }
                                },
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

                                      return PhotoCard(
                                        imageUrl: _photos[index].imageUrl,
                                        filename: _photos[index].filename,
                                        fileSize: _photos[index].fileSize,
                                        date: _photos[index].date,
                                        isTopCard: index == _visibleIndex,
                                        swipeDirection: swipeDirection,
                                      );
                                    },
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
                      onPressed: _isCompleted ? null : _swipeLeft,
                      backgroundColor: AppColors.danger.withValues(alpha: 0.18),
                      iconColor: AppColors.danger,
                    ),
                    ActionButton(
                      icon: Icons.undo_rounded,
                      label: 'Undo',
                      onPressed: _visibleIndex == 0 && !_isCompleted
                          ? null
                          : _undoSwipe,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      iconColor: AppColors.textPrimary,
                    ),
                    ActionButton(
                      icon: Icons.favorite_outline_rounded,
                      label: 'Keep',
                      onPressed: _isCompleted ? null : _swipeRight,
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
  }
}

class _SwipeHeader extends StatelessWidget {
  const _SwipeHeader({
    required this.currentNumber,
    required this.totalPhotos,
    required this.progressValue,
  });

  final int currentNumber;
  final int totalPhotos;
  final double progressValue;

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
              child: Text(
                '$currentNumber/$totalPhotos',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progressValue),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: const Color(0xFF334155),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent,
                ),
              );
            },
          ),
        ),
      ],
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
  const _CompletedState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Queue complete',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'You have reviewed every mock photo. Undo to step back through the stack.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Undo last swipe'),
          ),
        ],
      ),
    );
  }
}
