import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';

  Locale _locale = const Locale('en');
  bool _loaded = false;

  Locale get locale => _locale;
  bool get loaded => _loaded;
  AppLocalizations get strings => AppLocalizations.of(_locale);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      _locale = Locale(code);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  /// Speech recognition locale id (approximate).
  String get speechLocaleId {
    return switch (_locale.languageCode) {
      'es' => 'es_ES',
      'fr' => 'fr_FR',
      'de' => 'de_DE',
      'hi' => 'hi_IN',
      _ => 'en_US',
    };
  }
}
