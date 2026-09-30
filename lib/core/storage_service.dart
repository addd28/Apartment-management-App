import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_constants.dart';
import '../models/user_model.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> saveToken(String token) async {
    await init();
    return await _prefs!.setString(AppConstants.keyToken, token);
  }

  static String? getToken() {
    return _prefs?.getString(AppConstants.keyToken);
  }

  static bool hasToken() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> saveUser(UserModel user) async {
    await init();
    final jsonStr = jsonEncode(user.toJson());
    return await _prefs!.setString(AppConstants.keyUserData, jsonStr);
  }

  static UserModel? getUser() {
    final jsonStr = _prefs?.getString(AppConstants.keyUserData);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr);
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveFcmToken(String token) async {
    await init();
    return await _prefs!.setString(AppConstants.keyFcmToken, token);
  }

  static String? getFcmToken() {
    return _prefs?.getString(AppConstants.keyFcmToken);
  }

  static Future<bool> removeFcmToken() async {
    await init();
    return await _prefs!.remove(AppConstants.keyFcmToken);
  }

  static Future<bool> saveBaseUrl(String url) async {
    await init();
    return await _prefs!.setString(AppConstants.keyCustomBaseUrl, url);
  }

  static String getBaseUrl() {
    final custom = _prefs?.getString(AppConstants.keyCustomBaseUrl);
    if (custom != null && custom.isNotEmpty) return custom;
    return AppConstants.defaultBaseUrl;
  }

  static Future<void> clearAll() async {
    await init();
    await _prefs!.remove(AppConstants.keyToken);
    await _prefs!.remove(AppConstants.keyUserData);
    // keep FCM token or clear it as needed
  }
}