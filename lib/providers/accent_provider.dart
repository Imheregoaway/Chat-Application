import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_accent_theme.dart';
import '../models/accent_preset.dart';
import '../models/bubble_style.dart';

class AccentProvider extends ChangeNotifier {
  static const _accentKey = 'accent_preset';
  static const _bubbleKey = 'bubble_style';

  AccentPreset _preset = AccentPreset.violet;
  BubbleStyle _bubbleStyle = BubbleStyle.glass;
  bool _loaded = false;

  AccentPreset get preset => _preset;
  BubbleStyle get bubbleStyle => _bubbleStyle;
  bool get loaded => _loaded;
  AppAccentTheme get accentTheme =>
      AppAccentTheme.fromPreset(_preset, _bubbleStyle);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final accentIdx = prefs.getInt(_accentKey);
    final bubbleIdx = prefs.getInt(_bubbleKey);
    if (accentIdx != null && accentIdx < AccentPreset.values.length) {
      _preset = AccentPreset.values[accentIdx];
    }
    if (bubbleIdx != null && bubbleIdx < BubbleStyle.values.length) {
      _bubbleStyle = BubbleStyle.values[bubbleIdx];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPreset(AccentPreset preset) async {
    if (_preset == preset) return;
    _preset = preset;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, preset.index);
  }

  Future<void> setBubbleStyle(BubbleStyle style) async {
    if (_bubbleStyle == style) return;
    _bubbleStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bubbleKey, style.index);
  }
}
