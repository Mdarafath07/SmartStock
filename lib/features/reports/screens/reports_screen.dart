import 'package:flutter/material.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.glassBg : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF475569)),
                    ),
                  ),
                  Expanded(child: Text('Reports', style: AppTextStyles.headlineMd.copyWith(color: AppColors.textPrimary))),
                ],
              ),
              const SizedBox(height: 4),
              Text('Generate and view business reports', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  _ReportCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Sales Report',
                    subtitle: 'Daily & monthly sales analysis',
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.salesHistory),
                  ),
                  _ReportCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Profit Report',
                    subtitle: 'Revenue & profit breakdown',
                    color: AppColors.success,
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.reportsAnalytics),
                  ),
                  _ReportCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventory Report',
                    subtitle: 'Stock levels & movement',
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
                  ),
                  _ReportCard(
                    icon: Icons.verified_rounded,
                    title: 'Warranty Report',
                    subtitle: 'Active & expired warranties',
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.warranty),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? AppColors.cardDark : Colors.white).withAlpha(220),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 30 : 8), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSm.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
