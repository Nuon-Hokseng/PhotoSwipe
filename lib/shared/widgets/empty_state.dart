import 'package:background_remover/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: kColorStatNeutral),
              const SizedBox(height: 12),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ],
              if (action != null) ...[const SizedBox(height: 12), action!],
            ],
          ),
        ),
      );
}
