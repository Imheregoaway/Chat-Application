import 'package:shared_preferences/shared_preferences.dart';

class ApiConfigService {
  static const _baseUrlKey = 'backend_base_url';

  /// Local dev default. Override when building for production:
  /// `flutter build web --dart-define=API_BASE_URL=https://your-api.onrender.com`
  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv.replaceAll(RegExp(r'/$'), '');
    }
    return 'http://127.0.0.1:8000';
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
  }

  Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url.trim().replaceAll(RegExp(r'/$'), ''));
  }
}
