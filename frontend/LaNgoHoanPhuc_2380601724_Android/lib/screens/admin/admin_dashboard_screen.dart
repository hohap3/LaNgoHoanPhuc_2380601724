import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/api_settings_dialog.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/features_grid_section.dart';
import '../../widgets/role_badge.dart';
import '../auth/login_screen.dart';
import 'user_detail_dialog.dart';
import 'user_edit_dialog.dart';
import 'user_form_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<UserDto> _users = [];
  List<UserDto> _filteredUsers = [];
  bool _isLoading = true;
  String _currentUsername = '';
  String _searchQuery = '';
  String _selectedFilterRole = 'Tất cả';

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentAdminInfo();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAdminInfo() async {
    final username = await StorageService.getUsername();
    setState(() {
      _currentUsername = username ?? 'Admin';
    });
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);

    final response = await ApiService.getAllUsers();

    if (!mounted) return;

    if (response.status && response.data != null) {
      setState(() {
        _users = response.data!;
        _applyFilters();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      AppDialogs.showError(
        context,
        response.message.isNotEmpty
            ? response.message
            : 'Không thể tải danh sách người dùng!',
      );
    }
  }

  void _applyFilters() {
    List<UserDto> list = List.from(_users);

    // Apply role filter
    if (_selectedFilterRole != 'Tất cả') {
      list = list.where((u) {
        return u.roles.any((r) => r.toLowerCase() == _selectedFilterRole.toLowerCase());
      }).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((u) {
        return u.username.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.id.toLowerCase().contains(q);
      }).toList();
    }

    _filteredUsers = list;
  }

  Future<void> _handleDelete(UserDto user) async {
    // Check if current logged-in user is trying to delete self
    if (user.username == _currentUsername) {
      AppDialogs.showError(context, 'Không thể tự xóa tài khoản Admin đang đăng nhập!');
      return;
    }

    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Xóa tài khoản',
      message: 'Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản "${user.username}" (${user.email})?',
      confirmText: 'Xác nhận Xóa',
      confirmColor: AppConfig.dangerColor,
    );

    if (confirmed != true) return;

    final response = await ApiService.deleteUser(user.id);

    if (!mounted) return;

    if (response.status) {
      AppDialogs.showSuccess(
        context,
        response.message.isNotEmpty ? response.message : 'Đã xóa người dùng thành công!',
      );
      _fetchUsers();
    } else {
      AppDialogs.showError(context, response.message);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất khỏi trang quản trị?',
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

  int get _countAdmin => _users.where((u) => u.roles.any((r) => r.toLowerCase() == 'admin')).length;
  int get _countStaff => _users.where((u) => u.roles.any((r) => r.toLowerCase() == 'staff' || r.toLowerCase() == 'nhân viên')).length;
  int get _countCustomer => _users.where((u) => u.roles.any((r) => r.toLowerCase() == 'customer' || r.toLowerCase() == 'khách hàng')).length;

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
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.deepPurple, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trang Quản Trị Hệ Thống',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.textPrimary,
                    ),
                  ),
                  Text(
                    'Admin: $_currentUsername',
                    style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppConfig.primaryColor),
            tooltip: 'Làm mới',
            onPressed: _fetchUsers,
          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await UserFormDialog.show(context);
          if (created == true) {
            _fetchUsers();
          }
        },
        backgroundColor: AppConfig.primaryColor,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Thêm Người Dùng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUsers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Metric cards
              _buildMetricCards(),
              const SizedBox(height: 16),

              // Search bar and filter chips
              _buildSearchAndFilters(),
              const SizedBox(height: 16),

              // 3 Features extension (Vị trí, Vân tay/QR/NFC, Dịch realtime)
              const FeaturesGridSection(),
              const SizedBox(height: 16),

              // Header of list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách tài khoản (${_filteredUsers.length}/${_users.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.textPrimary,
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // User List or Empty State
              if (_isLoading && _users.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_filteredUsers.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredUsers.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final user = _filteredUsers[index];
                    return _buildUserCard(user);
                  },
                ),
              const SizedBox(height: 80), // Padding for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Tổng số',
                count: _users.length,
                icon: Icons.people_alt_rounded,
                color: AppConfig.primaryColor,
                bgColor: const Color(0xFFEEF2FF),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Admin',
                count: _countAdmin,
                icon: Icons.admin_panel_settings_rounded,
                color: Colors.deepPurple,
                bgColor: const Color(0xFFEDE9FE),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Staff',
                count: _countStaff,
                icon: Icons.badge_rounded,
                color: Colors.amber.shade800,
                bgColor: const Color(0xFFFEF3C7),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Khách',
                count: _countCustomer,
                icon: Icons.person_rounded,
                color: Colors.teal,
                bgColor: const Color(0xFFD1FAE5),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search input
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm username, email...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Role Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả'),
                const SizedBox(width: 6),
                _buildFilterChip('Admin'),
                const SizedBox(width: 6),
                _buildFilterChip('Staff'),
                const SizedBox(width: 6),
                _buildFilterChip('Customer'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilterRole == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppConfig.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppConfig.primaryColor,
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilterRole = label;
            _applyFilters();
          });
        }
      },
    );
  }

  Widget _buildUserCard(UserDto user) {
    final isSelf = user.username == _currentUsername;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelf ? AppConfig.primaryColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: isSelf ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isSelf
                      ? AppConfig.primaryColor
                      : AppConfig.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isSelf ? Colors.white : AppConfig.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.username,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Bạn',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppConfig.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email.isNotEmpty ? user.email : '(Chưa có email)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppConfig.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Role badge
                RoleBadge(role: user.primaryRole),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 6),

            // CRUD Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 1. READ: Chi tiết (Read by Id)
                TextButton.icon(
                  onPressed: () => UserDetailDialog.show(context, user),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                const SizedBox(width: 4),

                // 2. UPDATE: Sửa thông tin & đổi quyền
                TextButton.icon(
                  onPressed: () async {
                    final updated = await UserEditDialog.show(context, user);
                    if (updated == true) {
                      _fetchUsers();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Sửa', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppConfig.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                const SizedBox(width: 4),

                // 3. DELETE: Xóa tài khoản
                TextButton.icon(
                  onPressed: () => _handleDelete(user),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Xóa', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: isSelf ? Colors.grey : AppConfig.dangerColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Không tìm thấy người dùng phù hợp',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppConfig.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hãy thử thay đổi từ khóa tìm kiếm hoặc bộ lọc vai trò.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).alignment,
    );
  }
}
