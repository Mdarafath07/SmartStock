import 'package:flutter/material.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/categories/models/category_model.dart';

class FilterBar extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final String? selectedStockStatus;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStockStatusChanged;
  final VoidCallback onClear;

  const FilterBar({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    this.selectedStockStatus,
    required this.onCategoryChanged,
    required this.onStockStatusChanged,
    required this.onClear,
  });

  static const _stockStatuses = [
    {'id': 'in_stock', 'label': 'In Stock'},
    {'id': 'low_stock', 'label': 'Low Stock'},
    {'id': 'out_of_stock', 'label': 'Out of Stock'},
    {'id': 'overstock', 'label': 'Overstock'},
  ];

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter =
        selectedCategoryId != null || selectedStockStatus != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildChip(
                label: 'All',
                selected: selectedCategoryId == null,
                onTap: () => onCategoryChanged(null),
              ),
              const SizedBox(width: 8),
              ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildChip(
                      label: cat.name,
                      selected: selectedCategoryId == cat.id,
                      onTap: () => onCategoryChanged(cat.id),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ..._stockStatuses.map((status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildChip(
                      label: status['label'] as String,
                      selected: selectedStockStatus == status['id'],
                      onTap: () => onStockStatusChanged(
                          selectedStockStatus == status['id']
                              ? null
                              : status['id'] as String),
                    ),
                  )),
              if (hasActiveFilter) ...[
                const SizedBox(width: 8),
                _buildClearChip(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryContainer : AppColors.outline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildClearChip() {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, size: 14, color: AppColors.onErrorContainer),
            SizedBox(width: 4),
            Text(
              'Clear',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
