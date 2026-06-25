import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/utils/formatters.dart';
import 'package:smartstock/core/widgets/error_widget.dart';
import 'package:smartstock/features/reports/providers/report_provider.dart';
import 'package:smartstock/features/reports/widgets/download_report_button.dart';
import 'package:smartstock/features/reports/widgets/sales_chart.dart';
import 'package:smartstock/features/reports/widgets/statistics_grid.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadAllReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.dailyReport == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.loadAllReports(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAllReports(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Today\'s Overview'),
                  const SizedBox(height: 12),
                  StatisticsGrid(
                    totalSales: provider.dailyReport?.totalSales ?? 0,
                    totalProfit: provider.dailyReport?.totalProfit ?? 0,
                    totalTransactions: provider.dailyReport?.totalTransactions ?? 0,
                    totalProducts: provider.dailyReport?.totalProductsSold ?? 0,
                  ),
                  const SizedBox(height: 12),
                  _buildDailySummary(provider),
                  const SizedBox(height: 24),
                  _buildAllTimeSummary(provider),
                  const SizedBox(height: 24),
                  _buildYearlyReport(provider),
                  const SizedBox(height: 24),
                  if (provider.categorySales.isNotEmpty) ...[
                    _buildSectionTitle('Sales by Category'),
                    const SizedBox(height: 12),
                    _buildCategoryChart(provider),
                  ],
                  const SizedBox(height: 24),
                  if (provider.topSellingProducts.isNotEmpty) ...[
                    _buildSectionTitle('Top Selling Products'),
                    const SizedBox(height: 12),
                    _buildTopProducts(provider),
                  ],
                  const SizedBox(height: 24),
                  if (provider.yearlyReports.length >= 2) ...[
                    _buildSectionTitle('Monthly Breakdown'),
                    const SizedBox(height: 12),
                    _buildMonthlyChart(provider),
                  ],
                  const SizedBox(height: 24),
                  DownloadReportButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report download started'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMd.copyWith(
        fontSize: 18,
        color: ColorConstants.onSurface,
      ),
    );
  }

  Widget _buildDailySummary(ReportProvider provider) {
    final daily = provider.dailyReport;
    if (daily == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _summaryItem(
                Icons.trending_up_rounded,
                'Today Sales',
                AppFormatters.formatCurrency(daily.totalSales),
                ColorConstants.primary,
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: ColorConstants.outlineVariant,
            ),
            Expanded(
              child: _summaryItem(
                Icons.account_balance_wallet_rounded,
                'Today Profit',
                AppFormatters.formatCurrency(daily.totalProfit),
                ColorConstants.success,
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: ColorConstants.outlineVariant,
            ),
            Expanded(
              child: _summaryItem(
                Icons.receipt_long_rounded,
                'Transactions',
                '${daily.totalTransactions}',
                ColorConstants.info,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTimeSummary(ReportProvider provider) {
    final allTime = provider.allTimeSummary;
    if (allTime == null || allTime.totalTransactions == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('All-Time Summary'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _summaryItem(
                        Icons.trending_up_rounded,
                        'Total Sales',
                        AppFormatters.formatCurrency(allTime.totalSales),
                        ColorConstants.primary,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: ColorConstants.outlineVariant,
                    ),
                    Expanded(
                      child: _summaryItem(
                        Icons.account_balance_wallet_rounded,
                        'Total Profit',
                        AppFormatters.formatCurrency(allTime.totalProfit),
                        ColorConstants.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _summaryItem(
                        Icons.receipt_long_rounded,
                        'Transactions',
                        '${allTime.totalTransactions}',
                        ColorConstants.info,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: ColorConstants.outlineVariant,
                    ),
                    Expanded(
                      child: _summaryItem(
                        Icons.inventory_2_rounded,
                        'Items Sold',
                        '${allTime.totalProductsSold}',
                        ColorConstants.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearlyReport(ReportProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Yearly Report'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final newYear = provider.selectedYear - 1;
                    provider.setSelectedYear(newYear);
                    provider.loadYearlyReport(year: newYear);
                  },
                ),
                Text(
                  '${provider.selectedYear}',
                  style: AppTextStyles.titleMd.copyWith(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final newYear = provider.selectedYear + 1;
                    provider.setSelectedYear(newYear);
                    provider.loadYearlyReport(year: newYear);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildYearlyStats(provider),
      ],
    );
  }

  Widget _buildYearlyStats(ReportProvider provider) {
    final reports = provider.yearlyReports;
    if (reports.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No data for ${provider.selectedYear}',
              style: AppTextStyles.bodyMd.copyWith(
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final totalYearSales = reports.fold<double>(0, (s, r) => s + r.totalSales);
    final totalYearProfit = reports.fold<double>(0, (s, r) => s + r.totalProfit);
    final totalYearTransactions = reports.fold<int>(0, (s, r) => s + r.totalTransactions);

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    Icons.trending_up_rounded,
                    'Year Sales',
                    AppFormatters.formatCurrency(totalYearSales),
                    ColorConstants.primary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: ColorConstants.outlineVariant,
                ),
                Expanded(
                  child: _summaryItem(
                    Icons.account_balance_wallet_rounded,
                    'Year Profit',
                    AppFormatters.formatCurrency(totalYearProfit),
                    ColorConstants.success,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: ColorConstants.outlineVariant,
                ),
                Expanded(
                  child: _summaryItem(
                    Icons.receipt_long_rounded,
                    'Transactions',
                    '$totalYearTransactions',
                    ColorConstants.info,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(ReportProvider provider) {
    final reports = provider.yearlyReports;
    if (reports.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SalesBarChart(
          data: reports,
          title: '',
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleMd.copyWith(
            fontSize: 16,
            color: ColorConstants.onSurface,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(ReportProvider provider) {
    final maxSales = provider.categorySales.fold<double>(
      0,
      (max, c) => c.totalSales > max ? c.totalSales : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: provider.categorySales.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SimpleBar(
                label: cat.categoryName,
                value: cat.totalSales,
                maxValue: maxSales,
                color: ColorConstants.primary,
                formatValue: (v) => AppFormatters.formatCurrency(v),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopProducts(ReportProvider provider) {
    return Card(
      child: Column(
        children: provider.topSellingProducts.take(5).map((product) {
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorConstants.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.inventory_2_rounded,
                          color: ColorConstants.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.inventory_2_rounded,
                      color: ColorConstants.onSurfaceVariant,
                    ),
            ),
            title: Text(
              product.productName,
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Model: ${product.modelNumber}',
              style: AppTextStyles.labelMd.copyWith(
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.quantitySold} sold',
                  style: AppTextStyles.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.primary,
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(product.totalRevenue),
                  style: AppTextStyles.labelSm.copyWith(
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}