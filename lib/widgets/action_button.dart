import 'dart:ui';

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
            child: AnimatedOpacity(
              opacity: isEnabled ? 1 : 0.45,
              duration: const Duration(milliseconds: 160),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Material(
                    color: widget.backgroundColor.withValues(alpha: 0.86),
                    shape: const CircleBorder(),
                    elevation: isEnabled ? 16 : 6,
                    shadowColor: Colors.black.withValues(alpha: 0.35),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onPressed,
                      child: SizedBox(
                        width: 74,
                        height: 74,
                        child: Icon(
                          widget.icon,
                          color: widget.iconColor,
                          size: 29,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isEnabled
                ? AppColors.textSecondary
                : AppColors.textSecondary.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
