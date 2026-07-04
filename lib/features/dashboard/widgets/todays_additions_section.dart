import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/features/daily_additions/providers/daily_addition_provider.dart';

class TodaysAdditionsSection extends StatefulWidget {
  const TodaysAdditionsSection({super.key});

  @override
  State<TodaysAdditionsSection> createState() => _TodaysAdditionsSectionState();
}

class _TodaysAdditionsSectionState extends State<TodaysAdditionsSection> {
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
        final items = provider.todaysAdditions;
        final totalQty = items.fold(0, (s, i) => s + i.quantity);
        final totalValue = items.fold(0.0, (s, i) => s + i.totalPrice);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Additions",
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
                          subtitle: Text(
                              'Qty: ${item.quantity} — \$${item.totalPrice.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall),
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
                  'Total: $totalQty items — \$${totalValue.toStringAsFixed(2)}',
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
