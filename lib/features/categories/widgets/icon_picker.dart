import 'package:flutter/material.dart';
import 'package:smartstock/features/categories/widgets/category_icons.dart';
import 'package:smartstock/core/theme/app_colors.dart';

class IconPicker extends StatelessWidget {
  final String selectedIcon;
  final ValueChanged<String> onSelected;

  const IconPicker({
    super.key,
    required this.selectedIcon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Choose Icon',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: categoryIconNames.length,
          itemBuilder: (context, index) {
            final name = categoryIconNames[index];
            final icon = iconFromName(name);
            final isSelected = name == selectedIcon;
            return GestureDetector(
              onTap: () => onSelected(name),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.greyLight,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Icon(icon,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                    size: 22),
              ),
            );
          },
        ),
      ],
    );
  }
}
