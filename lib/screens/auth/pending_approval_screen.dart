import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../utils/helpers.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({Key? key}) : super(key: key);

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isRefreshing = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshProfile();

    setState(() {
      _isRefreshing = false;
    });

    if (!mounted) return;

    final user = authProvider.currentUser;
    if (user != null) {
      if (user.status.name == 'approved') {
        Helpers.showSnackBar(context, 'Your account has been approved!');
        _navigateToHome();
      } else if (user.status.name == 'rejected') {
        Helpers.showSnackBar(
          context,
          'Your account was rejected: ${user.rejectionReason ?? "No reason provided"}',
          isError: true,
        );
      } else {
        Helpers.showSnackBar(
          context,
          'Your account is still pending approval',
        );
      }
    }
  }

  void _navigateToHome() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    String route;
    switch (user.role.value) {
      case 'doctor':
        route = AppRoutes.doctorHome;
        break;
      case 'lab_technician':
        route = AppRoutes.labTechnicianHome;
        break;
      case 'pharmacy':
        route = AppRoutes.pharmacyHome;
        break;
      default:
        route = AppRoutes.patientHome;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
          (route) => false,
    );
  }

  Future<void> _logout() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
    );

    if (confirmed != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.roleSelection,
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_top,
                    size: 80,
                    color: Colors.orange.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Account Pending Approval',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your account is currently under review. Our admin team will verify your details and approve your account shortly.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'What happens next?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStep('1', 'Admin reviews your details'),
                    _buildStep('2', 'Verification of credentials'),
                    _buildStep('3', 'Account approval notification'),
                    _buildStep('4', 'Full access to the platform'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Check Status',
                onPressed: _refreshStatus,
                isLoading: _isRefreshing,
                width: double.infinity,
                icon: Icons.refresh,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Logout',
                onPressed: _logout,
                isOutlined: true,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}