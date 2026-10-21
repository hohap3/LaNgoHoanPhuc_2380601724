import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/storage_service.dart';
import 'admin/admin_dashboard_screen.dart';
import 'auth/login_screen.dart';
import 'customer/customer_dashboard_screen.dart';
import 'staff/staff_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final isLoggedIn = await StorageService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      final roles = await StorageService.getRoles();
      if (!mounted) return;

      final lowerRoles = roles.map((r) => r.toLowerCase()).toList();

      Widget destination;
      if (lowerRoles.contains('admin')) {
        destination = const AdminDashboardScreen();
      } else if (lowerRoles.contains('staff') ||
          lowerRoles.contains('nhân viên') ||
          lowerRoles.contains('employee')) {
        destination = const StaffDashboardScreen();
      } else {
        destination = const CustomerDashboardScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConfig.primaryColor, AppConfig.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConfig.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.security_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hệ Thống Phân Quyền',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppConfig.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'La Ngô Hoàn Phúc - 2380601724',
              style: TextStyle(
                fontSize: 14,
                color: AppConfig.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppConfig.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
