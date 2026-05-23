import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../utils/app_colors.dart';

class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    required this.imageUrl,
    required this.filename,
    required this.fileSize,
    required this.date,
    required this.isTopCard,
    this.swipeDirection,
    this.swipeProgress = 0,
  });

  final String imageUrl;
  final String filename;
  final String fileSize;
  final String date;
  final bool isTopCard;
  final CardSwiperDirection? swipeDirection;
  final double swipeProgress;

  @override
  Widget build(BuildContext context) {
    final shouldShowDelete = swipeDirection == CardSwiperDirection.left;
    final shouldShowKeep = swipeDirection == CardSwiperDirection.right;
    final swipeAmount = swipeProgress.clamp(0.0, 1.0);
    final swipeColor = shouldShowDelete
        ? AppColors.danger
        : shouldShowKeep
        ? AppColors.success
        : AppColors.primary;
    final cardScale = isTopCard ? 1.0 : 0.975;
    final cardElevation = isTopCard ? 30.0 : 18.0;
    final borderGlow = isTopCard
        ? swipeColor.withValues(alpha: 0.18 + (swipeAmount * 0.18))
        : Colors.white.withValues(alpha: 0.05);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.94, end: cardScale),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: borderGlow),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isTopCard ? 0.42 : 0.28),
              blurRadius: cardElevation,
              offset: const Offset(0, 18),
            ),
            if (isTopCard)
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.10),
                blurRadius: 30,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return Container(
                    color: AppColors.card,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator.adaptive(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.card,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_rounded,
                      color: AppColors.textSecondary,
                      size: 42,
                    ),
                  );
                },
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x140F172A),
                      Color(0x080F172A),
                      Color(0xB80F172A),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              if (isTopCard)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: swipeAmount * 0.24,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: swipeDirection == CardSwiperDirection.left
                              ? [
                                  AppColors.danger.withValues(alpha: 0.38),
                                  Colors.transparent,
                                ]
                              : swipeDirection == CardSwiperDirection.right
                              ? [
                                  AppColors.success.withValues(alpha: 0.34),
                                  Colors.transparent,
                                ]
                              : [
                                  AppColors.primary.withValues(alpha: 0.20),
                                  Colors.transparent,
                                ],
                          begin: swipeDirection == CardSwiperDirection.left
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          end: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                left: 16,
                child: _SwipeLabel(
                  visible: shouldShowDelete,
                  label: 'DELETE',
                  color: AppColors.danger,
                  rotation: -0.08,
                  opacity: swipeDirection == null ? 0 : swipeAmount,
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: _SwipeLabel(
                  visible: shouldShowKeep,
                  label: 'KEEP',
                  color: AppColors.success,
                  rotation: 0.08,
                  opacity: swipeDirection == null ? 0 : swipeAmount,
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _MetaChip(
                                icon: Icons.photo_size_select_large_rounded,
                                text: fileSize,
                              ),
                              const SizedBox(width: 8),
                              _MetaChip(
                                icon: Icons.calendar_month_rounded,
                                text: date,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        'Mock photo',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeLabel extends StatelessWidget {
  const _SwipeLabel({
    required this.visible,
    required this.label,
    required this.color,
    required this.rotation,
    required this.opacity,
  });

  final bool visible;
  final String label;
  final Color color;
  final double rotation;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? opacity.clamp(0.0, 1.0) : 0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Transform.rotate(
        angle: rotation,
        child: AnimatedScale(
          scale: visible ? 0.92 + (opacity.clamp(0.0, 1.0) * 0.12) : 0.92,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
