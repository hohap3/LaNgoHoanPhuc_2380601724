import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/custom_text_field.dart';

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const UserFormDialog(),
    );
  }

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = AppConfig.roleCustomer;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _roles = [
    AppConfig.roleCustomer,
    AppConfig.roleStaff,
    AppConfig.roleAdmin,
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = RegisterRequest(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    final response = await ApiService.createUser(request);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.status) {
      AppDialogs.showSuccess(
        context,
        response.message.isNotEmpty ? response.message : 'Thêm người dùng thành công!',
      );
      Navigator.of(context).pop(true);
    } else {
      AppDialogs.showError(context, response.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.person_add_rounded, color: AppConfig.primaryColor),
          SizedBox(width: 8),
          Text(
            'Thêm Người Dùng Mới',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _usernameController,
                label: 'Tên đăng nhập',
                hint: 'Ví dụ: nhanvien01',
                prefixIcon: Icons.account_circle_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập username';
                  if (val.trim().length < 3) return 'Tối thiểu 3 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Ví dụ: nhanvien@gmail.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập email';
                  if (!val.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _passwordController,
                label: 'Mật khẩu khởi tạo',
                hint: 'Tối thiểu 6 ký tự',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
                  if (val.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Phân quyền (Role):',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: _roles.map((r) {
                      return DropdownMenuItem<String>(
                        value: r,
                        child: Text(
                          r == AppConfig.roleAdmin
                              ? 'Admin (Quản trị viên)'
                              : r == AppConfig.roleStaff
                                  ? 'Staff (Nhân viên)'
                                  : 'Customer (Khách hàng)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Thêm mới',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
