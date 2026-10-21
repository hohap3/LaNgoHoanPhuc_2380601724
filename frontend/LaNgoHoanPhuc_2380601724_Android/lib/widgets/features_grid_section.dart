import 'package:flutter/material.dart';
import '../screens/features/biometric_nfc_qr_screen.dart';
import '../screens/features/location_sharing_screen.dart';
import '../screens/features/translation_screen.dart';

class FeaturesGridSection extends StatelessWidget {
  const FeaturesGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 8),
            Text(
              'Tính năng mở rộng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 1. Chia sẻ vị trí
            Expanded(
              child: _buildFeatureCard(
                context: context,
                title: 'Chia sẻ vị trí',
                subtitle: 'GPS & Bản đồ',
                icon: Icons.share_location_rounded,
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LocationSharingScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // 2. Vân tay / NFC / QR
            Expanded(
              child: _buildFeatureCard(
                context: context,
                title: 'Vân tay / QR',
                subtitle: 'NFC & Sinh trắc',
                icon: Icons.fingerprint_rounded,
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BiometricNfcQrScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),

            // 3. Dịch realtime / Ảnh chụp
            Expanded(
              child: _buildFeatureCard(
                context: context,
                title: 'Dịch thuật',
                subtitle: 'Realtime & Ảnh',
                icon: Icons.translate_rounded,
                color: const Color(0xFF0D9488),
                bgColor: const Color(0xFFF0FDFA),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TranslationScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
