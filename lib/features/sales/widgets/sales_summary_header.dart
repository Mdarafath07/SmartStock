import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesSummaryHeader extends StatelessWidget {
  final double totalAmount;
  final int totalCount;
  final double totalProfit;

  const SalesSummaryHeader({
    super.key,
    required this.totalAmount,
    required this.totalCount,
    this.totalProfit = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(symbol: '\$');

    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Sales",
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: theme.colorScheme.onPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatter.format(totalAmount),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.trending_up,
                            size: 14,
                            color: theme.colorScheme.onPrimary
                                .withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          'Profit: ${formatter.format(totalProfit)}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimary
                                .withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$totalCount',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Products',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onPrimary),
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
