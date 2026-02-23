import 'user_model.dart';

class AuthTokens {
  final String accessToken;
  final String? refreshToken;

  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final User? user;
  final AuthTokens? tokens;

  const AuthResponse({
    required this.success,
    required this.message,
    this.user,
    this.tokens,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'],
      message: json['message'],
      user: json['data']?['user'] != null
          ? User.fromJson(json['data']['user'])
          : null,
      tokens: json['data']?['tokens'] != null
          ? AuthTokens.fromJson(json['data']['tokens'])
          : null,
    );
  }
}