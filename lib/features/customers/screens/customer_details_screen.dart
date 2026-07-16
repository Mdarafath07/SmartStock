import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceLighter : AppColors.whiteMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.error_outline, size: 32, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              Text('Customer not found', style: AppTextStyles.bodyMd),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text('Purchase History', style: AppTextStyles.titleSm),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceLighter : AppColors.whiteMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${purchases.length}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
              decoration: InputDecoration(
                labelText: 'Name',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceLighter
                    : AppColors.whiteSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceLighter
                    : AppColors.whiteSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceLighter
                    : AppColors.whiteSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
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
              onPressed: isDisabled
                  ? null
                  : () {
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
