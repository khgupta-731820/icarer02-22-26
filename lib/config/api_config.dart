class ApiConfig {
  // Update this with your backend URL
  static const String baseUrl = 'http://localhost:3000/api';

  // Auth endpoints
  static const String sendOTP = '/auth/send-otp';
  static const String verifyOTP = '/auth/verify-otp';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String profile = '/auth/profile';

  // Admin endpoints
  static const String pendingUsers = '/admin/pending-users';
  static String approveUser(int userId) => '/admin/approve-user/$userId';
  static String rejectUser(int userId) => '/admin/reject-user/$userId';
  static const String allUsers = '/admin/users';

  // Timeout
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}