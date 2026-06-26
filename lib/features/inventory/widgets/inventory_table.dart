import 'package:flutter/material.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/inventory/models/inventory_model.dart';

class InventoryTable extends StatelessWidget {
  final List<InventoryItem> items;
  final void Function(InventoryItem item)? onItemTap;

  const InventoryTable({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 48, color: AppColors.onSurfaceVariant),
            SizedBox(height: 8),
            Text(
              'No inventory items found',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        color: AppColors.outlineVariant,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildRow(item);
      },
    );
  }

  Widget _buildRow(InventoryItem item) {
    return Debounced(
      onPressed: () => onItemTap?.call(item),
      builder: (context, isDisabled) => InkWell(
        onTap: isDisabled ? null : () => onItemTap?.call(item),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholderIcon(),
                    )
                  : _placeholderIcon(),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.categoryName} • ${item.modelNumber}',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${item.availableStock}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${item.soldStock}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(item.stockStatus),
          ],
        ),
      ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.surfaceContainerHighest,
      child: const Icon(
        Icons.inventory_2,
        size: 24,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'in_stock':
        bgColor = AppColors.statusInStockBg;
        textColor = AppColors.statusInStock;
        icon = Icons.check_circle;
        label = 'In Stock';
        break;
      case 'low_stock':
        bgColor = AppColors.statusLowStockBg;
        textColor = AppColors.statusLowStock;
        icon = Icons.warning;
        label = 'Low Stock';
        break;
      case 'out_of_stock':
        bgColor = AppColors.statusOutOfStockBg;
        textColor = AppColors.statusOutOfStock;
        icon = Icons.error;
        label = 'Out of Stock';
        break;
      default:
        bgColor = AppColors.statusOverstockBg;
        textColor = AppColors.statusOverstock;
        icon = Icons.inventory_2;
        label = 'Overstock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
