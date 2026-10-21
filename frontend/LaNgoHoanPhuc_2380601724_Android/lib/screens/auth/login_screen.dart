import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/api_settings_dialog.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'verify_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? initialUsername;

  const LoginScreen({super.key, this.initialUsername});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = LoginRequest(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    final response = await ApiService.login(request);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.status) {
      AppDialogs.showSuccess(
        context,
        response.message.isNotEmpty
            ? response.message
            : 'Mật khẩu chính xác! Mã OTP đã được gửi về Email.',
      );

      // Chuyển sang màn hình xác thực OTP (Yêu cầu 2: OTP)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(
            username: _usernameController.text.trim(),
          ),
        ),
      );
    } else {
      AppDialogs.showError(
        context,
        response.message.isNotEmpty
            ? response.message
            : 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin!',
      );
    }
  }

  void _fillAccount(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded, color: AppConfig.primaryColor),
            tooltip: 'Cài đặt API URL',
            onPressed: () => ApiSettingsDialog.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Đăng Nhập Hệ Thống',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Bảo mật 2 lớp: Tên đăng nhập + Mật khẩu + OTP',
                    style: TextStyle(fontSize: 13, color: AppConfig.textSecondary),
                  ),
                ),
                const SizedBox(height: 24),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConfig.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tên đăng nhập
                      CustomTextField(
                        controller: _usernameController,
                        label: 'Tên đăng nhập',
                        hint: 'Nhập tên tài khoản',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên đăng nhập';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mật khẩu
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        hint: 'Nhập mật khẩu',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng nhập
                      CustomButton(
                        text: 'Tiếp Tục (Nhận OTP)',
                        icon: Icons.login_rounded,
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Link sang đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản? ',
                      style: TextStyle(color: AppConfig.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final registeredUser = await Navigator.of(context).push<String>(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                        if (registeredUser != null && registeredUser.isNotEmpty) {
                          setState(() {
                            _usernameController.text = registeredUser;
                          });
                        }
                      },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          color: AppConfig.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick test accounts for demo/testing
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.touch_app_outlined, size: 16, color: AppConfig.primaryColor),
                          SizedBox(width: 6),
                          Text(
                            'Tài khoản Demo (Bấm để điền nhanh):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppConfig.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.admin_panel_settings, size: 16, color: Colors.deepPurple),
                            label: const Text('Admin', style: TextStyle(fontSize: 12)),
                            backgroundColor: const Color(0xFFEDE9FE),
                            onPressed: () => _fillAccount('testadmin', 'AdminPassword123!'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.badge, size: 16, color: Colors.orange),
                            label: const Text('Staff (Nhân viên)', style: TextStyle(fontSize: 12)),
                            backgroundColor: const Color(0xFFFEF3C7),
                            onPressed: () => _fillAccount('teststaff', 'StaffPassword123!'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.person, size: 16, color: Colors.teal),
                            label: const Text('Customer (Khách)', style: TextStyle(fontSize: 12)),
                            backgroundColor: const Color(0xFFD1FAE5),
                            onPressed: () => _fillAccount('testcustomer', 'CustomerPassword123!'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
