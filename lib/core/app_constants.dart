import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Chung Cư Xanh - Resident';

  // Base API URLs
  // On Android Emulator, host machine localhost is 10.0.2.2
  // On Windows Desktop / Web, host machine is localhost
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5131/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5131/api';
    }
    return 'http://localhost:5131/api';
  }

  // Fallback / MinIO base URL for static images if full URL not returned
  static String get defaultMinioUrl {
    if (kIsWeb) {
      return 'http://localhost:9000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:9000';
    }
    return 'http://localhost:9000';
  }

  // Storage Keys
  static const String keyToken = 'jwt_token';
  static const String keyUserData = 'user_data';
  static const String keyCustomBaseUrl = 'custom_base_url';
  static const String keyFcmToken = 'fcm_token';

  // Theme Colors
  static const Color primaryColor = Color(0xFF1E5BB0); // Deep rich royal blue
  static const Color primaryDark = Color(0xFF0F3670);
  static const Color primaryLight = Color(0xFFE8F1FC);
  static const Color accentColor = Color(0xFF00B4D8); // Bright sky cyan
  static const Color secondaryColor = Color(0xFF10B981); // Fresh Emerald
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color dangerColor = Color(0xFFEF4444); // Crimson
  static const Color backgroundColor = Color(0xFFF8FAFC); // Clean slate background
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
}