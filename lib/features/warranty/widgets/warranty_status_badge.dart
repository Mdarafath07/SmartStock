import 'package:flutter/material.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/core/theme/text_styles.dart';

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
    final Color bgColor;
    final Color fgColor;
    final IconData icon;
    final String label;

    if (isClaimed) {
      bgColor = ColorConstants.surfaceContainerHighest;
      fgColor = ColorConstants.onSurfaceVariant;
      icon = Icons.assignment_rounded;
      label = 'Claimed';
    } else if (isActive) {
      bgColor = ColorConstants.successContainer;
      fgColor = ColorConstants.success;
      icon = Icons.check_circle_rounded;
      label = 'Active';
    } else {
      bgColor = ColorConstants.errorContainer;
      fgColor = ColorConstants.error;
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
              fontFamily: AppTextStyles.labelFont,
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
