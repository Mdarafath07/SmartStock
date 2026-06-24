import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/features/customers/providers/customer_provider.dart';
import 'package:smartstock/features/customers/screens/customer_details_screen.dart';
import 'package:smartstock/features/customers/widgets/customer_tile.dart';

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
    final theme = Theme.of(context);
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
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
                onChanged: (query) {
                  customerProvider.loadCustomers(searchQuery: query);
                },
              )
            : const Text('Customers'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
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
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('No customers found',
                        style: theme.textTheme.bodyLarge),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return CustomerTile(
                    customer: customer,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerDetailsScreen(
                              customerId: customer.id),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
