import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class RegistrationScreen extends StatefulWidget {
  final String phoneNumber;
  final String role;

  const RegistrationScreen({
    super.key,
    required this.phoneNumber,
    required this.role,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Common fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Doctor specific fields
  final _specializationController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _experienceController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _bioController = TextEditingController();

  // Lab Technician specific fields
  final _labNameController = TextEditingController();
  final _labLicenseController = TextEditingController();
  final _labSpecializationController = TextEditingController();

  // Pharmacy specific fields
  final _pharmacyNameController = TextEditingController();
  final _pharmacyLicenseController = TextEditingController();
  final _gstNumberController = TextEditingController();

  String? _selectedGender;
  DateTime? _dateOfBirth;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _specializationController.dispose();
    _qualificationController.dispose();
    _registrationNumberController.dispose();
    _experienceController.dispose();
    _consultationFeeController.dispose();
    _bioController.dispose();
    _labNameController.dispose();
    _labLicenseController.dispose();
    _labSpecializationController.dispose();
    _pharmacyNameController.dispose();
    _pharmacyLicenseController.dispose();
    _gstNumberController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Validate role-specific fields
  bool _validateRoleSpecificFields() {
    if (widget.role == 'doctor') {
      if (_specializationController.text.trim().isEmpty ||
          _qualificationController.text.trim().isEmpty ||
          _registrationNumberController.text.trim().isEmpty) {
        Helpers.showSnackBar(
          context,
          'Please fill all required doctor fields',
          isError: true,
        );
        return false;
      }
    } else if (widget.role == 'lab_technician') {
      if (_labNameController.text.trim().isEmpty ||
          _labLicenseController.text.trim().isEmpty) {
        Helpers.showSnackBar(
          context,
          'Please fill all required lab fields',
          isError: true,
        );
        return false;
      }
    } else if (widget.role == 'pharmacy') {
      if (_pharmacyNameController.text.trim().isEmpty ||
          _pharmacyLicenseController.text.trim().isEmpty) {
        Helpers.showSnackBar(
          context,
          'Please fill all required pharmacy fields',
          isError: true,
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate role-specific fields for non-patients
    if (widget.role != 'patient' && !_validateRoleSpecificFields()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userData = _buildUserData();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.register(userData);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (response != null && response.success) {
      _navigateAfterRegistration(response.user!);
    } else {
      Helpers.showSnackBar(
        context,
        authProvider.errorMessage ?? 'Registration failed',
        isError: true,
      );
    }
  }

  Map<String, dynamic> _buildUserData() {
    // Explicitly type as Map<String, dynamic> to allow nested maps
    final Map<String, dynamic> userData = <String, dynamic>{
      'phone_number': widget.phoneNumber,
      'password': _passwordController.text,
      'full_name': _fullNameController.text.trim(),
      'role': widget.role,
    };

    // Add optional fields only if they have values
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      userData['email'] = email;
    }

    if (_selectedGender != null) {
      userData['gender'] = _selectedGender;
    }

    if (_dateOfBirth != null) {
      userData['date_of_birth'] = _dateOfBirth!.toIso8601String().split('T')[0];
    }

    final address = _addressController.text.trim();
    if (address.isNotEmpty) {
      userData['address'] = address;
    }

    final city = _cityController.text.trim();
    if (city.isNotEmpty) {
      userData['city'] = city;
    }

    final state = _stateController.text.trim();
    if (state.isNotEmpty) {
      userData['state'] = state;
    }

    final pincode = _pincodeController.text.trim();
    if (pincode.isNotEmpty) {
      userData['pincode'] = pincode;
    }

    // Add role-specific details
    final roleDetails = _buildRoleDetails();
    if (roleDetails != null) {
      userData['role_details'] = roleDetails;
    }

    return userData;
  }

  Map<String, dynamic>? _buildRoleDetails() {
    if (widget.role == 'doctor') {
      final specialization = _specializationController.text.trim();
      final qualification = _qualificationController.text.trim();
      final registrationNumber = _registrationNumberController.text.trim();

      if (specialization.isEmpty || qualification.isEmpty || registrationNumber.isEmpty) {
        return null;
      }

      final Map<String, dynamic> details = <String, dynamic>{
        'specialization': specialization,
        'qualification': qualification,
        'registration_number': registrationNumber,
      };

      final experience = _experienceController.text.trim();
      if (experience.isNotEmpty) {
        final parsedExp = int.tryParse(experience);
        if (parsedExp != null) {
          details['years_of_experience'] = parsedExp;
        }
      }

      final fee = _consultationFeeController.text.trim();
      if (fee.isNotEmpty) {
        final parsedFee = double.tryParse(fee);
        if (parsedFee != null) {
          details['consultation_fee'] = parsedFee;
        }
      }

      final bio = _bioController.text.trim();
      if (bio.isNotEmpty) {
        details['bio'] = bio;
      }

      return details;
    } else if (widget.role == 'lab_technician') {
      final labName = _labNameController.text.trim();
      final licenseNumber = _labLicenseController.text.trim();

      if (labName.isEmpty || licenseNumber.isEmpty) {
        return null;
      }

      final Map<String, dynamic> details = <String, dynamic>{
        'lab_name': labName,
        'license_number': licenseNumber,
      };

      final specialization = _labSpecializationController.text.trim();
      if (specialization.isNotEmpty) {
        details['specialization'] = specialization;
      }

      return details;
    } else if (widget.role == 'pharmacy') {
      final pharmacyName = _pharmacyNameController.text.trim();
      final licenseNumber = _pharmacyLicenseController.text.trim();

      if (pharmacyName.isEmpty || licenseNumber.isEmpty) {
        return null;
      }

      final Map<String, dynamic> details = <String, dynamic>{
        'pharmacy_name': pharmacyName,
        'license_number': licenseNumber,
      };

      final gstNumber = _gstNumberController.text.trim();
      if (gstNumber.isNotEmpty) {
        details['gst_number'] = gstNumber;
      }

      return details;
    }

    return null;
  }

  void _navigateAfterRegistration(User user) {
    String route;

    if (user.role == UserRole.patient) {
      route = AppRoutes.patientHome;
    } else if (user.status == UserStatus.pending) {
      route = AppRoutes.pendingApproval;
    } else {
      route = AppRoutes.patientHome; // Default
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
          (route) => false,
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleConfig = AppConstants.roleConfigs[widget.role];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: _currentStep == _getTotalSteps() - 1
                            ? 'Register'
                            : 'Continue',
                        onPressed: details.onStepContinue,
                        isLoading: _isLoading,
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Back',
                          onPressed: details.onStepCancel,
                          isOutlined: true,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: _buildSteps(roleConfig),
          ),
        ),
      ),
    );
  }

  List<Step> _buildSteps(RoleConfig? roleConfig) {
    final List<Step> steps = [
      // Step 1: Basic Information
      Step(
        title: const Text('Basic Information'),
        subtitle: const Text('Name, email & password'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: _buildBasicInfoStep(),
      ),

      // Step 2: Personal Details
      Step(
        title: const Text('Personal Details'),
        subtitle: const Text('Date of birth & address'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: _buildPersonalDetailsStep(),
      ),
    ];

    // Step 3: Role-specific details (for non-patients)
    if (widget.role != 'patient') {
      steps.add(
        Step(
          title: Text('${roleConfig?.name ?? 'Professional'} Details'),
          subtitle: const Text('Professional information'),
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          content: _buildRoleSpecificStep(),
        ),
      );
    }

    return steps;
  }

  void _onStepContinue() {
    // Validate current step before proceeding
    if (_currentStep == 0) {
      // Validate basic info
      if (_fullNameController.text.trim().isEmpty) {
        Helpers.showSnackBar(context, 'Please enter your full name', isError: true);
        return;
      }
      if (_passwordController.text.isEmpty) {
        Helpers.showSnackBar(context, 'Please enter a password', isError: true);
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        Helpers.showSnackBar(context, 'Passwords do not match', isError: true);
        return;
      }
      final passwordError = Validators.validatePassword(_passwordController.text);
      if (passwordError != null) {
        Helpers.showSnackBar(context, passwordError, isError: true);
        return;
      }
    }

    if (_currentStep < _getTotalSteps() - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _register();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  int _getTotalSteps() {
    return widget.role == 'patient' ? 2 : 3;
  }

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        CustomTextField(
          label: 'Full Name',
          hint: 'Enter your full name',
          controller: _fullNameController,
          validator: Validators.validateFullName,
          prefix: const Icon(Icons.person_outline),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Email (Optional)',
          hint: 'Enter your email address',
          controller: _emailController,
          validator: Validators.validateEmail,
          keyboardType: TextInputType.emailAddress,
          prefix: const Icon(Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Password',
          hint: 'Create a strong password',
          controller: _passwordController,
          validator: Validators.validatePassword,
          obscureText: true,
          prefix: const Icon(Icons.lock_outline),
        ),
        const SizedBox(height: 8),
        _buildPasswordRequirements(),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          controller: _confirmPasswordController,
          validator: (value) => Validators.validateConfirmPassword(
            value,
            _passwordController.text,
          ),
          obscureText: true,
          prefix: const Icon(Icons.lock_outline),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password must contain:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          _buildRequirement('At least 8 characters'),
          _buildRequirement('One uppercase letter'),
          _buildRequirement('One lowercase letter'),
          _buildRequirement('One number'),
          _buildRequirement(r'One special character (@$!%*?&)'),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsStep() {
    return Column(
      children: [
        // Gender Selection
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Gender (Optional)',
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Date of Birth
        InkWell(
          onTap: _selectDateOfBirth,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date of Birth (Optional)',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _dateOfBirth != null
                  ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                  : 'Select your date of birth',
              style: TextStyle(
                color: _dateOfBirth != null
                    ? AppTheme.textPrimaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        CustomTextField(
          label: 'Address (Optional)',
          hint: 'Enter your address',
          controller: _addressController,
          prefix: const Icon(Icons.home_outlined),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'City (Optional)',
                hint: 'City',
                controller: _cityController,
                prefix: const Icon(Icons.location_city),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'State (Optional)',
                hint: 'State',
                controller: _stateController,
                prefix: const Icon(Icons.map),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        CustomTextField(
          label: 'Pincode (Optional)',
          hint: 'Enter pincode',
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          prefix: const Icon(Icons.pin_drop),
          maxLength: 10,
        ),
      ],
    );
  }

  Widget _buildRoleSpecificStep() {
    switch (widget.role) {
      case 'doctor':
        return _buildDoctorFields();
      case 'lab_technician':
        return _buildLabTechnicianFields();
      case 'pharmacy':
        return _buildPharmacyFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDoctorFields() {
    return Column(
      children: [
        CustomTextField(
          label: 'Specialization *',
          hint: 'e.g., Cardiologist, Dermatologist',
          controller: _specializationController,
          validator: (value) => Validators.validateRequired(value, 'Specialization'),
          prefix: const Icon(Icons.medical_services),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Qualification *',
          hint: 'e.g., MBBS, MD',
          controller: _qualificationController,
          validator: (value) => Validators.validateRequired(value, 'Qualification'),
          prefix: const Icon(Icons.school),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Medical Registration Number *',
          hint: 'Enter your registration number',
          controller: _registrationNumberController,
          validator: (value) => Validators.validateRequired(value, 'Registration Number'),
          prefix: const Icon(Icons.badge),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Experience (Years)',
                hint: 'Years',
                controller: _experienceController,
                keyboardType: TextInputType.number,
                prefix: const Icon(Icons.work_history),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                label: 'Consultation Fee',
                hint: 'Fee',
                controller: _consultationFeeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefix: const Icon(Icons.currency_rupee),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Bio (Optional)',
          hint: 'Tell patients about yourself',
          controller: _bioController,
          maxLines: 3,
          prefix: const Icon(Icons.description),
        ),
      ],
    );
  }

  Widget _buildLabTechnicianFields() {
    return Column(
      children: [
        CustomTextField(
          label: 'Lab Name *',
          hint: 'Enter laboratory name',
          controller: _labNameController,
          validator: (value) => Validators.validateRequired(value, 'Lab Name'),
          prefix: const Icon(Icons.science),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'License Number *',
          hint: 'Enter lab license number',
          controller: _labLicenseController,
          validator: (value) => Validators.validateRequired(value, 'License Number'),
          prefix: const Icon(Icons.badge),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Specialization (Optional)',
          hint: 'e.g., Pathology, Radiology',
          controller: _labSpecializationController,
          prefix: const Icon(Icons.biotech),
        ),
      ],
    );
  }

  Widget _buildPharmacyFields() {
    return Column(
      children: [
        CustomTextField(
          label: 'Pharmacy Name *',
          hint: 'Enter pharmacy name',
          controller: _pharmacyNameController,
          validator: (value) => Validators.validateRequired(value, 'Pharmacy Name'),
          prefix: const Icon(Icons.local_pharmacy),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'License Number *',
          hint: 'Enter pharmacy license number',
          controller: _pharmacyLicenseController,
          validator: (value) => Validators.validateRequired(value, 'License Number'),
          prefix: const Icon(Icons.badge),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'GST Number (Optional)',
          hint: 'Enter GST number',
          controller: _gstNumberController,
          prefix: const Icon(Icons.receipt_long),
        ),
      ],
    );
  }
}