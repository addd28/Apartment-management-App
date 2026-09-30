import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;

  Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/Auth/login',
        data: {
          'username': username.trim(),
          'password': password,
        },
      );

      final data = response.data;
      final token = data['token'] ?? '';
      final role = (data['role'] ?? '').toString().toUpperCase();

      if (token.isEmpty) {
        throw Exception('Phản hồi đăng nhập không hợp lệ (thiếu token).');
      }

      await StorageService.saveToken(token);

      // Fetch user profile immediately
      UserModel? user;
      try {
        user = await getProfile();
        await StorageService.saveUser(user);
      } catch (_) {
        // Fallback user from login if me fails
        user = UserModel(
          id: 0,
          username: username,
          fullName: username,
          role: role,
        );
      }

      // Sync FCM device token with backend
      try {
        NotificationService().syncDeviceToken();
      } catch (_) {}

      return LoginResponse(
        token: token,
        role: role,
        user: user,
      );
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/Users/me');
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<UserModel> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final response = await _dio.put(
        '/Users/me',
        data: {
          'fullName': fullName.trim(),
          'phoneNumber': phoneNumber?.trim(),
          'email': email?.trim(),
        },
      );
      final user = UserModel.fromJson(response.data);
      await StorageService.saveUser(user);
      return user;
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.put(
        '/Users/me/password',
        data: {
          'currentPassword': oldPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmPassword,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      await NotificationService().deactivateCurrentToken();
    } catch (_) {}
    await StorageService.clearAll();
  }
}