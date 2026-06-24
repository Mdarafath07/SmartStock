import 'package:flutter/material.dart';

enum DateFilter { daily, weekly, monthly, allTime }

class DateFilterBar extends StatelessWidget {
  final DateFilter selectedFilter;
  final ValueChanged<DateFilter> onFilterChanged;

  const DateFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(context, theme, DateFilter.daily, 'Daily'),
          const SizedBox(width: 8),
          _buildChip(context, theme, DateFilter.weekly, 'Weekly'),
          const SizedBox(width: 8),
          _buildChip(context, theme, DateFilter.monthly, 'Monthly'),
          const SizedBox(width: 8),
          _buildChip(context, theme, DateFilter.allTime, 'All Time'),
        ],
      ),
    );
  }

  Widget _buildChip(
      BuildContext context, ThemeData theme, DateFilter filter, String label) {
    final isSelected = selectedFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onFilterChanged(filter),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
