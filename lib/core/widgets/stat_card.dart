import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../widgets/debounced.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Debounced(
        onPressed: onTap,
        builder: (context, isDisabled) => InkWell(
          onTap: isDisabled ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                color: color,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      value,
                      style: AppTextStyles.displayLg.copyWith(
                        fontSize: 28,
                        height: 32 / 28,
                        color: isDark ? AppColors.textPrimary : const Color(0xFF1B1B21),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
