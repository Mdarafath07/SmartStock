import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';

class SaleCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback? onTap;

  const SaleCard({super.key, required this.sale, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormatter = DateFormat('hh:mm a');
    final priceFormatter = NumberFormat.currency(symbol: '\$');
    final profitColor = sale.profit >= 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sale.productName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (sale.isReplacement)
                    _badge('Replacement', Colors.orange, theme)
                  else if (sale.isWarrantyClaim)
                    _badge('Warranty', Colors.blue, theme),
                  if (!sale.isReplacement && !sale.isWarrantyClaim)
                    Text(
                      timeFormatter.format(sale.saleDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Model: ${sale.modelNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: sale.serialNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Serial number copied')),
                  );
                },
                child: Text(
                  'S/N: ${sale.serialNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.customerName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          sale.customerPhone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceFormatter.format(sale.salePrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Profit: ${priceFormatter.format(sale.profit)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: profitColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
