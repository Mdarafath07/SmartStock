import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/utils/formatters.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/features/reports/providers/report_provider.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:smartstock/features/reports/widgets/download_report_button.dart';
import 'package:smartstock/features/reports/widgets/sales_chart.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final symbol = context.watch<SettingsProvider>().currencySymbol;

    return Scaffold(
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.dailyReport == null) {
            return _buildSkeleton(isDark);
          }

          if (provider.error != null) {
            return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.error)),
                const SizedBox(height: 16),
                Text(provider.error!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: () => provider.loadAllReports(), icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
              ],
            ));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAllReports(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics', style: AppTextStyles.headlineMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                  const SizedBox(height: 4),
                  Text('Track your business performance', style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
                  const SizedBox(height: 20),
                  _buildTodayOverview(provider, symbol, isDark),
                  const SizedBox(height: 16),
                  _buildDailySummary(provider, symbol, isDark),
                  const SizedBox(height: 16),
                  _buildAllTimeSummary(provider, symbol, isDark),
                  const SizedBox(height: 16),
                  _buildYearlyReport(provider, symbol, isDark),
                  const SizedBox(height: 16),
                  if (provider.categorySales.isNotEmpty) ...[
                    _buildCategorySection(provider, symbol, isDark),
                    const SizedBox(height: 16),
                  ],
                  if (provider.topSellingProducts.isNotEmpty) ...[
                    _buildTopProductsSection(provider, symbol, isDark),
                    const SizedBox(height: 16),
                  ],
                  if (provider.yearlyReports.length >= 2) ...[
                    _buildMonthlySection(provider, isDark),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  DownloadReportButton(onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report download started')),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayOverview(ReportProvider provider, String symbol, bool isDark) {
    final daily = provider.dailyReport;
    return ModernCard(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: isDark ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)] : [AppColors.greenDark, AppColors.greenLight],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Overview", style: AppTextStyles.titleMd.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white.withAlpha(160))),
                    const SizedBox(height: 4),
                    Text(AppFormatters.formatCurrency(daily?.totalSales ?? 0, symbol: symbol),
                        style: AppTextStyles.amountMd.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withAlpha(40)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Profit', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white.withAlpha(160))),
                    const SizedBox(height: 4),
                    Text(AppFormatters.formatCurrency(daily?.totalProfit ?? 0, symbol: symbol),
                        style: AppTextStyles.amountMd.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MinStat(label: 'Transactions', value: '${daily?.totalTransactions ?? 0}', isDark: false),
              const SizedBox(width: 12),
              _MinStat(label: 'Items Sold', value: '${daily?.totalProductsSold ?? 0}', isDark: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummary(ReportProvider provider, String symbol, bool isDark) {
    final daily = provider.dailyReport;
    if (daily == null) return const SizedBox.shrink();

    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Breakdown", style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          Row(
            children: [
              _AnalyticItem(label: 'Sales', value: AppFormatters.formatCurrency(daily.totalSales, symbol: symbol), color: AppColors.primary, isDark: isDark),
              const SizedBox(width: 8),
              _AnalyticItem(label: 'Profit', value: AppFormatters.formatCurrency(daily.totalProfit, symbol: symbol), color: AppColors.green, isDark: isDark),
              const SizedBox(width: 8),
              _AnalyticItem(label: 'Transactions', value: '${daily.totalTransactions}', color: AppColors.blue, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllTimeSummary(ReportProvider provider, String symbol, bool isDark) {
    final allTime = provider.allTimeSummary;
    if (allTime == null || allTime.totalTransactions == 0) return const SizedBox.shrink();

    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('All-Time Summary', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          Row(
            children: [
              _AnalyticItem(label: 'Total Sales', value: AppFormatters.formatCurrency(allTime.totalSales, symbol: symbol), color: AppColors.primary, isDark: isDark),
              const SizedBox(width: 8),
              _AnalyticItem(label: 'Total Profit', value: AppFormatters.formatCurrency(allTime.totalProfit, symbol: symbol), color: AppColors.green, isDark: isDark),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _AnalyticItem(label: 'Transactions', value: '${allTime.totalTransactions}', color: AppColors.blue, isDark: isDark),
              const SizedBox(width: 8),
              _AnalyticItem(label: 'Items Sold', value: '${allTime.totalProductsSold}', color: AppColors.orange, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyReport(ReportProvider provider, String symbol, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Yearly Report', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
              Row(
                children: [
                  GestureDetector(
                    onTap: () { final ny = provider.selectedYear - 1; provider.setSelectedYear(ny); provider.loadYearlyReport(year: ny); },
                    child: Container(width: 32, height: 32,
                      decoration: BoxDecoration(color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.chevron_left_rounded, size: 18)),
                  ),
                  const SizedBox(width: 8),
                  Text('${provider.selectedYear}', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () { final ny = provider.selectedYear + 1; provider.setSelectedYear(ny); provider.loadYearlyReport(year: ny); },
                    child: Container(width: 32, height: 32,
                      decoration: BoxDecoration(color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.chevron_right_rounded, size: 18)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildYearlyStats(provider, symbol, isDark),
        ],
      ),
    );
  }

  Widget _buildYearlyStats(ReportProvider provider, String symbol, bool isDark) {
    final reports = provider.yearlyReports;
    if (reports.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16),
        child: Text('No data for ${provider.selectedYear}', style: AppTextStyles.bodyMd.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280)))));
    }

    final totalYearSales = reports.fold<double>(0, (s, r) => s + r.totalSales);
    final totalYearProfit = reports.fold<double>(0, (s, r) => s + r.totalProfit);
    final totalYearTransactions = reports.fold<int>(0, (s, r) => s + r.totalTransactions);

    return Row(
      children: [
        _AnalyticItem(label: 'Year Sales', value: AppFormatters.formatCurrency(totalYearSales, symbol: symbol), color: AppColors.primary, isDark: isDark),
        const SizedBox(width: 8),
        _AnalyticItem(label: 'Year Profit', value: AppFormatters.formatCurrency(totalYearProfit, symbol: symbol), color: AppColors.green, isDark: isDark),
        const SizedBox(width: 8),
        _AnalyticItem(label: 'Transactions', value: '$totalYearTransactions', color: AppColors.blue, isDark: isDark),
      ],
    );
  }

  Widget _buildCategorySection(ReportProvider provider, String symbol, bool isDark) {
    final maxSales = provider.categorySales.fold<double>(0, (max, c) => c.totalSales > max ? c.totalSales : max);

    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sales by Category', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          ...provider.categorySales.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cat.categoryName, style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                    Text(AppFormatters.formatCurrency(cat.totalSales, symbol: symbol), style: AppTextStyles.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maxSales > 0 ? (cat.totalSales / maxSales).clamp(0.0, 1.0) : 0,
                    minHeight: 6,
                    backgroundColor: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(100),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection(ReportProvider provider, String symbol, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Selling Products', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          ...provider.topSellingProducts.take(5).map((product) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceLight : const Color(0xFFF9FAFB)).withAlpha(180),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: isDark ? AppColors.greyDarker.withAlpha(100) : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(8)),
                  child: product.imageUrl.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(product.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_rounded, size: 18, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))))
                      : Icon(Icons.inventory_2_rounded, size: 18, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.productName, style: AppTextStyles.bodyMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E), fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Model: ${product.modelNumber}', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${product.quantitySold} sold', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    Text(AppFormatters.formatCurrency(product.totalRevenue, symbol: symbol), style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMonthlySection(ReportProvider provider, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Breakdown', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          SizedBox(height: 200, child: SalesBarChart(data: provider.yearlyReports, title: '')),
        ],
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(children: List.generate(5, (_) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(color: (isDark ? AppColors.shimmerBase : const Color(0xFFE5E7EB)).withAlpha(150), borderRadius: BorderRadius.circular(12)),
      ))),
    );
  }
}

class _MinStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _MinStat({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white.withAlpha(160))),
            ),
            Text(value, style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _AnalyticItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _AnalyticItem({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.amountSm.copyWith(color: color, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
