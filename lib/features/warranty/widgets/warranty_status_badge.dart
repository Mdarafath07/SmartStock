import 'package:flutter/material.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/core/theme/text_styles.dart';

class WarrantyStatusBadge extends StatelessWidget {
  final bool isActive;
  final double fontSize;

  const WarrantyStatusBadge({
    super.key,
    required this.isActive,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? ColorConstants.successContainer
            : ColorConstants.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: fontSize + 2,
            color: isActive ? ColorConstants.success : ColorConstants.error,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Expired',
            style: TextStyle(
              fontFamily: AppTextStyles.labelFont,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: isActive ? ColorConstants.success : ColorConstants.error,
            ),
          ),
        ],
      ),
    );
  }
}
