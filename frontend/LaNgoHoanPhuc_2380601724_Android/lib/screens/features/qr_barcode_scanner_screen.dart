import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_config.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/role_badge.dart';

class QrBarcodeScannerScreen extends StatefulWidget {
  const QrBarcodeScannerScreen({super.key});

  @override
  State<QrBarcodeScannerScreen> createState() => _QrBarcodeScannerScreenState();
}

class _QrBarcodeScannerScreenState extends State<QrBarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  bool _isTorchOn = false;
  late AnimationController _animController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    _showResultDialog(rawValue, barcode.format.name);
  }

  Future<void> _scanFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final BarcodeCapture? capture = await _controller.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        final barcode = capture.barcodes.first;
        final raw = barcode.rawValue;
        if (raw != null && raw.isNotEmpty) {
          _showResultDialog(raw, barcode.format.name);
          return;
        }
      }

      if (mounted) {
        AppDialogs.showInfo(
          context,
          'Không tìm thấy mã QR/Barcode trong ảnh đã chọn. Bạn có thể thử ảnh khác hoặc dùng camera quét trực tiếp.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(context, 'Lỗi phân tích hình ảnh: $e');
      }
    }
  }

  void _simulateScan(String sampleCode, String type) {
    _showResultDialog(sampleCode, type);
  }

  void _showResultDialog(String rawValue, String formatName) {
    _controller.stop();

    // Parse data
    Map<String, dynamic>? parsedJson;
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map<String, dynamic>) {
        parsedJson = decoded;
      }
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle pill
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      formatName.toLowerCase().contains('qr')
                          ? Icons.qr_code_2_rounded
                          : Icons.view_week_rounded,
                      color: Colors.teal,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông Tin Đã Quét Thành Công',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppConfig.textPrimary,
                          ),
                        ),
                        Text(
                          'Định dạng mã: $formatName',
                          style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Parsed Information Content
              if (parsedJson != null)
                _buildJsonCard(parsedJson)
              else if (rawValue.startsWith('http://') || rawValue.startsWith('https://'))
                _buildUrlCard(rawValue)
              else if (_isProductBarcode(rawValue))
                _buildProductBarcodeCard(rawValue)
              else
                _buildTextCard(rawValue),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: rawValue));
                        AppDialogs.showSuccess(context, 'Đã sao chép nội dung mã!');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Sao Chép'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: 'Dữ liệu mã quét: $rawValue',
                            subject: 'Thông tin QR / Barcode',
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Chia Sẻ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Continue scan button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text(
                  'TIẾP TỤC QUÉT MÃ KHÁC',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _controller.start();
      setState(() => _isProcessing = false);
    });
  }

  bool _isProductBarcode(String code) {
    return RegExp(r'^\d{8,14}$').hasMatch(code.trim());
  }

  Widget _buildJsonCard(Map<String, dynamic> json) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppConfig.primaryColor,
                radius: 20,
                child: Text(
                  (json['name']?.toString() ?? json['username']?.toString() ?? 'U')[0]
                      .toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      json['name']?.toString() ??
                          json['username']?.toString() ??
                          'Người dùng hệ thống',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (json.containsKey('role')) ...[
                      const SizedBox(height: 4),
                      RoleBadge(role: json['role'].toString()),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...json.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key}: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      e.value.toString(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUrlCard(String url) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.language_rounded, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Địa Chỉ Liên Kết Website (URL):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            url,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBarcodeCard(String barcode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_rounded, color: Colors.amber.shade900, size: 20),
              const SizedBox(width: 8),
              Text(
                'Thông Tin Hàng Hóa / Mã Vạch:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildInfoItem('Mã số vạch (GTIN/EAN):', barcode),
          _buildInfoItem('Tên mặt hàng:', 'Hồ sơ thiết bị / Sản phẩm lưu kho'),
          _buildInfoItem('Mã sinh viên quản lý:', '2380601724 - La Ngô Hoàn Phúc'),
          _buildInfoItem('Trạng thái kiểm định:', 'Hợp lệ & Đã kích hoạt bảo hành'),
        ],
      ),
    );
  }

  Widget _buildTextCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nội dung giải mã:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          SelectableText(
            text,
            style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(width: 6),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanAreaSize = MediaQuery.of(context).size.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Máy Quét QR / Barcode',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? Colors.amber : Colors.white,
            ),
            tooltip: 'Bật/Tắt Đèn Flash',
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white),
            tooltip: 'Đổi Camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Live Camera Scanner Feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 2. Translucent Dark Mask with Viewfinder
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: scanAreaSize,
                    height: scanAreaSize,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Viewfinder Laser Frame with Pulsating Line
          SizedBox(
            width: scanAreaSize,
            height: scanAreaSize,
            child: Stack(
              children: [
                // 4 Corner brackets
                _buildCornerBracket(top: 0, left: 0, isTop: true, isLeft: true),
                _buildCornerBracket(top: 0, right: 0, isTop: true, isLeft: false),
                _buildCornerBracket(bottom: 0, left: 0, isTop: false, isLeft: true),
                _buildCornerBracket(bottom: 0, right: 0, isTop: false, isLeft: false),

                // Animated Laser Line
                AnimatedBuilder(
                  animation: _laserAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: _laserAnimation.value * (scanAreaSize - 4),
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.transparent, Color(0xFF00FF88), Colors.transparent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
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

          // 4. Instructions & Gallery Scanner Button at Bottom
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Hướng camera vào mã QR hoặc mã vạch Barcode để quét',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // Pick from gallery button
                ElevatedButton.icon(
                  onPressed: _scanFromGallery,
                  icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
                  label: const Text(
                    'Chọn Ảnh Mã Từ Thư Viện',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Simulation Chips for Testing/Demo
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.person_pin_rounded, size: 16, color: Colors.white),
                      label: const Text('Quét Thử Thẻ SV', style: TextStyle(color: Colors.white, fontSize: 11)),
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      onPressed: () => _simulateScan(
                        '{"id":"2380601724","name":"La Ngô Hoàn Phúc","role":"Admin","email":"phuc@hutech.edu.vn"}',
                        'QR_CODE',
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.qr_code_scanner, size: 16, color: Colors.white),
                      label: const Text('Quét Thử Barcode', style: TextStyle(color: Colors.white, fontSize: 11)),
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      onPressed: () => _simulateScan('8935001889241', 'EAN_13'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBracket({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    const length = 26.0;
    const thickness = 4.0;
    const color = Color(0xFF00FF88);

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: length,
        height: length,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            left: isLeft ? const BorderSide(color: color, width: thickness) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
