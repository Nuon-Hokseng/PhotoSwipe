import 'package:flutter/material.dart';

import '../animations/premium_animations.dart';
import '../utils/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../widgets/stat_card.dart';
import '../widgets/premium_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onStartCleanup});

  final VoidCallback? onStartCleanup;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumAnimations.fadeSlideIn(
              PremiumSurface(
                padding: const EdgeInsets.all(24),
                borderRadius: 32,
                gradient: AppColors.softGradient,
                shadowColor: AppColors.primary.withOpacity(0.24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PhotoSwipe',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              'Smart local photo cleanup',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.82),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    GradientButton(
                      label: 'Start Cleaning',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: onStartCleanup ?? () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            PremiumAnimations.fadeSlideIn(
              const PremiumSectionHeader(
                title: 'Overview',
                subtitle: 'A compact snapshot of the mock cleanup workspace.',
              ),
              delayMs: 80,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 390;

                return GridView.count(
                  crossAxisCount: isWide ? 2 : 1,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isWide ? 1.28 : 2.6,
                  children: const [
                    StatCard(
                      title: 'Total Photos',
                      value: '1,248',
                      icon: Icons.photo_library_rounded,
                      accentColor: AppColors.primary,
                      subtitle: '+12 today',
                    ),
                    StatCard(
                      title: 'Storage Used',
                      value: '42 GB',
                      icon: Icons.storage_rounded,
                      accentColor: AppColors.accent,
                      subtitle: '78% of device',
                    ),
                    StatCard(
                      title: 'Estimated Cleanup',
                      value: '9.6 GB',
                      icon: Icons.cleaning_services_rounded,
                      accentColor: AppColors.success,
                      subtitle: 'Potential saved',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick cleanup progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    const PremiumGradientProgressBar(value: 0.64, height: 10),
                    const SizedBox(height: 12),
                    PremiumCountText(
                      value: '64% ready for cleanup session',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
