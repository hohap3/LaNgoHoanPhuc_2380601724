import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final double fontSize;

  const RoleBadge({
    super.key,
    required this.role,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    IconData icon;

    switch (role.toLowerCase()) {
      case 'admin':
        bg = const Color(0xFFEDE9FE); // Light purple
        text = const Color(0xFF6D28D9); // Dark purple
        icon = Icons.admin_panel_settings_rounded;
        break;
      case 'staff':
      case 'nhân viên':
      case 'employee':
        bg = const Color(0xFFFEF3C7); // Light amber
        text = const Color(0xFFB45309); // Dark amber
        icon = Icons.badge_rounded;
        break;
      case 'customer':
      case 'khách hàng':
      default:
        bg = const Color(0xFFD1FAE5); // Light emerald
        text = const Color(0xFF047857); // Dark emerald
        icon = Icons.person_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: text),
          const SizedBox(width: 4),
          Text(
            role,
            style: TextStyle(
              color: text,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
