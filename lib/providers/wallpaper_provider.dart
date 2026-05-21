import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_wallpaper.dart';

class WallpaperProvider extends ChangeNotifier {
  static const _key = 'chat_wallpaper';

  ChatWallpaper _wallpaper = ChatWallpaper.aurora;
  bool _loaded = false;

  ChatWallpaper get wallpaper => _wallpaper;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key);
    if (index != null && index >= 0 && index < ChatWallpaper.values.length) {
      _wallpaper = ChatWallpaper.values[index];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setWallpaper(ChatWallpaper value) async {
    if (_wallpaper == value) return;
    _wallpaper = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value.index);
  }
}
