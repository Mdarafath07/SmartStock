import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/features/customers/models/customer_model.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;

  const CustomerTile({super.key, required this.customer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = context.watch<SettingsProvider>().currencySymbol;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            customer.name.isNotEmpty
                ? customer.name[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          customer.phone,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${customer.totalOrders} orders',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$symbol${customer.lifetimeValue.toStringAsFixed(0)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
