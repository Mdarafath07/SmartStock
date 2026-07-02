import 'package:flutter/material.dart';
import 'package:smartstock/core/theme/app_colors.dart';

class WarrantyStatusBadge extends StatelessWidget {
  final bool isActive;
  final bool isClaimed;
  final double fontSize;

  const WarrantyStatusBadge({
    super.key,
    required this.isActive,
    this.isClaimed = false,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor;
    final Color fgColor;
    final IconData icon;
    final String label;

    if (isClaimed) {
      bgColor = isDark ? AppColors.cardDark : const Color(0xFFE4E1EA);
      fgColor = isDark ? AppColors.textSecondary : const Color(0xFF454652);
      icon = Icons.assignment_rounded;
      label = 'Claimed';
    } else if (isActive) {
      bgColor = AppColors.success.withAlpha(30);
      fgColor = AppColors.success;
      icon = Icons.check_circle_rounded;
      label = 'Active';
    } else {
      bgColor = AppColors.error.withAlpha(30);
      fgColor = AppColors.error;
      icon = Icons.cancel_rounded;
      label = 'Expired';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: fgColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
