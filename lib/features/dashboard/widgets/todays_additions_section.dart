import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/features/daily_additions/providers/daily_addition_provider.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class AdditionHistorySection extends StatefulWidget {
  const AdditionHistorySection({super.key});

  @override
  State<AdditionHistorySection> createState() => _AdditionHistorySectionState();
}

class _AdditionHistorySectionState extends State<AdditionHistorySection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyAdditionProvider>().loadTodaysAdditions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyAdditionProvider>(
      builder: (context, provider, _) {
        final symbol = context.watch<SettingsProvider>().currencySymbol;
        final items = provider.todaysAdditions;
        final totalQty = items.fold(0, (s, i) => s + i.quantity);
        final totalValue = items.fold(0.0, (s, i) => s + i.totalPrice);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Addition History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 4),
            if (provider.isTodaysLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_rounded,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('No additions today',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              )
            else
              Card(
                child: Column(
                  children: [
                    ...items.take(5).map((item) => ListTile(
                          title: Text(item.productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Qty: ${item.quantity} — $symbol${item.totalPrice.toStringAsFixed(0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (item.serialNumbers.isNotEmpty)
                                Text(
                                  item.serialNumbers.join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(
                            DateFormat('h:mm a').format(item.dateAdded),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          dense: true,
                        )),
                    if (items.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('+${items.length - 5} more items',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                )),
                      ),
                  ],
                ),
              ),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Total: $totalQty items — $symbol${totalValue.toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }
}
