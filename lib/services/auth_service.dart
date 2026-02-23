import 'dart:convert';
import '../models/user_model.dart';
import '../models/auth_response_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../config/api_config.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    return await _apiService.post(
      ApiConfig.sendOTP,
      data: {'phone_number': phoneNumber},
    );
  }

  Future<Map<String, dynamic>> verifyOTP(
      String phoneNumber, String otpCode) async {
    return await _apiService.post(
      ApiConfig.verifyOTP,
      data: {
        'phone_number': phoneNumber,
        'otp_code': otpCode,
      },
    );
  }

  Future<AuthResponse> register(Map<String, dynamic> userData) async {
    final response = await _apiService.post(
      ApiConfig.register,
      data: userData,
    );

    final authResponse = AuthResponse.fromJson(response);

    if (authResponse.success && authResponse.tokens != null) {
      await StorageService.saveAccessToken(authResponse.tokens!.accessToken);
      if (authResponse.tokens!.refreshToken != null) {
        await StorageService.saveRefreshToken(
            authResponse.tokens!.refreshToken!);
      }
      if (authResponse.user != null) {
        await StorageService.saveUserData(jsonEncode(authResponse.user!.toJson()));
      }
    }

    return authResponse;
  }

  Future<AuthResponse> login(
      String phoneNumber,
      String password,
      bool rememberMe,
      ) async {
    final response = await _apiService.post(
      ApiConfig.login,
      data: {
        'phone_number': phoneNumber,
        'password': password,
        'remember_me': rememberMe,
      },
    );

    final authResponse = AuthResponse.fromJson(response);

    if (authResponse.success && authResponse.tokens != null) {
      await StorageService.saveAccessToken(authResponse.tokens!.accessToken);
      if (authResponse.tokens!.refreshToken != null) {
        await StorageService.saveRefreshToken(
            authResponse.tokens!.refreshToken!);
      }
      if (authResponse.user != null) {
        await StorageService.saveUserData(jsonEncode(authResponse.user!.toJson()));
      }
      await StorageService.saveRememberMe(rememberMe);
    }

    return authResponse;
  }

  Future<void> logout() async {
    final refreshToken = await StorageService.getRefreshToken();

    try {
      await _apiService.post(
        ApiConfig.logout,
        data: {'refresh_token': refreshToken},
      );
    } catch (e) {
      // Continue with logout even if API call fails
    }

    await StorageService.clearAll();
  }

  Future<User?> getProfile() async {
    try {
      final response = await _apiService.get(ApiConfig.profile);
      if (response['success']) {
        return User.fromJson(response['data']['user']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    final userData = StorageService.getUserData();
    if (userData != null) {
      try {
        return User.fromJson(jsonDecode(userData));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final token = await StorageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}