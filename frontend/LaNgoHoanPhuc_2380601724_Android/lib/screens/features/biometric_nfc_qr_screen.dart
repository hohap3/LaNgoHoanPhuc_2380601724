import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import '../../config/app_config.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/custom_button.dart';
import 'qr_barcode_scanner_screen.dart';

class BiometricNfcQrScreen extends StatefulWidget {
  const BiometricNfcQrScreen({super.key});

  @override
  State<BiometricNfcQrScreen> createState() => _BiometricNfcQrScreenState();
}

class _BiometricNfcQrScreenState extends State<BiometricNfcQrScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocalAuthentication _auth = LocalAuthentication();
  final ImagePicker _picker = ImagePicker();

  // Biometric state
  bool _canCheckBiometrics = false;
  bool _isDeviceSupported = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isAuthenticating = false;
  String _authResult = 'Chưa thực hiện quét vân tay';
  bool _authSuccess = false;

  // QR & Barcode state
  final TextEditingController _qrContentController =
      TextEditingController(text: 'SV: 2380601724 | La Ngo Hoan Phuc | Role: Admin');
  final TextEditingController _manualBarcodeInputController = TextEditingController();
  bool _isBarcodeMode = false; // false = QR 2D, true = Barcode 1D
  String _scannedResult = '';
  String _scannedType = '';
  bool _isScanningMedia = false;

  // NFC state
  bool _isNfcScanning = false;
  bool _isNfcWriting = false;
  String _selectedNfcTagType = 'Thẻ Sinh Viên / Nhân Viên';
  final TextEditingController _nfcWriteController =
      TextEditingController(text: 'MSSV: 2380601724 - HUTECH');
  Map<String, String>? _nfcTagData;

  final List<String> _nfcTagTypes = [
    'Thẻ Sinh Viên / Nhân Viên',
    'Thẻ CCCD Gắn Chip (ICAO)',
    'Thẻ Thanh Toán Chạm (EMV Contactless)',
    'Thẻ Thông Minh NDEF (NTAG215)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkBiometricSupport();
    _initDefaultUserQr();
  }

  Future<void> _initDefaultUserQr() async {
    final username = await StorageService.getUsername();
    final roles = await StorageService.getRoles();
    if (username != null && mounted) {
      setState(() {
        _qrContentController.text =
            'ID: 2380601724 | User: $username | Role: ${roles.join(', ')}';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrContentController.dispose();
    _manualBarcodeInputController.dispose();
    _nfcWriteController.dispose();
    super.dispose();
  }

  // ==========================================
  // 1. BIOMETRICS LOGIC
  // ==========================================
  Future<void> _checkBiometricSupport() async {
    bool canCheck = false;
    bool isSupported = false;
    List<BiometricType> available = [];

    try {
      canCheck = await _auth.canCheckBiometrics;
      isSupported = await _auth.isDeviceSupported();
      if (canCheck || isSupported) {
        available = await _auth.getAvailableBiometrics();
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheck;
        _isDeviceSupported = isSupported;
        _availableBiometrics = available;
      });
    }
  }

  Future<void> _authenticateBiometrics() async {
    setState(() {
      _isAuthenticating = true;
      _authResult = 'Đang chờ chạm cảm biến vân tay...';
    });

    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Chạm cảm biến vân tay để xác thực danh tính sinh trắc học',
      );

      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _authSuccess = authenticated;
          _authResult = authenticated
              ? 'Xác thực sinh trắc học vân tay THÀNH CÔNG!'
              : 'Xác thực vân tay thất bại hoặc đã bị hủy!';
        });

        if (authenticated) {
          AppDialogs.showSuccess(context, 'Nhận diện vân tay thành công!');
        } else {
          AppDialogs.showError(context, 'Xác thực không thành công.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _authSuccess = false;
          _authResult = 'Lỗi cảm biến: ${e.toString()}';
        });
        AppDialogs.showError(context, 'Lỗi cảm biến: $e');
      }
    }
  }

  // ==========================================
  // 2. QR & BARCODE LOGIC
  // ==========================================
  Future<void> _scanFromCameraOrGallery(ImageSource source) async {
    try {
      setState(() => _isScanningMedia = true);
      final XFile? image = await _picker.pickImage(source: source);

      if (image == null) {
        setState(() => _isScanningMedia = false);
        return;
      }

      // Simulate optical QR/Barcode decoder
      await Future.delayed(const Duration(milliseconds: 900));

      if (mounted) {
        setState(() {
          _isScanningMedia = false;
          _scannedType = _isBarcodeMode ? 'Barcode (Mã vạch 1D)' : 'Mã QR (2D Code)';
          _scannedResult = _isBarcodeMode
              ? '8938505991824 | Mã sản phẩm: SP-2380601724 | Tiêu chuẩn: EAN-13'
              : '{"mssv":"2380601724","name":"LaNgoHoanPhuc","auth":"VALID","timestamp":"${DateTime.now().toIso8601String()}"}';
        });
        AppDialogs.showSuccess(context, 'Đã quét và giải mã thành công từ ảnh!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanningMedia = false);
        AppDialogs.showError(context, 'Lỗi quét hình ảnh: $e');
      }
    }
  }

  void _manualDecode() {
    final code = _manualBarcodeInputController.text.trim();
    if (code.isEmpty) {
      AppDialogs.showError(context, 'Vui lòng nhập mã cần giải mã!');
      return;
    }

    setState(() {
      _scannedType = code.length > 20 ? 'Mã QR (2D)' : 'Mã Vạch Barcode (1D)';
      _scannedResult = 'Nội dung giải mã: $code\nThời gian xử lý: ${DateTime.now()}';
    });
    AppDialogs.showSuccess(context, 'Đã giải mã thành công!');
  }

  // ==========================================
  // 3. NFC SCAN & WRITE LOGIC
  // ==========================================
  void _startNfcScan() {
    setState(() {
      _isNfcScanning = true;
      _nfcTagData = null;
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;

      Map<String, String> data;
      switch (_selectedNfcTagType) {
        case 'Thẻ CCCD Gắn Chip (ICAO)':
          data = {
            'Chuẩn công nghệ': 'ISO/IEC 7816-4 (ICAO Doc 9303)',
            'Số định danh (UID)': '08:79:33:F1:4A:2D:10',
            'Chíp lưu trữ': 'SmartMX 144K EEPROM',
            'Dữ liệu thẻ': 'Căn cước công dân gắn chip điện tử hợp lệ',
            'Khóa bảo mật': 'BAC / PACE AES-256 Enabled',
            'Tần số hoạt động': '13.56 MHz High Frequency',
            'Thời gian đọc': '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
          };
          break;
        case 'Thẻ Thanh Toán Chạm (EMV Contactless)':
          data = {
            'Chuẩn công nghệ': 'EMV Contactless (PayPass/PayWave)',
            'UID Thẻ': '54:B2:19:9C:88:2E:31',
            'Loại thẻ': 'NFC Type A / ISO 14443-3A',
            'Ứng dụng AID': 'A0000000041010 (Mastercard/Visa)',
            'Trạng thái': 'Đã kết nối giao tiếp chạm an toàn',
            'Thời gian đọc': '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
          };
          break;
        case 'Thẻ Thông Minh NDEF (NTAG215)':
          data = {
            'Chuẩn công nghệ': 'NFC Forum Type 2 Tag (NTAG215)',
            'Serial UID': '04:8E:1A:4C:91:20:80',
            'Định dạng bản tin': 'NDEF Text Record (UTF-8)',
            'Nội dung NDEF': _nfcWriteController.text,
            'Bộ nhớ khả dụng': '504 Bytes',
            'Thời gian đọc': '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
          };
          break;
        default:
          data = {
            'Loại thẻ': 'Thẻ Sinh viên / Nhân viên điểm danh',
            'Tag ID (UID)': '04:A2:8B:1A:3C:6E:80',
            'Chuẩn công nghệ': 'ISO 14443-4A (Mifare Plus EV1)',
            'Định dạng bản tin': 'NDEF Text Record',
            'Nội dung thẻ': 'MSSV: 2380601724 | La Ngo Hoan Phuc | Role: Admin',
            'Dung lượng bộ nhớ': '1024 Bytes (EEPROM)',
            'Tần số hoạt động': '13.56 MHz',
            'Thời gian quét': '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
          };
      }

      setState(() {
        _isNfcScanning = false;
        _nfcTagData = data;
      });
      AppDialogs.showSuccess(context, 'Đã đọc thành công thông tin thẻ NFC!');
    });
  }

  void _writeToNfcTag() {
    final text = _nfcWriteController.text.trim();
    if (text.isEmpty) {
      AppDialogs.showError(context, 'Vui lòng nhập nội dung cần ghi vào thẻ NFC!');
      return;
    }

    setState(() => _isNfcWriting = true);

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _isNfcWriting = false);
      AppDialogs.showSuccess(
        context,
        'Đã ghi thành công bản tin NDEF vào thẻ NFC: "$text"',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        title: const Text('Nhận Diện Vân Tay / NFC / QR'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConfig.primaryColor,
          unselectedLabelColor: AppConfig.textSecondary,
          indicatorColor: AppConfig.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.fingerprint_rounded), text: 'Vân tay'),
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'QR / Barcode'),
            Tab(icon: Icon(Icons.nfc_rounded), text: 'NFC'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFingerprintTab(),
          _buildQrBarcodeTab(),
          _buildNfcTab(),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: VÂN TAY (BIOMETRICS)
  // =========================================================================
  Widget _buildFingerprintTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    size: 54,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bảo Mật Sinh Trắc Học',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Xác thực người dùng an toàn với phần cứng vân tay thiết bị',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Device status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trạng thái cảm biến thiết bị',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 16),
                _buildStatusRow(
                  'Cảm biến sinh trắc học:',
                  _canCheckBiometrics || _isDeviceSupported
                      ? 'Khả dụng (Ready)'
                      : 'Chưa cấu hình / Mô phỏng',
                  _canCheckBiometrics || _isDeviceSupported ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildStatusRow(
                  'Loại nhận diện:',
                  _availableBiometrics.isEmpty
                      ? 'Cảm biến Vân Tay (Fingerprint) / PIN'
                      : _availableBiometrics.map((e) => e.name).join(', '),
                  Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Verification result box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _authSuccess ? Colors.green.shade50 : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _authSuccess ? Colors.green.shade300 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _authSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: _authSuccess ? Colors.green : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _authResult,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _authSuccess ? Colors.green.shade900 : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action button
          CustomButton(
            text: _isAuthenticating ? 'Đang Chờ Quét...' : 'Quét Vân Tay Xác Thực',
            icon: Icons.fingerprint_rounded,
            isLoading: _isAuthenticating,
            backgroundColor: const Color(0xFF6366F1),
            onPressed: _authenticateBiometrics,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: QR CODE & BARCODE (2D & 1D)
  // =========================================================================
  Widget _buildQrBarcodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode Toggle (Mã QR 2D vs Mã Vạch Barcode 1D)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isBarcodeMode = false),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isBarcodeMode ? AppConfig.primaryColor : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2_rounded,
                              size: 18, color: !_isBarcodeMode ? Colors.white : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'Mã QR Code (2D)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: !_isBarcodeMode ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isBarcodeMode = true),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isBarcodeMode ? AppConfig.primaryColor : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.view_week_rounded,
                              size: 18, color: _isBarcodeMode ? Colors.white : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            'Mã Vạch Barcode (1D)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isBarcodeMode ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Visual Generator Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      !_isBarcodeMode ? 'Trình Tạo Mã QR Động' : 'Trình Tạo Mã Vạch Barcode',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppConfig.primaryColor),
                      tooltip: 'Sao chép nội dung mã',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _qrContentController.text));
                        AppDialogs.showSuccess(context, 'Đã sao chép nội dung mã!');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Render Visual QR or Barcode
                if (!_isBarcodeMode)
                  _buildVisualQrMatrix()
                else
                  _buildVisualBarcodeLines(),

                const SizedBox(height: 14),

                // Text field to customize content
                TextField(
                  controller: _qrContentController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Nội dung mã (Gõ để cập nhật mã trực tiếp):',
                    labelStyle: const TextStyle(fontSize: 13),
                    hintText: 'Nhập nội dung mã...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: const Icon(Icons.edit_note_rounded, color: AppConfig.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scan Actions Bar
          const Text(
            'Quét & Giải Mã (Scanner):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppConfig.textPrimary),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QrBarcodeScannerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Quét Camera (Live)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isScanningMedia ? null : () => _scanFromCameraOrGallery(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                  label: const Text('Quét từ Ảnh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Manual code input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualBarcodeInputController,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã số cần tra cứu...',
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _manualDecode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Giải Mã', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Decoded result
          if (_isScanningMedia)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Đang quét và giải mã hình ảnh...'),
                  ],
                ),
              ),
            )
          else if (_scannedResult.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Kết quả giải mã ($_scannedType):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                      ),
                    ],
                  ),
                  const Divider(height: 14),
                  SelectableText(
                    _scannedResult,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.4),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVisualQrMatrix() {
    final text = _qrContentController.text;
    final int hash = text.hashCode.abs();

    return Container(
      width: 180,
      height: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: 49,
            itemBuilder: (ctx, i) {
              final isCorner = (i < 3 || (i >= 7 && i < 10) || (i >= 14 && i < 17)) ||
                  (i % 7 >= 4 && i < 21) ||
                  (i >= 28 && i % 7 < 3);
              final isFilled = isCorner || ((i * 13 + hash) % 3 == 0);
              return Container(
                decoration: BoxDecoration(
                  color: isFilled ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_2_rounded, size: 26, color: AppConfig.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualBarcodeLines() {
    final text = _qrContentController.text;
    final int hash = text.hashCode.abs();

    return Container(
      width: double.infinity,
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(45, (index) {
                final isThick = (index * 7 + hash) % 4 == 0;
                final isSpace = (index * 11 + hash) % 3 == 0 && index > 2 && index < 42;
                return Container(
                  width: isThick ? 4.5 : (isSpace ? 1.0 : 2.5),
                  color: isSpace ? Colors.transparent : Colors.black,
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text.length > 24 ? '${text.substring(0, 24)}...' : text,
            style: const TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: GIAO TIẾP TẦM NGẮN NFC (READ & WRITE)
  // =========================================================================
  Widget _buildNfcTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // NFC Radar Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: _isNfcScanning ? 0.35 : 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.nfc_rounded,
                    size: 54,
                    color: _isNfcScanning ? Colors.amberAccent : Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isNfcScanning ? 'ĐANG DÒ TÌM SÓNG THẺ NFC...' : 'Giao Tiếp Tầm Ngắn (NFC)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _isNfcScanning
                      ? 'Vui lòng đưa thẻ NFC vào mặt lưng điện thoại (13.56 MHz)'
                      : 'Hỗ trợ đọc & ghi thẻ thông minh, thẻ CCCD và thẻ thành viên',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chọn loại thẻ NFC để đọc
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
                const Text(
                  'Chọn loại thẻ NFC cần đọc:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedNfcTagType,
                    isExpanded: true,
                    items: _nfcTagTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedNfcTagType = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action 1: Đọc thẻ
          CustomButton(
            text: _isNfcScanning ? 'Đang Quét Thẻ...' : 'Bắt Đầu Đọc Thẻ NFC',
            icon: Icons.sensors_rounded,
            isLoading: _isNfcScanning,
            backgroundColor: const Color(0xFF0F766E),
            onPressed: _isNfcScanning ? null : _startNfcScan,
          ),
          const SizedBox(height: 16),

          // Display decoded NFC tag data
          if (_nfcTagData != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.credit_card_rounded, color: Color(0xFF0F766E), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Dữ liệu thẻ NFC đã giải mã',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  ..._nfcTagData!.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.key}: ',
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          Expanded(
                            child: SelectableText(
                              e.value,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action 2: Ghi dữ liệu vào thẻ NFC (NFC Writer)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: Color(0xFF0F766E), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ghi Dữ Liệu Vào Thẻ NFC (NFC Writer)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nfcWriteController,
                  decoration: InputDecoration(
                    labelText: 'Nội dung NDEF Text cần ghi:',
                    hintText: 'Nhập chuỗi văn bản hoặc URL...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isNfcWriting ? null : _writeToNfcTag,
                  icon: _isNfcWriting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_isNfcWriting ? 'Đang Ghi Thẻ...' : 'Ghi Dữ Liệu Lên Thẻ NFC'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
