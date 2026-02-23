import '../models/user_model.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  Future<List<User>> getPendingUsers() async {
    try {
      final response = await _apiService.get(ApiConfig.pendingUsers);

      if (response['success']) {
        final List<dynamic> usersJson = response['data']['users'];
        return usersJson.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> approveUser(int userId) async {
    try {
      final response = await _apiService.post(ApiConfig.approveUser(userId));
      return response['success'] ?? false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> rejectUser(int userId, {String? reason}) async {
    try {
      final response = await _apiService.post(
        ApiConfig.rejectUser(userId),
        data: {'reason': reason},
      );
      return response['success'] ?? false;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<User>> getAllUsers({String? role, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (role != null) queryParams['role'] = role;
      if (status != null) queryParams['status'] = status;

      final response = await _apiService.get(
        ApiConfig.allUsers,
        queryParameters: queryParams,
      );

      if (response['success']) {
        final List<dynamic> usersJson = response['data']['users'];
        return usersJson.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}