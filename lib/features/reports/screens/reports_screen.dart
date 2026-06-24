import 'package:flutter/material.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/features/reports/widgets/report_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
          children: [
            ReportCard(
              icon: Icons.trending_up_rounded,
              title: 'Sales Report',
              subtitle: 'Daily and monthly sales analysis',
              color: ColorConstants.primary,
              onTap: () =>
                  Navigator.pushNamed(context, '/sales/history'),
            ),
            ReportCard(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Profit Report',
              subtitle: 'Revenue and profit breakdown',
              color: ColorConstants.success,
              onTap: () =>
                  Navigator.pushNamed(context, '/reports/analytics'),
            ),
            ReportCard(
              icon: Icons.inventory_2_rounded,
              title: 'Inventory Report',
              subtitle: 'Stock levels and movement',
              color: ColorConstants.info,
              onTap: () =>
                  Navigator.pushNamed(context, '/inventory'),
            ),
            ReportCard(
              icon: Icons.verified_user_rounded,
              title: 'Warranty Report',
              subtitle: 'Active and expired warranties',
              color: ColorConstants.warning,
              onTap: () =>
                  Navigator.pushNamed(context, '/warranty'),
            ),
          ],
        ),
      ),
    );
  }
}
