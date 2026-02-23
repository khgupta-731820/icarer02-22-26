import 'package:equatable/equatable.dart';

enum UserRole {
  patient,
  doctor,
  labTechnician,
  pharmacy,
  admin;

  String get value {
    switch (this) {
      case UserRole.patient:
        return 'patient';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.labTechnician:
        return 'lab_technician';
      case UserRole.pharmacy:
        return 'pharmacy';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'patient':
        return UserRole.patient;
      case 'doctor':
        return UserRole.doctor;
      case 'lab_technician':
        return UserRole.labTechnician;
      case 'pharmacy':
        return UserRole.pharmacy;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.patient;
    }
  }
}

enum UserStatus {
  pending,
  approved,
  rejected;

  static UserStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return UserStatus.pending;
      case 'approved':
        return UserStatus.approved;
      case 'rejected':
        return UserStatus.rejected;
      default:
        return UserStatus.pending;
    }
  }
}

class User extends Equatable {
  final int id;
  final String phoneNumber;
  final String? email;
  final String fullName;
  final UserRole role;
  final UserStatus status;
  final bool isPhoneVerified;
  final String? profileImage;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.phoneNumber,
    this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.isPhoneVerified,
    this.profileImage,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.rejectionReason,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      fullName: json['full_name'],
      role: UserRole.fromString(json['role']),
      status: UserStatus.fromString(json['status']),
      isPhoneVerified: json['is_phone_verified'] ?? false,
      profileImage: json['profile_image'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'email': email,
      'full_name': fullName,
      'role': role.value,
      'status': status.name,
      'is_phone_verified': isPhoneVerified,
      'profile_image': profileImage,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    phoneNumber,
    email,
    fullName,
    role,
    status,
    isPhoneVerified,
  ];
}