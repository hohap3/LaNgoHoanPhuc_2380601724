import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String appTitle = 'Phân Quyền & Quản Lý Người Dùng';
  static const String defaultBaseUrl = 'https://5x6pn4j8-7162.asse.devtunnels.ms/api';
  static const String keyCustomBaseUrl = 'custom_base_url';

  // Role constants
  static const String roleAdmin = 'Admin';
  static const String roleStaff = 'Staff';
  static const String roleCustomer = 'Customer';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String url = prefs.getString(keyCustomBaseUrl) ?? defaultBaseUrl;
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    String trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    await prefs.setString(keyCustomBaseUrl, trimmed);
  }

  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyCustomBaseUrl);
  }

  // App Theme Palette (Modern Indigo / Violet gradient)
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF3730A3);  // Indigo 800
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color accentColor = Color(0xFF06B6D4);  // Cyan 500
  static const Color successColor = Color(0xFF10B981); // Emerald 500
  static const Color warningColor = Color(0xFFF59E0B); // Amber 500
  static const Color dangerColor = Color(0xFFEF4444);  // Rose 500
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
}
