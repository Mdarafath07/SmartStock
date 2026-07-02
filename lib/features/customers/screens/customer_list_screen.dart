import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/features/customers/providers/customer_provider.dart';
import 'package:smartstock/features/customers/screens/customer_details_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    color: isDark
                        ? AppColors.textPrimary
                        : const Color(0xFF1A1A2E)),
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
                              color: isDark
                                  ? AppColors.primary
                                      .withAlpha(25)
                                  : AppColors.green
                                      .withAlpha(20),
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
                                '\$${customer.lifetimeValue.toStringAsFixed(0)}',
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
}
