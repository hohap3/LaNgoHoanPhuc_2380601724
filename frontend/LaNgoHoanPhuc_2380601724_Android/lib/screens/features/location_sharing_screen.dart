import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_config.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/custom_button.dart';

class LocationSharingScreen extends StatefulWidget {
  const LocationSharingScreen({super.key});

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen> {
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isLiveTracking = false;
  String _statusMessage = 'Sẵn sàng lấy vị trí GPS hiện tại';
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      AppDialogs.showError(
        context,
        'Dịch vụ định vị GPS đang tắt. Vui lòng bật định vị trên thiết bị!',
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return false;
        AppDialogs.showError(context, 'Quyền truy cập vị trí bị từ chối!');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      AppDialogs.showError(
        context,
        'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt ứng dụng.',
      );
      return false;
    }

    return true;
  }

  Future<void> _fetchCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang kết nối vệ tinh GPS để lấy tọa độ...';
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _statusMessage = 'Đã định vị thành công lúc ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Lỗi lấy vị trí: ${e.toString()}';
      });
      if (mounted) {
        AppDialogs.showError(context, 'Không thể lấy vị trí: $e');
      }
    }
  }

  void _toggleLiveTracking() {
    if (_isLiveTracking) {
      _positionStreamSubscription?.cancel();
      setState(() {
        _isLiveTracking = false;
        _statusMessage = 'Đã dừng theo dõi vị trí thời gian thực.';
      });
    } else {
      setState(() {
        _isLiveTracking = true;
        _statusMessage = 'Đang theo dõi vị trí thời gian thực...';
      });

      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: settings).listen(
        (Position? position) {
          if (position != null && mounted) {
            setState(() {
              _currentPosition = position;
              _statusMessage = 'Cập nhật trực tiếp: ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}';
            });
          }
        },
        onError: (e) {
          if (mounted) {
            AppDialogs.showError(context, 'Lỗi cập nhật trực tiếp: $e');
          }
        },
      );
    }
  }

  String get _googleMapsUrl {
    if (_currentPosition == null) return '';
    return 'https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';
  }

  String _formatShareText({bool isSos = false}) {
    if (_currentPosition == null) return '';
    final lat = _currentPosition!.latitude.toStringAsFixed(6);
    final lng = _currentPosition!.longitude.toStringAsFixed(6);
    final accuracy = _currentPosition!.accuracy.toStringAsFixed(1);

    if (isSos) {
      return '🚨 [KHẨN CẤP / SOS] Tôi đang cần hỗ trợ tại vị trí:\n'
          '📍 Tọa độ: $lat, $lng (Độ chính xác: ±$accuracy m)\n'
          '🗺️ Google Maps: $_googleMapsUrl';
    }

    return '📍 Vị trí hiện tại của tôi:\n'
        '• Tọa độ: $lat, $lng\n'
        '• Độ chính xác: ±$accuracy mét\n'
        '• Xem trên Google Maps: $_googleMapsUrl';
  }

  void _shareLocation({bool isSos = false}) {
    if (_currentPosition == null) {
      AppDialogs.showError(context, 'Chưa có dữ liệu vị trí để chia sẻ!');
      return;
    }
    final text = _formatShareText(isSos: isSos);
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: isSos ? 'Cảnh báo vị trí SOS' : 'Chia sẻ vị trí GPS',
      ),
    );
  }

  void _copyToClipboard() {
    if (_currentPosition == null) return;
    Clipboard.setData(ClipboardData(text: _formatShareText()));
    AppDialogs.showSuccess(context, 'Đã sao chép tọa độ & Link Google Maps vào bộ nhớ tạm!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: AppBar(
        title: const Text('Chia Sẻ Vị Trí (GPS Location)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới vị trí',
            onPressed: _isLoading ? null : _fetchCurrentLocation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status & Radar Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isLiveTracking ? Icons.navigation_rounded : Icons.my_location_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Định Vị Vệ Tinh Toàn Cầu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Coordinate Metrics Card
            if (_isLoading)
              const ContainerMetricsLoading()
            else if (_currentPosition != null)
              _buildCoordinatesCard()
            else
              _buildNoLocationCard(),

            const SizedBox(height: 20),

            // Main Share Buttons
            CustomButton(
              text: 'Chia Sẻ Vị Trí Nhanh',
              icon: Icons.share_rounded,
              backgroundColor: const Color(0xFF2563EB),
              onPressed: _currentPosition != null ? () => _shareLocation() : null,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentPosition != null ? _copyToClipboard : null,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Sao chép Link'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleLiveTracking,
                    icon: Icon(
                      _isLiveTracking ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                      size: 20,
                    ),
                    label: Text(_isLiveTracking ? 'Dừng Live' : 'Live Tracking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLiveTracking ? Colors.red.shade600 : Colors.teal.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // SOS Alert button
            ElevatedButton.icon(
              onPressed: _currentPosition != null ? () => _shareLocation(isSos: true) : null,
              icon: const Icon(Icons.emergency_rounded, color: Colors.white),
              label: const Text(
                'GỬI TỌA ĐỘ CỨU HỘ KHẨN CẤP (SOS)',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatesCard() {
    final pos = _currentPosition!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pin_drop_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 8),
              Text(
                'Thông số tọa độ GPS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildInfoRow('Vĩ độ (Latitude):', pos.latitude.toStringAsFixed(6), Icons.north_rounded),
          const SizedBox(height: 8),
          _buildInfoRow('Kinh độ (Longitude):', pos.longitude.toStringAsFixed(6), Icons.east_rounded),
          const SizedBox(height: 8),
          _buildInfoRow('Độ chính xác (Accuracy):', '±${pos.accuracy.toStringAsFixed(1)} mét', Icons.gps_fixed_rounded),
          const SizedBox(height: 8),
          _buildInfoRow('Độ cao (Altitude):', '${pos.altitude.toStringAsFixed(1)} m', Icons.height_rounded),
          const SizedBox(height: 8),
          _buildInfoRow('Vận tốc (Speed):', '${(pos.speed * 3.6).toStringAsFixed(1)} km/h', Icons.speed_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const Spacer(),
        SelectableText(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
        ),
      ],
    );
  }

  Widget _buildNoLocationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.location_disabled_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Chưa có dữ liệu vị trí',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bấm "Làm mới vị trí" để kích hoạt lấy tọa độ vệ tinh GPS.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ContainerMetricsLoading extends StatelessWidget {
  const ContainerMetricsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Đang truy vấn tín hiệu GPS...', style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
