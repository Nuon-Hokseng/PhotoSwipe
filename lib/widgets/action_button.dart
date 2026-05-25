import 'dart:ui';

import 'package:flutter/material.dart';

import '../animations/premium_animations.dart';
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
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final scale = _pressed
        ? 0.92
        : _hovered
        ? 1.04
        : 1.0;
    final glowStrength = _pressed
        ? 0.24
        : _hovered
        ? 0.40
        : 0.34;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: isEnabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: isEnabled
              ? (_) {
                  setState(() {
                    _hovered = true;
                  });
                }
              : null,
          onExit: isEnabled
              ? (_) {
                  setState(() {
                    _hovered = false;
                  });
                }
              : null,
          child: GestureDetector(
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
              scale: scale,
              duration: PremiumAnimations.quick,
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: isEnabled ? 1 : 0.45,
                duration: PremiumAnimations.quick,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: AnimatedContainer(
                      duration: PremiumAnimations.quick,
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            widget.backgroundColor.withValues(alpha: 0.92),
                            widget.backgroundColor.withValues(alpha: 0.74),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.iconColor.withValues(
                              alpha: glowStrength,
                            ),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        elevation: 0,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          splashColor: widget.iconColor.withValues(alpha: 0.12),
                          highlightColor: widget.iconColor.withValues(
                            alpha: 0.08,
                          ),
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
