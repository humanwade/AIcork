import 'package:shared_preferences/shared_preferences.dart';

/// Simple in-memory + SharedPreferences token storage.
class TokenStorage {
  TokenStorage._();

  static const _key = 'auth_token';
  static String? _cachedToken;

  static String? get token => _cachedToken;

  static Future<void> setToken(String? value) async {
    _cachedToken = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, value);
    }
  }

  static Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_key);
  }
}

