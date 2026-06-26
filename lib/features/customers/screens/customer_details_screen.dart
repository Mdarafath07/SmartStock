import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/customers/providers/customer_provider.dart';
import 'package:smartstock/features/customers/widgets/customer_info_card.dart';
import 'package:smartstock/features/customers/widgets/purchase_history_table.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomerDetails(widget.customerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerProvider = context.watch<CustomerProvider>();
    final customer = customerProvider.selectedCustomer;
    final purchases = customerProvider.purchaseHistory;

    if (customerProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Customer not found', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, customer),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomerInfoCard(customer: customer),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Purchase History',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            PurchaseHistoryTable(purchases: purchases),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final addressController = TextEditingController(text: customer.address);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          Debounced(
            onPressed: () => Navigator.of(ctx).pop(),
            builder: (_, isDisabled) => TextButton(
              onPressed: isDisabled ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ),
          Debounced(
            onPressed: () {
              final updated = customer.copyWith(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: addressController.text.trim(),
              );
              context
                  .read<CustomerProvider>()
                  .updateCustomer(updated);
              Navigator.of(ctx).pop();
            },
            builder: (context, isDisabled) => FilledButton(
              onPressed: isDisabled ? null : () {
                final updated = customer.copyWith(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                );
                context
                    .read<CustomerProvider>()
                    .updateCustomer(updated);
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
