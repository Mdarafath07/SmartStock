import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/utils/formatters.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class StatisticsGrid extends StatelessWidget {
  final double totalSales;
  final double totalProfit;
  final int totalTransactions;
  final int totalProducts;

  const StatisticsGrid({
    super.key,
    required this.totalSales,
    required this.totalProfit,
    required this.totalTransactions,
    required this.totalProducts,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard(context,
          'Total Sales',
          AppFormatters.formatCurrency(totalSales, symbol: symbol),
          Icons.trending_up_rounded,
          AppColors.primary,
        ),
        _statCard(context,
          'Total Profit',
          AppFormatters.formatCurrency(totalProfit, symbol: symbol),
          Icons.account_balance_wallet_rounded,
          AppColors.success,
        ),
        _statCard(context,
          'Transactions',
          totalTransactions.toString(),
          Icons.receipt_long_rounded,
          AppColors.info,
        ),
        _statCard(context,
          'Products Sold',
          totalProducts.toString(),
          Icons.inventory_2_rounded,
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.titleMd.copyWith(
                fontSize: 18,
                color: isDark ? AppColors.textPrimary : const Color(0xFF1B1B21),
              ),
            ),
            Text(
              title,
              style: AppTextStyles.labelMd.copyWith(
                color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
