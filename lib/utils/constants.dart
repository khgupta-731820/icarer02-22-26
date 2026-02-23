import 'package:flutter/material.dart';

class AppConstants {
  // Role Configurations
  static const Map<String, RoleConfig> roleConfigs = {
    'patient': RoleConfig(
      name: 'Patient',
      icon: Icons.person,
      color: Color(0xFF2196F3),
      description: 'Book appointments and manage health records',
    ),
    'doctor': RoleConfig(
      name: 'Doctor',
      icon: Icons.medical_services,
      color: Color(0xFF4CAF50),
      description: 'Manage patients and appointments',
      requiresApproval: true,
    ),
    'lab_technician': RoleConfig(
      name: 'Lab Technician',
      icon: Icons.science,
      color: Color(0xFF9C27B0),
      description: 'Manage lab tests and reports',
      requiresApproval: true,
    ),
    'pharmacy': RoleConfig(
      name: 'Pharmacy',
      icon: Icons.local_pharmacy,
      color: Color(0xFFFF9800),
      description: 'Manage prescriptions and medicines',
      requiresApproval: true,
    ),
  };

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Padding & Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
}

class RoleConfig {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final bool requiresApproval;

  const RoleConfig({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    this.requiresApproval = false,
  });
}