import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  final Widget child;
  final double intensity;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: base),
            CustomPaint(
              painter: _BlobPainter(
                progress: t,
                isDark: isDark,
                intensity: widget.intensity,
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({
    required this.progress,
    required this.isDark,
    required this.intensity,
  });

  final double progress;
  final bool isDark;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = isDark ? 0.35 : 0.25;
    final blobs = [
      (
        color: AppColors.primary.withValues(alpha: opacity * intensity),
        cx: size.width * (0.2 + 0.1 * math.sin(progress)),
        cy: size.height * (0.15 + 0.08 * math.cos(progress * 0.7)),
        radius: size.width * 0.45,
      ),
      (
        color: AppColors.secondary.withValues(alpha: opacity * 0.8 * intensity),
        cx: size.width * (0.85 + 0.08 * math.cos(progress * 1.2)),
        cy: size.height * (0.25 + 0.1 * math.sin(progress * 0.9)),
        radius: size.width * 0.4,
      ),
      (
        color: AppColors.accent.withValues(alpha: opacity * 0.6 * intensity),
        cx: size.width * (0.5 + 0.12 * math.sin(progress * 0.5)),
        cy: size.height * (0.75 + 0.08 * math.cos(progress)),
        radius: size.width * 0.35,
      ),
    ];

    for (final blob in blobs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [blob.color, blob.color.withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(blob.cx, blob.cy),
            radius: blob.radius,
          ),
        );
      canvas.drawCircle(Offset(blob.cx, blob.cy), blob.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
