import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/constants/color_constants.dart';
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
        _statCard(
          'Total Sales',
          AppFormatters.formatCurrency(totalSales, symbol: symbol),
          Icons.trending_up_rounded,
          ColorConstants.primary,
        ),
        _statCard(
          'Total Profit',
          AppFormatters.formatCurrency(totalProfit, symbol: symbol),
          Icons.account_balance_wallet_rounded,
          ColorConstants.success,
        ),
        _statCard(
          'Transactions',
          totalTransactions.toString(),
          Icons.receipt_long_rounded,
          ColorConstants.info,
        ),
        _statCard(
          'Products Sold',
          totalProducts.toString(),
          Icons.inventory_2_rounded,
          ColorConstants.warning,
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
                color: ColorConstants.onSurface,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.labelMd.copyWith(
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
