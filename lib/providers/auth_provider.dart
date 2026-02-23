import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/auth_response_model.dart';
import '../services/auth_service.dart';

enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  User? _currentUser;
  String? _errorMessage;

  AuthState get state => _state;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  Future<void> checkAuthStatus() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _authService.getCurrentUser();
        if (_currentUser != null) {
          _state = AuthState.authenticated;
        } else {
          _state = AuthState.unauthenticated;
        }
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<bool> sendOTP(String phoneNumber) async {
    _errorMessage = null;
    try {
      final response = await _authService.sendOTP(phoneNumber);
      return response['success'] ?? false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otpCode) async {
    _errorMessage = null;
    try {
      final response = await _authService.verifyOTP(phoneNumber, otpCode);
      return response['success'] ?? false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<AuthResponse?> register(Map<String, dynamic> userData) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(userData);

      if (response.success && response.user != null) {
        _currentUser = response.user;
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
        _errorMessage = response.message;
      }

      notifyListeners();
      return response;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<AuthResponse?> login(
      String phoneNumber,
      String password,
      bool rememberMe,
      ) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(phoneNumber, password, rememberMe);

      if (response.success && response.user != null) {
        _currentUser = response.user;
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
        _errorMessage = response.message;
      }

      notifyListeners();
      return response;
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
      _state = AuthState.unauthenticated;
    } catch (e) {
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _authService.getProfile();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}