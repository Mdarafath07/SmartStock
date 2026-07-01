import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/inventory/models/inventory_model.dart';
import 'package:smartstock/features/inventory/providers/inventory_provider.dart';
import 'package:smartstock/features/inventory/screens/stock_details_screen.dart';
import 'package:smartstock/features/inventory/widgets/filter_bar.dart';
import 'package:smartstock/features/inventory/widgets/inventory_table.dart';
import 'package:smartstock/features/inventory/widgets/stock_summary_cards.dart';
import 'package:smartstock/features/products/widgets/barcode_scanner_screen.dart';
import 'package:smartstock/core/widgets/debounced.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventory();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeScan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || code.isEmpty) return;
    if (!mounted) return;

    final provider = context.read<InventoryProvider>();
    final productId = await provider.findProductIdBySerial(code);
    if (productId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No product found for "$code"')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockDetailsScreen(productId: productId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Inventory',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => inventoryProvider.loadInventory(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              StockSummaryCards(
                totalProducts: inventoryProvider.totalProducts,
                totalAvailable: inventoryProvider.totalAvailable,
                lowStockCount: inventoryProvider.lowStockCount,
                outOfStockCount: inventoryProvider.outOfStockCount,
              ),
              const SizedBox(height: 12),
              _buildSearchBar(),
              const SizedBox(height: 8),
              FilterBar(
                categories: categoryProvider.categories,
                selectedCategoryId: inventoryProvider.filter.categoryId,
                selectedStockStatus: inventoryProvider.filter.stockStatus,
                onCategoryChanged: (id) =>
                    inventoryProvider.setCategoryFilter(id),
                onStockStatusChanged: (status) =>
                    inventoryProvider.setStockStatusFilter(status),
                onClear: () => inventoryProvider.clearFilters(),
              ),
              const SizedBox(height: 12),
              _buildHeader(),
              if (inventoryProvider.isLoading && inventoryProvider.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (inventoryProvider.error != null &&
                  inventoryProvider.items.isEmpty)
                _buildError(inventoryProvider)
              else ...[
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: InventoryTable(
                    items: _filteredItems(inventoryProvider.items),
                    onItemTap: (item) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StockDetailsScreen(
                          productId: item.productId,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      '${_filteredItems(inventoryProvider.items).length} result(s)',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<InventoryItem> _filteredItems(List<InventoryItem> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((i) =>
        i.productName.toLowerCase().contains(q) ||
        i.modelNumber.toLowerCase().contains(q) ||
        i.categoryName.toLowerCase().contains(q)).toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.onSurfaceVariant),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear,
                            color: AppColors.onSurfaceVariant),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primaryContainer),
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _handleBarcodeScan,
            icon: const Icon(Icons.qr_code_scanner),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            tooltip: 'Scan barcode',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Text(
              'Product',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Available',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Sold',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(
            width: 80,
            child: Text(
              'Status',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(InventoryProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Debounced(
              onPressed: () => provider.loadInventory(),
              builder: (context, isDisabled) => FilledButton(
                onPressed: isDisabled ? null : () => provider.loadInventory(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
