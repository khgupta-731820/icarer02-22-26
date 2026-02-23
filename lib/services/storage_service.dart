import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure Storage (for tokens)
  static Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: 'access_token', value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  static Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: 'refresh_token', value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  static Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  // Shared Preferences (for user data)
  static Future<void> saveUserData(String userData) async {
    await _prefs?.setString('user_data', userData);
  }

  static String? getUserData() {
    return _prefs?.getString('user_data');
  }

  static Future<void> saveRememberMe(bool value) async {
    await _prefs?.setBool('remember_me', value);
  }

  static bool getRememberMe() {
    return _prefs?.getBool('remember_me') ?? false;
  }

  static Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }
}