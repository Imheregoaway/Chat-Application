import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF8B84FF);
  static const secondary = Color(0xFF00D9A5);
  static const accent = Color(0xFFFF6B9D);

  static const lightBackground = Color(0xFFF8F9FE);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);

  static const darkBackground = Color(0xFF0D0D1A);
  static const darkSurface = Color(0xFF16162A);
  static const darkCard = Color(0xFF1E1E35);

  static const sentBubbleLight = Color(0xFF6C63FF);
  static const receivedBubbleLight = Color(0xFFE8E9F3);
  static const sentBubbleDark = Color(0xFF6C63FF);
  static const receivedBubbleDark = Color(0xFF252540);

  static const online = Color(0xFF00D9A5);
  static const offline = Color(0xFF9E9EB8);
  static const typing = Color(0xFFFFB347);

  static const gradientStart = Color(0xFF6C63FF);
  static const gradientMid = Color(0xFF9B59B6);
  static const gradientEnd = Color(0xFF00D9A5);

  static List<Color> avatarPalette = const [
    Color(0xFF6C63FF),
    Color(0xFF00D9A5),
    Color(0xFFFF6B9D),
    Color(0xFFFFB347),
    Color(0xFF3498DB),
    Color(0xFFE74C3C),
    Color(0xFF1ABC9C),
    Color(0xFF9B59B6),
  ];
}
