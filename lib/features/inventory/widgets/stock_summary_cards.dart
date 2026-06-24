import 'package:flutter/material.dart';
import 'package:smartstock/core/theme/app_colors.dart';

class StockSummaryCards extends StatelessWidget {
  final int totalProducts;
  final int totalAvailable;
  final int lowStockCount;
  final int outOfStockCount;

  const StockSummaryCards({
    super.key,
    required this.totalProducts,
    required this.totalAvailable,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildCard('Total', '$totalProducts', Icons.inventory_2, AppColors.primaryContainer)),
          const SizedBox(width: 8),
          Expanded(child: _buildCard('Available', '$totalAvailable', Icons.check_circle, AppColors.statusInStock)),
          const SizedBox(width: 8),
          Expanded(child: _buildCard('Low Stock', '$lowStockCount', Icons.warning, AppColors.statusLowStock)),
          const SizedBox(width: 8),
          Expanded(child: _buildCard('Out of Stock', '$outOfStockCount', Icons.error, AppColors.statusOutOfStock)),
        ],
      ),
    );
  }

  Widget _buildCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
