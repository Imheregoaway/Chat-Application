import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/chat_wallpaper.dart';

/// Full-screen animated wallpaper with readability scrim for chat content.
class ChatWallpaperBackground extends StatefulWidget {
  const ChatWallpaperBackground({
    super.key,
    required this.wallpaper,
    required this.child,
  });

  final ChatWallpaper wallpaper;
  final Widget child;

  @override
  State<ChatWallpaperBackground> createState() => _ChatWallpaperBackgroundState();
}

class _ChatWallpaperBackgroundState extends State<ChatWallpaperBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _WallpaperPainter(
                wallpaper: widget.wallpaper,
                progress: _controller.value * 2 * math.pi,
                isDark: isDark,
              ),
              size: Size.infinite,
            ),
            // Scrim keeps bubbles and text readable on busy wallpapers
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: isDark ? 0.08 : 0.12),
                    (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: isDark ? 0.22 : 0.28),
                  ],
                ),
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

class _WallpaperPainter extends CustomPainter {
  _WallpaperPainter({
    required this.wallpaper,
    required this.progress,
    required this.isDark,
  });

  final ChatWallpaper wallpaper;
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    switch (wallpaper) {
      case ChatWallpaper.aurora:
        _paintAurora(canvas, size);
      case ChatWallpaper.sunset:
        _paintSunset(canvas, size);
      case ChatWallpaper.ocean:
        _paintOcean(canvas, size);
      case ChatWallpaper.forest:
        _paintForest(canvas, size);
      case ChatWallpaper.midnight:
        _paintMidnight(canvas, size);
      case ChatWallpaper.mesh:
        _paintMesh(canvas, size);
    }
  }

  void _fillBase(Canvas canvas, Size size, List<Color> colors) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );
  }

  void _paintBlob(
    Canvas canvas,
    Size size, {
    required Color color,
    required double cx,
    required double cy,
    required double radius,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, paint);
  }

  void _paintAurora(Canvas canvas, Size size) {
    _fillBase(
      canvas,
      size,
      isDark
          ? [const Color(0xFF0D0D1A), const Color(0xFF16162A)]
          : [const Color(0xFFF8F9FE), const Color(0xFFEEF0FF)],
    );
    final t = progress;
    final opacity = isDark ? 0.4 : 0.28;
    _paintBlob(
      canvas,
      size,
      color: AppColors.primary.withValues(alpha: opacity),
      cx: size.width * (0.2 + 0.1 * math.sin(t)),
      cy: size.height * (0.12 + 0.06 * math.cos(t * 0.7)),
      radius: size.width * 0.5,
    );
    _paintBlob(
      canvas,
      size,
      color: AppColors.secondary.withValues(alpha: opacity * 0.85),
      cx: size.width * (0.88 + 0.06 * math.cos(t * 1.1)),
      cy: size.height * (0.22 + 0.08 * math.sin(t * 0.9)),
      radius: size.width * 0.42,
    );
    _paintBlob(
      canvas,
      size,
      color: AppColors.accent.withValues(alpha: opacity * 0.55),
      cx: size.width * (0.45 + 0.14 * math.sin(t * 0.5)),
      cy: size.height * (0.78 + 0.06 * math.cos(t)),
      radius: size.width * 0.38,
    );
  }

  void _paintSunset(Canvas canvas, Size size) {
    _fillBase(
      canvas,
      size,
      [
        const Color(0xFF1A1035),
        const Color(0xFF4A1942),
        Color.lerp(const Color(0xFFFF6B35), const Color(0xFFFFB347), 0.5)!,
      ],
    );
    _paintBlob(
      canvas,
      size,
      color: const Color(0xFFFF6B9D).withValues(alpha: 0.45),
      cx: size.width * (0.7 + 0.05 * math.sin(progress)),
      cy: size.height * 0.35,
      radius: size.width * 0.55,
    );
    _paintBlob(
      canvas,
      size,
      color: const Color(0xFFFFB347).withValues(alpha: 0.35),
      cx: size.width * 0.25,
      cy: size.height * (0.55 + 0.05 * math.cos(progress * 0.8)),
      radius: size.width * 0.45,
    );
  }

  void _paintOcean(Canvas canvas, Size size) {
    _fillBase(
      canvas,
      size,
      [
        const Color(0xFF021526),
        const Color(0xFF03396C),
        const Color(0xFF0A6EBD),
      ],
    );
    for (var i = 0; i < 3; i++) {
      final waveY = size.height * (0.45 + i * 0.12) +
          18 * math.sin(progress + i * 1.2);
      final path = Path()
        ..moveTo(0, waveY)
        ..quadraticBezierTo(
          size.width * 0.25,
          waveY - 40,
          size.width * 0.5,
          waveY,
        )
        ..quadraticBezierTo(
          size.width * 0.75,
          waveY + 40,
          size.width,
          waveY,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF00D9A5),
            const Color(0xFF3498DB),
            i / 3,
          )!
              .withValues(alpha: 0.12 + i * 0.04),
      );
    }
    _paintBlob(
      canvas,
      size,
      color: const Color(0xFF00D9A5).withValues(alpha: 0.2),
      cx: size.width * 0.8,
      cy: size.height * 0.15,
      radius: size.width * 0.35,
    );
  }

  void _paintForest(Canvas canvas, Size size) {
    _fillBase(
      canvas,
      size,
      [
        const Color(0xFF0B1F14),
        const Color(0xFF1B4332),
        const Color(0xFF2D6A4F),
      ],
    );
    _paintBlob(
      canvas,
      size,
      color: const Color(0xFF95D5B2).withValues(alpha: 0.25),
      cx: size.width * 0.3,
      cy: size.height * 0.2,
      radius: size.width * 0.5,
    );
    _paintBlob(
      canvas,
      size,
      color: const Color(0xFF1ABC9C).withValues(alpha: 0.18),
      cx: size.width * 0.85,
      cy: size.height * 0.7,
      radius: size.width * 0.4,
    );
    // Soft light rays
    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.1 + i * 0.18);
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 40, size.height),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.04),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(x, 0, 40, size.height)),
      );
    }
  }

  void _paintMidnight(Canvas canvas, Size size) {
    _fillBase(
      canvas,
      size,
      [const Color(0xFF050510), const Color(0xFF12122A), const Color(0xFF1E1E45)],
    );
    final rng = math.Random(42);
    for (var i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final twinkle = 0.4 + 0.6 * math.sin(progress * 2 + i);
      canvas.drawCircle(
        Offset(x, y),
        (rng.nextDouble() * 1.8 + 0.4) * twinkle,
        Paint()..color = Colors.white.withValues(alpha: 0.15 + rng.nextDouble() * 0.5),
      );
    }
    _paintBlob(
      canvas,
      size,
      color: AppColors.primary.withValues(alpha: 0.35),
      cx: size.width * 0.5,
      cy: size.height * 0.85,
      radius: size.width * 0.6,
    );
  }

  void _paintMesh(Canvas canvas, Size size) {
    _fillBase(canvas, size, [const Color(0xFF0F0C29), const Color(0xFF302B63), const Color(0xFF24243E)]);
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.gradientMid,
    ];
    for (var i = 0; i < colors.length; i++) {
      final angle = progress + i * math.pi / 2;
      _paintBlob(
        canvas,
        size,
        color: colors[i].withValues(alpha: 0.35),
        cx: size.width * (0.5 + 0.35 * math.cos(angle)),
        cy: size.height * (0.5 + 0.35 * math.sin(angle)),
        radius: size.width * 0.42,
      );
    }
  }

  @override
  bool shouldRepaint(_WallpaperPainter old) =>
      old.progress != progress ||
      old.wallpaper != wallpaper ||
      old.isDark != isDark;
}

/// Small preview tile for wallpaper picker in settings.
class WallpaperPreview extends StatelessWidget {
  const WallpaperPreview({
    super.key,
    required this.wallpaper,
    required this.selected,
    required this.onTap,
  });

  final ChatWallpaper wallpaper;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _WallpaperPainter(
                  wallpaper: wallpaper,
                  progress: 0,
                  isDark: true,
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  wallpaper.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
