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
      return StatusBadge(label: 'Out of Stock', color: AppColors.red, icon: Icons.error_outline_rounded);
    }
    if (quantity <= 5) {
      return StatusBadge(label: 'Low Stock', color: AppColors.orange, icon: Icons.warning_rounded);
    }
    return StatusBadge(label: 'In Stock', color: AppColors.green, icon: Icons.check_circle_rounded);
  }

  factory StatusBadge.warranty(bool isActive) {
    return isActive
        ? StatusBadge(label: 'Active', color: AppColors.green, icon: Icons.check_circle_rounded)
        : StatusBadge(label: 'Expired', color: AppColors.red, icon: Icons.cancel_rounded);
  }

  factory StatusBadge.claimStatus(String status) {
    switch (status) {
      case 'pending':
        return StatusBadge(label: 'Pending', color: AppColors.orange, icon: Icons.schedule_rounded);
      case 'completed':
        return StatusBadge(label: 'Completed', color: AppColors.green, icon: Icons.check_circle_rounded);
      case 'rejected':
        return StatusBadge(label: 'Rejected', color: AppColors.red, icon: Icons.cancel_rounded);
      default:
        return StatusBadge(label: status, color: AppColors.grey);
    }
  }

  factory StatusBadge.issueStatus(String status) {
    switch (status) {
      case 'open':
        return StatusBadge(label: 'Open', color: AppColors.red, icon: Icons.error_outline_rounded);
      case 'in_progress':
        return StatusBadge(label: 'In Progress', color: AppColors.orange, icon: Icons.schedule_rounded);
      case 'resolved':
        return StatusBadge(label: 'Resolved', color: AppColors.green, icon: Icons.check_circle_rounded);
      default:
        return StatusBadge(label: status, color: AppColors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withAlpha(25),
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
