import 'package:flutter/material.dart';

import '../../models/accent_preset.dart';
import '../../models/bubble_style.dart';

class AppAccentTheme extends ThemeExtension<AppAccentTheme> {
  const AppAccentTheme({
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.bubbleStyle,
  });

  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final BubbleStyle bubbleStyle;

  factory AppAccentTheme.fromPreset(AccentPreset preset, BubbleStyle style) {
    return AppAccentTheme(
      primary: preset.primary,
      primaryLight: preset.primaryLight,
      secondary: preset.secondary,
      bubbleStyle: style,
    );
  }

  static AppAccentTheme defaultTheme() =>
      AppAccentTheme.fromPreset(AccentPreset.violet, BubbleStyle.glass);

  @override
  AppAccentTheme copyWith({
    Color? primary,
    Color? primaryLight,
    Color? secondary,
    BubbleStyle? bubbleStyle,
  }) {
    return AppAccentTheme(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      secondary: secondary ?? this.secondary,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
    );
  }

  @override
  AppAccentTheme lerp(ThemeExtension<AppAccentTheme>? other, double t) {
    if (other is! AppAccentTheme) return this;
    return AppAccentTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      bubbleStyle: t < 0.5 ? bubbleStyle : other.bubbleStyle,
    );
  }
}
