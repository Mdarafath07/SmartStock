import 'package:flutter/material.dart';
import '../constants/color_constants.dart';
import '../theme/text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: fontSize + 2,
            color: config.color,
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontFamily: AppTextStyles.labelFont,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              height: 14 / fontSize,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getConfig(String status) {
    switch (status.toLowerCase()) {
      case 'in_stock':
      case 'active':
        return _StatusConfig(
          label: status == 'active' ? 'Active' : 'In Stock',
          color: ColorConstants.success,
          backgroundColor: ColorConstants.successContainer,
          icon: Icons.check_circle_rounded,
        );
      case 'low_stock':
        return _StatusConfig(
          label: 'Low Stock',
          color: ColorConstants.warning,
          backgroundColor: ColorConstants.warningContainer,
          icon: Icons.warning_amber_rounded,
        );
      case 'out_of_stock':
      case 'expired':
        return _StatusConfig(
          label: status == 'expired' ? 'Expired' : 'Out of Stock',
          color: ColorConstants.error,
          backgroundColor: ColorConstants.errorContainer,
          icon: Icons.cancel_rounded,
        );
      case 'overstock':
        return _StatusConfig(
          label: 'Overstock',
          color: ColorConstants.info,
          backgroundColor: ColorConstants.infoContainer,
          icon: Icons.inventory_2_rounded,
        );
      default:
        return _StatusConfig(
          label: status,
          color: ColorConstants.onSurfaceVariant,
          backgroundColor: ColorConstants.surfaceContainerHighest,
          icon: Icons.help_outline_rounded,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });
}
