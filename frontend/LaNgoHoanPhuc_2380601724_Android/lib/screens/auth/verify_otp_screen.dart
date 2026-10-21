import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/custom_button.dart';
import '../admin/admin_dashboard_screen.dart';
import '../customer/customer_dashboard_screen.dart';
import '../staff/staff_dashboard_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String username;

  const VerifyOtpScreen({
    super.key,
    required this.username,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  int _remainingSeconds = 180; // 3 phút theo Backend
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _remainingSeconds = 180);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _handleVerify() async {
    final otpCode = _otpController.text.trim();
    if (otpCode.isEmpty) {
      AppDialogs.showError(context, 'Vui lòng nhập mã OTP 6 chữ số!');
      return;
    }
    if (otpCode.length < 6) {
      AppDialogs.showError(context, 'Mã OTP bao gồm 6 chữ số!');
      return;
    }

    setState(() => _isLoading = true);

    final request = VerifyOtpRequest(
      username: widget.username,
      otpCode: otpCode,
    );

    final response = await ApiService.verifyOtp(request);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.status && response.token != null) {
      final roles = response.roles ?? [];

      // Save session
      await StorageService.saveSession(
        token: response.token!,
        username: widget.username,
        roles: roles,
      );

      if (!mounted) return;

      AppDialogs.showSuccess(context, 'Xác thực thành công! Đang chuyển hướng...');

      // Role-based navigation
      _navigateBasedOnRole(roles);
    } else {
      AppDialogs.showError(
        context,
        response.message.isNotEmpty
            ? response.message
            : 'Xác thực OTP thất bại. Vui lòng kiểm tra lại mã!',
      );
    }
  }

  void _navigateBasedOnRole(List<String> roles) {
    Widget destination;

    final lowerRoles = roles.map((r) => r.toLowerCase()).toList();

    if (lowerRoles.contains('admin')) {
      // Yêu cầu 3: Admin -> vào trang quản trị
      destination = const AdminDashboardScreen();
    } else if (lowerRoles.contains('staff') ||
        lowerRoles.contains('nhân viên') ||
        lowerRoles.contains('employee')) {
      // Yêu cầu 3: Nhân viên -> vào Dashboard của nhân viên tương ứng
      destination = const StaffDashboardScreen();
    } else {
      // Yêu cầu 3: Khách hàng hoặc khác -> vào trang tương ứng
      destination = const CustomerDashboardScreen();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _handleResendOtp() async {
    setState(() => _isResending = true);

    // Call login API to generate and resend OTP
    final response = await ApiService.login(LoginRequest(
      username: widget.username,
      password: '', // Note: we can show dialog if password is required or trigger resend
    ));

    setState(() => _isResending = false);

    if (!mounted) return;

    if (response.status) {
      AppDialogs.showSuccess(context, 'Mã OTP mới đã được gửi về Email!');
      _startCountdown();
    } else {
      AppDialogs.showInfo(
        context,
        'Nếu mã hết hạn, vui lòng quay lại màn hình đăng nhập để nhận mã mới.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTimerActive = _remainingSeconds > 0;

    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Xác Thực OTP',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConfig.accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 54,
                    color: AppConfig.accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'Nhập mã OTP xác thực',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: AppConfig.textSecondary),
                    children: [
                      const TextSpan(text: 'Mã 6 chữ số đã gửi về Email của tài khoản: '),
                      TextSpan(
                        text: widget.username,
                        style: const TextStyle(
                          color: AppConfig.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Card Container
              Container(
                padding: const EdgeInsets.all(24),
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
                  children: [
                    // OTP Input Field
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 14,
                        color: AppConfig.primaryColor,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        hintStyle: TextStyle(
                          fontSize: 28,
                          letterSpacing: 14,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppConfig.primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Countdown timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: isTimerActive ? AppConfig.primaryColor : AppConfig.dangerColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isTimerActive
                              ? 'Mã có hiệu lực trong: ${_formatTimer(_remainingSeconds)}'
                              : 'Mã OTP đã hết hạn!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isTimerActive ? AppConfig.primaryColor : AppConfig.dangerColor,
                          ),
                        ),
                      ],
                    ),
                    if (!isTimerActive) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _isResending ? null : _handleResendOtp,
                        icon: _isResending
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Gửi lại mã OTP'),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Submit Button
                    CustomButton(
                      text: 'Xác Thực & Đăng Nhập',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isLoading,
                      onPressed: _handleVerify,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Helpful instruction
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: Colors.amber.shade800, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kiểm tra hộp thư đến (Inbox) hoặc thư mục Thư rác (Spam) trong Email của bạn để nhận mã OTP 6 số.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Back to login
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Quay lại màn hình đăng nhập'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppConfig.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
