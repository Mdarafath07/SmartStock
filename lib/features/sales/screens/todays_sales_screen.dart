import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/sales/providers/sale_provider.dart';
import 'package:smartstock/features/sales/screens/sale_details_screen.dart';
import 'package:smartstock/features/sales/widgets/sale_card.dart';
import 'package:smartstock/features/sales/widgets/sales_summary_header.dart';

class TodaysSalesScreen extends StatefulWidget {
  const TodaysSalesScreen({super.key});

  @override
  State<TodaysSalesScreen> createState() => _TodaysSalesScreenState();
}

class _TodaysSalesScreenState extends State<TodaysSalesScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadTodaysSales();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SaleProvider>().loadTodaysSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final saleProvider = context.watch<SaleProvider>();
    final sales = saleProvider.todaysSales;
    final summary = saleProvider.dailySummary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldBg : AppColors.whiteSoft,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
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
                  Text(
                    "Today's Sales",
                    style: AppTextStyles.headlineMd.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.statusInStockBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Today',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<SaleProvider>().loadDailySalesSummary();
                  if (!context.mounted) return;
                  context.read<SaleProvider>().loadTodaysSales();
                },
                child: sales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 56,
                                color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB)),
                            const SizedBox(height: 16),
                            Text('No sales today',
                                style: AppTextStyles.titleSm.copyWith(
                                  color: AppColors.textSecondary,
                                )),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: SalesSummaryHeader(
                              totalAmount:
                                  (summary['totalAmount'] as double?) ?? 0.0,
                              totalCount:
                                  (summary['totalCount'] as int?) ?? 0,
                              totalProfit:
                                  (summary['totalProfit'] as double?) ?? 0.0,
                            ),
                          ),
                          ...sales.map(
                            (sale) => SaleCard(
                              sale: sale,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SaleDetailsScreen(saleId: sale.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
