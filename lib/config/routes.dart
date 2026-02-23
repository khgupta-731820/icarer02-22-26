import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/phone_input_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/pending_approval_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/patient_home_screen.dart';
import '../screens/home/doctor_home_screen.dart';
import '../screens/home/lab_technician_home_screen.dart';
import '../screens/home/pharmacy_home_screen.dart';
import '../screens/home/admin_home_screen.dart';
import '../screens/admin/pending_users_screen.dart';
import '../screens/admin/all_users_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/phone_input_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/pending_approval_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/patient_home_screen.dart';
import '../screens/home/doctor_home_screen.dart';
import '../screens/home/lab_technician_home_screen.dart';
import '../screens/home/pharmacy_home_screen.dart';
import '../screens/home/admin_home_screen.dart';
import '../screens/admin/pending_users_screen.dart';
import '../screens/admin/all_users_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String roleSelection = '/role-selection';
  static const String phoneInput = '/phone-input';
  static const String otpVerification = '/otp-verification';
  static const String registration = '/registration';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String pendingApproval = '/pending-approval';

  // Home routes
  static const String patientHome = '/patient-home';
  static const String doctorHome = '/doctor-home';
  static const String labTechnicianHome = '/lab-technician-home';
  static const String pharmacyHome = '/pharmacy-home';
  static const String adminHome = '/admin-home';

  // Admin routes
  static const String pendingUsers = '/admin/pending-users';
  static const String allUsers = '/admin/all-users';

  // Profile
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case roleSelection:
        return _buildRoute(const RoleSelectionScreen(), settings);

      case phoneInput:
        final role = settings.arguments as String;
        return _buildRoute(PhoneInputScreen(role: role), settings);

      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          OTPVerificationScreen(
            phoneNumber: args['phone_number'],
            role: args['role'],
          ),
          settings,
        );

      case registration:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          RegistrationScreen(
            phoneNumber: args['phone_number'],
            role: args['role'],
          ),
          settings,
        );

      case login:
        return _buildRoute(const LoginScreen(), settings);

      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);

      case pendingApproval:
        return _buildRoute(const PendingApprovalScreen(), settings);

      case patientHome:
        return _buildRoute(const PatientHomeScreen(), settings);

      case doctorHome:
        return _buildRoute(const DoctorHomeScreen(), settings);

      case labTechnicianHome:
        return _buildRoute(const LabTechnicianHomeScreen(), settings);

      case pharmacyHome:
        return _buildRoute(const PharmacyHomeScreen(), settings);

      case adminHome:
        return _buildRoute(const AdminHomeScreen(), settings);

      case pendingUsers:
        return _buildRoute(const PendingUsersScreen(), settings);

      case allUsers:
        return _buildRoute(const AllUsersScreen(), settings);

      case profile:
        return _buildRoute(const ProfileScreen(), settings);

      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}