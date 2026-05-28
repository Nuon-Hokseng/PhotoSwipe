import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class PremiumAnimations {
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration premium = Duration(milliseconds: 460);

  static Widget fadeSlideIn(
    Widget child, {
    int delayMs = 0,
    Offset begin = const Offset(0, 0.12),
    Duration duration = premium,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration + Duration(milliseconds: delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final t = value.clamp(0.0, 1.0);

        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(begin.dx * (1 - t) * 64, begin.dy * (1 - t) * 64),
            child: Transform.scale(scale: 0.985 + (0.015 * t), child: child),
          ),
        );
      },
    );
  }
}

class PremiumCountText extends StatelessWidget {
  const PremiumCountText({
    super.key,
    required this.value,
    required this.style,
    this.duration = PremiumAnimations.premium,
    this.textAlign,
  });

  final String value;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final match = RegExp(
      r'^\s*([0-9,]+(?:\.[0-9]+)?)\s*(.*)$',
    ).firstMatch(value);
    if (match == null) {
      return Text(value, style: style, textAlign: textAlign);
    }

    final parsedValue = double.tryParse(match.group(1)!.replaceAll(',', ''));
    if (parsedValue == null) {
      return Text(value, style: style, textAlign: textAlign);
    }

    final suffix = match.group(2)?.trim() ?? '';
    final isWhole = parsedValue == parsedValue.roundToDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: parsedValue),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final displayValue = isWhole
            ? animatedValue.round().toString()
            : animatedValue.toStringAsFixed(1);
        final text = suffix.isEmpty ? displayValue : '$displayValue $suffix';

        return Text(text, style: style, textAlign: textAlign);
      },
    );
  }
}

class PremiumShimmer extends StatefulWidget {
  const PremiumShimmer({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = 16,
    this.baseColor = const Color(0xFF243044),
    this.highlightColor = const Color(0xFF394860),
  });

  final double height;
  final double? width;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;

  @override
  State<PremiumShimmer> createState() => _PremiumShimmerState();
}

class _PremiumShimmerState extends State<PremiumShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmerPosition = _controller.value * 2 - 1;

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.4 + shimmerPosition * 1.1, -0.2),
              end: Alignment(0.8 + shimmerPosition * 1.1, 0.2),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.15, 0.5, 0.85],
            ),
          ),
        );
      },
    );
  }
}

class PremiumGradientProgressBar extends StatelessWidget {
  const PremiumGradientProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.borderRadius = 999,
  });

  final double value;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * value.clamp(0.0, 1.0);

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            height: height,
            color: const Color(0xFF243044),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: PremiumAnimations.standard,
                curve: Curves.easeOutCubic,
                width: width,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PremiumMetricSkeleton extends StatelessWidget {
  const PremiumMetricSkeleton({super.key, this.height = 12, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return PremiumShimmer(height: height, width: width, borderRadius: 12);
  }
}

class PremiumSuccessPulse extends StatefulWidget {
  const PremiumSuccessPulse({super.key, required this.child});

  final Widget child;

  @override
  State<PremiumSuccessPulse> createState() => _PremiumSuccessPulseState();
}

class _PremiumSuccessPulseState extends State<PremiumSuccessPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final lift = math.sin(_controller.value * math.pi) * 2.5;

        return Transform.translate(offset: Offset(0, -lift), child: child);
      },
      child: widget.child,
    );
  }
}
