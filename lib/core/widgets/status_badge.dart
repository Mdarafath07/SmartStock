import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.fontSize = 10,
  });

  factory StatusBadge.stock(int quantity) {
    if (quantity <= 0) {
      return StatusBadge(label: 'Out of Stock', color: AppColors.error, icon: Icons.error_outline_rounded,
        backgroundColor: AppColors.statusOutOfStockBg);
    }
    if (quantity <= 5) {
      return StatusBadge(label: 'Low Stock', color: AppColors.warning, icon: Icons.warning_rounded,
        backgroundColor: AppColors.statusLowStockBg);
    }
    return StatusBadge(label: 'In Stock', color: AppColors.success, icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.statusInStockBg);
  }

  factory StatusBadge.warranty(bool isActive) {
    return isActive
        ? StatusBadge(label: 'Active', color: AppColors.success, icon: Icons.check_circle_rounded,
            backgroundColor: AppColors.statusInStockBg)
        : StatusBadge(label: 'Expired', color: AppColors.error, icon: Icons.cancel_rounded,
            backgroundColor: AppColors.statusOutOfStockBg);
  }

  factory StatusBadge.claimStatus(String status) {
    switch (status) {
      case 'pending':
        return StatusBadge(label: 'Pending', color: AppColors.warning, icon: Icons.schedule_rounded,
          backgroundColor: AppColors.statusLowStockBg);
      case 'completed':
        return StatusBadge(label: 'Completed', color: AppColors.success, icon: Icons.check_circle_rounded,
          backgroundColor: AppColors.statusInStockBg);
      case 'rejected':
        return StatusBadge(label: 'Rejected', color: AppColors.error, icon: Icons.cancel_rounded,
          backgroundColor: AppColors.statusOutOfStockBg);
      default:
        return StatusBadge(label: status, color: AppColors.textSecondary,
          backgroundColor: AppColors.greyLight);
    }
  }

  factory StatusBadge.issueStatus(String status) {
    switch (status) {
      case 'open':
        return StatusBadge(label: 'Open', color: AppColors.error, icon: Icons.error_outline_rounded,
          backgroundColor: AppColors.statusOutOfStockBg);
      case 'in_progress':
        return StatusBadge(label: 'In Progress', color: AppColors.warning, icon: Icons.schedule_rounded,
          backgroundColor: AppColors.statusLowStockBg);
      case 'resolved':
        return StatusBadge(label: 'Resolved', color: AppColors.success, icon: Icons.check_circle_rounded,
          backgroundColor: AppColors.statusInStockBg);
      default:
        return StatusBadge(label: status, color: AppColors.textSecondary,
          backgroundColor: AppColors.greyLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.greyLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
