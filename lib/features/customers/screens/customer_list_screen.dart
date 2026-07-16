import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/services/connectivity_service.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/features/customers/models/customer_model.dart';
import 'package:smartstock/features/customers/providers/customer_provider.dart';
import 'package:smartstock/features/customers/screens/customer_details_screen.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<CustomerProvider>().loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final customerProvider = context.watch<CustomerProvider>();
    final customers = customerProvider.customers;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  border: InputBorder.none,
                  hintStyle:
                      TextStyle(color: AppColors.textMuted),
                ),
                style: TextStyle(
                    color: AppColors.textPrimary),
                onChanged: (query) {
                  customerProvider.loadCustomers(searchQuery: query);
                },
              )
            : const Text('Customers'),
        actions: [
          IconButton(
            icon:
                Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  customerProvider.loadCustomers();
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context, customerProvider),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          customerProvider.loadCustomers();
        },
        child: customers.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                      height:
                          MediaQuery.of(context).size.height *
                              0.25),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceLighter
                                : AppColors.whiteMuted,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.people_outline,
                              size: 32,
                              color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No customers found',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 10),
                    child: ModernCard(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerDetailsScreen(
                                    customerId:
                                        customer.id),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                customer.name.isNotEmpty
                                    ? customer.name[0]
                                        .toUpperCase()
                                    : '?',
                                style: AppTextStyles.titleMd
                                    .copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer.name,
                                  style: AppTextStyles.titleSm
                                      .copyWith(
                                    color: isDark
                                        ? AppColors
                                            .textPrimary
                                        : const Color(
                                            0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  customer.phone,
                                  style: AppTextStyles.labelSm
                                      .copyWith(
                                    color:
                                        AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${customer.totalOrders} orders',
                                style: AppTextStyles.labelSm
                                    .copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$symbol${customer.lifetimeValue.toStringAsFixed(0)}',
                                style: AppTextStyles.caption
                                    .copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context, CustomerProvider provider) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        title: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_rounded, size: 20, color: AppColors.textMuted),
                ),
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_rounded, size: 20, color: AppColors.textMuted),
                ),
                keyboardType: TextInputType.phone,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_rounded, size: 20, color: AppColors.textMuted),
                ),
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          OutlinedButton(onPressed: isSubmitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final nav = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    final connectivity = context.read<ConnectivityService>();
                    if (!connectivity.canWrite()) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('No internet connection. Please connect to add customers.')),
                      );
                      return;
                    }
                    setDialogState(() => isSubmitting = true);
                    try {
                      await provider.addCustomer(Customer(
                        name: name,
                        phone: phoneController.text.trim(),
                        address: addressController.text.trim(),
                      ));
                      if (ctx.mounted) nav.pop();
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to add customer: $e')),
                      );
                    }
                  },
            child: isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Add'),
          ),
        ],
      ),
      ),
    );
  }
}
