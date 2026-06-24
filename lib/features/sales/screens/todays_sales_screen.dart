import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/features/sales/providers/sale_provider.dart';
import 'package:smartstock/features/sales/screens/sale_details_screen.dart';
import 'package:smartstock/features/sales/widgets/sale_card.dart';
import 'package:smartstock/features/sales/widgets/sales_summary_header.dart';

class TodaysSalesScreen extends StatefulWidget {
  const TodaysSalesScreen({super.key});

  @override
  State<TodaysSalesScreen> createState() => _TodaysSalesScreenState();
}

class _TodaysSalesScreenState extends State<TodaysSalesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadTodaysSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saleProvider = context.watch<SaleProvider>();
    final sales = saleProvider.todaysSales;
    final summary = saleProvider.dailySummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Sales"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
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
                    Icon(Icons.receipt_long,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('No sales today',
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: SalesSummaryHeader(
                      totalAmount:
                          (summary['totalAmount'] as double?) ?? 0.0,
                      totalCount:
                          (summary['totalCount'] as int?) ?? 0,
                      totalProfit:
                          (summary['totalProfit'] as double?) ?? 0.0,
                    ),
                  ),
                  const SizedBox(height: 8),
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
    );
  }
}
