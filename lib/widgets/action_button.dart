import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: isEnabled
              ? (_) {
                  setState(() {
                    _pressed = true;
                  });
                }
              : null,
          onTapUp: isEnabled
              ? (_) {
                  setState(() {
                    _pressed = false;
                  });
                  widget.onPressed?.call();
                }
              : null,
          onTapCancel: isEnabled
              ? () {
                  setState(() {
                    _pressed = false;
                  });
                }
              : null,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Material(
              color: widget.backgroundColor,
              shape: const CircleBorder(),
              elevation: 14,
              shadowColor: Colors.black.withValues(alpha: 0.32),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: Icon(widget.icon, color: widget.iconColor, size: 28),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
