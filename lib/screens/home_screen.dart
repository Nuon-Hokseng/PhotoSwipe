import 'package:flutter/material.dart';

import '../animations/premium_animations.dart';
import '../controllers/swipe_session_controller.dart';
import '../utils/app_colors.dart';
import '../utils/storage_formatters.dart';
import '../widgets/gradient_button.dart';
import '../widgets/stat_card.dart';
import '../widgets/premium_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onStartCleanup});

  final VoidCallback? onStartCleanup;

  @override
  Widget build(BuildContext context) {
    final session = SwipeSessionController.instance;

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final isLoading = session.isLoading;
        final totalPhotos = session.galleryTotalPhotos;
        final totalStorage = session.galleryTotalBytes;
        final estimatedCleanup = session.estimatedCleanupBytes;
        final storageValue = isLoading
            ? '—'
            : formatStorageBytes(totalStorage);
        final cleanupValue = isLoading
            ? '—'
            : formatStorageBytes(estimatedCleanup);
        final totalValue = isLoading ? '—' : '$totalPhotos';
        final reviewedValue = isLoading ? '—' : '${session.reviewedCount}';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumAnimations.fadeSlideIn(
                  const PremiumSectionHeader(
                    title: 'Overview',
                    subtitle: 'A compact snapshot of your cleanup workspace.',
                  ),
                  delayMs: 80,
                ),
                const SizedBox(height: 10),
                // Stat cards — flex grows to fill available space
                Expanded(
                  flex: 5,
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    children: [
                      StatCard(
                        title: 'Total Photos',
                        value: totalValue,
                        icon: Icons.photo_library_rounded,
                        accentColor: AppColors.primary,
                        subtitle: 'Gallery total',
                      ),
                      StatCard(
                        title: 'Storage Used',
                        value: storageValue,
                        icon: Icons.storage_rounded,
                        accentColor: AppColors.accent,
                        subtitle: 'Photo storage',
                      ),
                      StatCard(
                        title: 'Est. Cleanup',
                        value: cleanupValue,
                        icon: Icons.cleaning_services_rounded,
                        accentColor: AppColors.success,
                        subtitle: 'Suggested reclaim',
                      ),
                      StatCard(
                        title: 'Reviewed',
                        value: reviewedValue,
                        icon: Icons.fact_check_rounded,
                        accentColor: AppColors.danger,
                        subtitle: 'Session progress',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // ↕ Banner height — change this one value to resize the banner
                SizedBox(
                  height: 170,
                  child: PremiumAnimations.fadeSlideIn(
                    PremiumSurface(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      borderRadius: 22,
                      gradient: AppColors.softGradient,
                      shadowColor: AppColors.primary.withOpacity(0.24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'PhotoSwipe',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Smart local photo cleanup',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.white.withOpacity(0.75)),
                                ),
                                const SizedBox(height: 16),
                                GradientButton(
                                  label: 'Start Cleaning',
                                  icon: Icons.arrow_forward_rounded,
                                  onPressed: onStartCleanup ?? () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Quick cleanup progress — real data, more visual weight
                Expanded(
                  flex: 2,
                  child: PremiumAnimations.fadeSlideIn(
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cleanup progress',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                isLoading
                                    ? '—'
                                    : totalPhotos == 0
                                        ? '0%'
                                        : '${((session.reviewedCount / totalPhotos) * 100).round()}%',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          PremiumGradientProgressBar(
                            value: isLoading || totalPhotos == 0
                                ? 0.0
                                : (session.reviewedCount / totalPhotos).clamp(0.0, 1.0),
                            height: 9,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _ProgressStat(
                                label: 'Reviewed',
                                value: isLoading ? '—' : '${session.reviewedCount}',
                                color: AppColors.accent,
                              ),
                              _ProgressStat(
                                label: 'Est. freed',
                                value: isLoading ? '—' : formatStorageBytes(estimatedCleanup),
                                color: AppColors.success,
                              ),
                              _ProgressStat(
                                label: 'Remaining',
                                value: isLoading
                                    ? '—'
                                    : '${(totalPhotos - session.reviewedCount).clamp(0, totalPhotos)}',
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
