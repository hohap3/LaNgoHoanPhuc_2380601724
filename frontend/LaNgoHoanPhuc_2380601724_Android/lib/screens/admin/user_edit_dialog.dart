import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/custom_text_field.dart';

class UserEditDialog extends StatefulWidget {
  final UserDto user;

  const UserEditDialog({super.key, required this.user});

  static Future<bool?> show(BuildContext context, UserDto user) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UserEditDialog(user: user),
    );
  }

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late String _selectedRole;
  bool _isLoading = false;

  final List<String> _roles = [
    AppConfig.roleCustomer,
    AppConfig.roleStaff,
    AppConfig.roleAdmin,
  ];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user.email);
    _selectedRole = widget.user.primaryRole;
    if (!_roles.contains(_selectedRole)) {
      _selectedRole = AppConfig.roleCustomer;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = UpdateUserRequest(
      email: _emailController.text.trim(),
      newRole: _selectedRole,
    );

    final response = await ApiService.updateUser(widget.user.id, request);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.status) {
      AppDialogs.showSuccess(
        context,
        response.message.isNotEmpty ? response.message : 'Cập nhật người dùng thành công!',
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
      title: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: AppConfig.primaryColor, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chỉnh sửa: ${widget.user.username}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
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
              // Username (Read-only)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      'Tên đăng nhập: ${widget.user.username}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Email
              CustomTextField(
                controller: _emailController,
                label: 'Địa chỉ Email mới',
                hint: 'nhap_email@domain.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập email';
                  if (!val.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Phân quyền mới (New Role)
              const Text(
                'Phân quyền mới (New Role):',
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
          onPressed: _isLoading ? null : _handleUpdate,
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
                  'Lưu thay đổi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
