import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../widgets/role_badge.dart';

class UserDetailDialog extends StatelessWidget {
  final UserDto user;

  const UserDetailDialog({super.key, required this.user});

  static void show(BuildContext context, UserDto user) {
    showDialog(
      context: context,
      builder: (ctx) => UserDetailDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppConfig.primaryColor.withValues(alpha: 0.1),
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: AppConfig.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Chi tiết tài khoản',
                  style: TextStyle(fontSize: 12, color: AppConfig.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            _buildDetailRow(
              icon: Icons.fingerprint_rounded,
              title: 'Mã người dùng (ID)',
              value: user.id,
              isCopyable: true,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.account_circle_outlined,
              title: 'Tên đăng nhập',
              value: user.username,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.email_outlined,
              title: 'Địa chỉ Email',
              value: user.email.isNotEmpty ? user.email : '(Chưa cập nhật)',
            ),
            const SizedBox(height: 14),
            const Text(
              'Danh sách quyền hạn (Roles):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: user.roles.isEmpty
                  ? [const Text('Không có quyền')]
                  : user.roles.map((r) => RoleBadge(role: r, fontSize: 13)).toList(),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    bool isCopyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConfig.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
