import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';

class PurchaseHistoryTable extends StatelessWidget {
  final List<Sale> purchases;

  const PurchaseHistoryTable({super.key, required this.purchases});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final priceFormatter = NumberFormat.currency(symbol: '\$');

    if (purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No purchases yet',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final sale = purchases[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(Icons.inventory_2,
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.productName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: sale.serialNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Serial number copied')),
                          );
                        },
                        child: Text(
                          'Model: ${sale.modelNumber} | S/N: ${sale.serialNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormatter.format(sale.saleDate),
                        style: theme.textTheme.labelSmall?.copyWith(
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (sale.isReplacement)
                      _badge('Replacement', Colors.orange)
                    else if (sale.isWarrantyClaim)
                      _badge('Warranty Claim', Colors.blue)
                    else
                      _buildWarrantyBadge(theme, sale),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildWarrantyBadge(ThemeData theme, Sale sale) {
    final isActive = sale.warrantyExpiryDate.isAfter(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'Warranty Active' : 'Expired',
        style: TextStyle(
          fontSize: 10,
          color: isActive ? Colors.green : Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
