import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyToken = 'auth_token';
  static const String keyUsername = 'auth_username';
  static const String keyRoles = 'auth_roles';

  static Future<void> saveSession({
    required String token,
    required String username,
    required List<String> roles,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
    await prefs.setString(keyUsername, username);
    await prefs.setStringList(keyRoles, roles);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUsername);
  }

  static Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(keyRoles) ?? [];
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyToken);
    await prefs.remove(keyUsername);
    await prefs.remove(keyRoles);
  }
}
