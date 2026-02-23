import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../utils/helpers.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String role;

  const OTPVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.role,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  late final TextEditingController _otpController;
  bool _isLoading = false;
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _canResend = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _startTimer();
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isDisposed && mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Please enter a valid OTP', isError: true);
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOTP(
      widget.phoneNumber,
      _otpController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pushReplacementNamed(
        '/registration',
        arguments: {
          'phone_number': widget.phoneNumber,
          'role': widget.role,
        },
      );
    } else {
      Helpers.showSnackBar(
        context,
        authProvider.errorMessage ?? 'Invalid OTP',
        isError: true,
      );
    }
  }

  Future<void> _resendOTP() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOTP(widget.phoneNumber);

    if (!mounted) return;

    if (success) {
      _startTimer();
      Helpers.showSnackBar(context, 'OTP sent successfully');
    } else {
      Helpers.showSnackBar(
        context,
        authProvider.errorMessage ?? 'Failed to send OTP',
        isError: true,
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Verification Code',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the code sent to\n${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 40),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  activeColor: AppTheme.primaryColor,
                  selectedColor: AppTheme.primaryColor,
                  inactiveColor: Colors.grey.shade300,
                ),
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                onCompleted: (code) {
                  if (mounted && !_isLoading) {
                    _verifyOTP();
                  }
                },
                onChanged: (value) {
                  // Just update the value, no action needed
                },
                beforeTextPaste: (text) {
                  return true;
                },
              ),
              const SizedBox(height: 24),
              if (!_canResend)
                Text(
                  'Resend code in ${_remainingSeconds}s',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                )
              else
                TextButton(
                  onPressed: _isLoading ? null : _resendOTP,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Verify',
                onPressed: _isLoading ? null : _verifyOTP,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}