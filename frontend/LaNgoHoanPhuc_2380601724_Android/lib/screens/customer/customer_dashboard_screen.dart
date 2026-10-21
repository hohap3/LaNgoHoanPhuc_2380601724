import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/storage_service.dart';
import '../../widgets/api_settings_dialog.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/features_grid_section.dart';
import '../../widgets/role_badge.dart';
import '../auth/login_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  String _username = '';
  List<String> _roles = [];

  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Đơn hàng của tôi',
      'subtitle': 'Xem trạng thái vận chuyển và hóa đơn',
      'icon': Icons.shopping_bag_outlined,
      'color': Colors.indigo,
    },
    {
      'title': 'Ưu đãi & Voucher',
      'subtitle': 'Mã giảm giá dành riêng cho thành viên',
      'icon': Icons.confirmation_number_outlined,
      'color': Colors.pink,
    },
    {
      'title': 'Ví & Thanh toán',
      'subtitle': 'Quản lý phương thức và lịch sử nạp/rút',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Colors.teal,
    },
    {
      'title': 'Trung tâm hỗ trợ',
      'subtitle': 'Liên hệ tổng đài viên & tư vấn viên',
      'icon': Icons.support_agent_rounded,
      'color': Colors.blue,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final username = await StorageService.getUsername();
    final roles = await StorageService.getRoles();
    setState(() {
      _username = username ?? 'Khách hàng';
      _roles = roles;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất?',
      confirmText: 'Đăng xuất',
      confirmColor: AppConfig.primaryColor,
    );

    if (confirmed == true) {
      await StorageService.clearSession();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.teal, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trang Khách Hàng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.textPrimary,
                    ),
                  ),
                  Text(
                    'Cổng thông tin & Dịch vụ người dùng',
                    style: TextStyle(fontSize: 12, color: AppConfig.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded, color: AppConfig.primaryColor),
            tooltip: 'Cài đặt API',
            onPressed: () => ApiSettingsDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppConfig.dangerColor),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, $_username!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Thành viên thân thiết',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: _roles.map((r) => RoleBadge(role: r)).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer Role Verification Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.teal.shade700, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Phân quyền tài khoản: Khách hàng (Customer). Giao diện tối ưu trải nghiệm dịch vụ khách hàng.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF115E59)),
                    ),
                  ),
                ],
              ),
            ),
            // 3 Features extension (Vị trí, Vân tay/QR/NFC, Dịch realtime)
            const FeaturesGridSection(),
            const SizedBox(height: 20),

            // Features Grid
            const Text(
              'Tiện ích tài khoản',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConfig.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemCount: _features.length,
              itemBuilder: (ctx, index) {
                final item = _features[index];
                final color = item['color'] as Color;
                return InkWell(
                  onTap: () {
                    AppDialogs.showInfo(context, 'Tính năng "${item['title']}" sẵn sàng phục vụ!');
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item['icon'] as IconData, color: color, size: 22),
                        ),
                        const Spacer(),
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppConfig.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['subtitle'] as String,
                          style: const TextStyle(fontSize: 11, color: AppConfig.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
