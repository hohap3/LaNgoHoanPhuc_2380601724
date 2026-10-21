import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/api_settings_dialog.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = AppConfig.roleCustomer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<Map<String, String>> _roleOptions = [
    {'value': AppConfig.roleCustomer, 'label': 'Khách hàng (Customer)'},
    {'value': AppConfig.roleStaff, 'label': 'Nhân viên (Staff)'},
    {'value': AppConfig.roleAdmin, 'label': 'Quản trị viên (Admin)'},
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = RegisterRequest(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    final response = await ApiService.register(request);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.status) {
      AppDialogs.showSuccess(
        context,
        response.message.isNotEmpty
            ? response.message
            : 'Đăng ký tài khoản thành công! Vui lòng đăng nhập.',
      );
      // Return username to login screen
      Navigator.of(context).pop(_usernameController.text.trim());
    } else {
      AppDialogs.showError(context, response.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Đăng Ký Tài Khoản',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded, color: AppConfig.primaryColor),
            tooltip: 'Cài đặt API',
            onPressed: () => ApiSettingsDialog.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon / Banner
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 48,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Tạo tài khoản mới',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.textPrimary,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Đăng ký qua Email để nhận mã OTP đăng nhập',
                    style: TextStyle(fontSize: 13, color: AppConfig.textSecondary),
                  ),
                ),
                const SizedBox(height: 24),

                // Card container
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
                        label: 'Tên đăng nhập (Username)',
                        hint: 'Nhập tên đăng nhập',
                        prefixIcon: Icons.account_circle_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên đăng nhập';
                          }
                          if (value.trim().length < 3) {
                            return 'Tên đăng nhập tối thiểu 3 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      CustomTextField(
                        controller: _emailController,
                        label: 'Địa chỉ Email (Nhận mã OTP)',
                        hint: 'example@gmail.com',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Email không đúng định dạng';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mật khẩu
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        hint: 'Tối thiểu 6 ký tự',
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
                          if (value.length < 6) {
                            return 'Mật khẩu tối thiểu 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nhập lại mật khẩu
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Xác nhận mật khẩu',
                        hint: 'Nhập lại mật khẩu',
                        prefixIcon: Icons.lock_clock_outlined,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Mật khẩu xác nhận không khớp!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phân quyền (Role Selection)
                      const Text(
                        'Phân quyền tài khoản (Role)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppConfig.primaryColor),
                            items: _roleOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt['value'],
                                child: Row(
                                  children: [
                                    Icon(
                                      opt['value'] == AppConfig.roleAdmin
                                          ? Icons.admin_panel_settings_rounded
                                          : opt['value'] == AppConfig.roleStaff
                                              ? Icons.badge_rounded
                                              : Icons.person_rounded,
                                      size: 18,
                                      color: opt['value'] == AppConfig.roleAdmin
                                          ? Colors.deepPurple
                                          : opt['value'] == AppConfig.roleStaff
                                              ? Colors.amber.shade800
                                              : Colors.teal,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(opt['label']!, style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRole = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng ký
                      CustomButton(
                        text: 'Đăng Ký Tài Khoản',
                        icon: Icons.how_to_reg_rounded,
                        isLoading: _isLoading,
                        onPressed: _handleRegister,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Link to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(color: AppConfig.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Đăng nhập ngay',
                        style: TextStyle(
                          color: AppConfig.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
