import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/storage_service.dart';
import '../../widgets/api_settings_dialog.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/features_grid_section.dart';
import '../../widgets/role_badge.dart';
import '../auth/login_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  String _username = '';
  List<String> _roles = [];

  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Xử lý đơn hàng giao nhanh #DH-8891',
      'priority': 'Cao',
      'time': '09:30 AM',
      'status': 'Đang xử lý',
      'color': Colors.orange,
    },
    {
      'title': 'Kiểm tra và xác thực dữ liệu kho hàng',
      'priority': 'Trung bình',
      'time': '11:00 AM',
      'status': 'Chờ thực hiện',
      'color': Colors.blue,
    },
    {
      'title': 'Hỗ trợ giải đáp thắc mắc khách hàng #KH-204',
      'priority': 'Khẩn cấp',
      'time': '02:15 PM',
      'status': 'Đang xử lý',
      'color': Colors.red,
    },
    {
      'title': 'Cập nhật báo cáo doanh số ca làm việc',
      'priority': 'Bình thường',
      'time': '05:00 PM',
      'status': 'Chưa bắt đầu',
      'color': Colors.grey,
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
      _username = username ?? 'Nhân viên';
      _roles = roles;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Đăng xuất',
      message: 'Bạn có muốn đăng xuất khỏi Dashboard Nhân viên?',
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
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.badge_rounded, color: Colors.amber.shade800, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Nhân Viên',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.textPrimary,
                    ),
                  ),
                  Text(
                    'Không gian làm việc nhân viên',
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
            // Staff Profile Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade700, Colors.orange.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
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
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'S',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Nhân viên vận hành hệ thống',
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

            // Performance KPI Cards
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Nhiệm vụ hôm nay',
                    value: '12 / 15',
                    icon: Icons.assignment_turned_in_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Hiệu suất ca',
                    value: '96%',
                    icon: Icons.trending_up_rounded,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Ca làm việc',
                    value: 'Ca Sáng',
                    icon: Icons.wb_sunny_rounded,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notice about role limitations
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Phân quyền tài khoản: Nhân viên (Staff). Bạn có quyền truy cập bảng làm việc, xử lý công việc và báo cáo.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ),
            // 3 Features extension (Vị trí, Vân tay/QR/NFC, Dịch realtime)
            const FeaturesGridSection(),
            const SizedBox(height: 20),

            // Task list section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh sách công việc được giao',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AppDialogs.showInfo(context, 'Dữ liệu danh sách công việc đã được cập nhật.');
                  },
                  child: const Text('Làm mới'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tasks.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final task = _tasks[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: task['color'] as Color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  task['time'] as String,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (task['color'] as Color).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Ưu tiên: ${task['priority']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: task['color'] as Color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          task['status'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppConfig.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
