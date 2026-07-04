import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/inventory/models/inventory_model.dart';
import 'package:smartstock/features/inventory/providers/inventory_provider.dart';
import 'package:smartstock/features/inventory/screens/stock_details_screen.dart';
import 'package:smartstock/features/products/widgets/barcode_scanner_screen.dart';

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
      context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || code.isEmpty) return;
    if (!mounted) return;
    final provider = context.read<InventoryProvider>();
    final productId = await provider.findProductIdBySerial(code);
    if (productId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No product found for "$code"')));
      return;
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => StockDetailsScreen(productId: productId)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inventoryProvider = context.watch<InventoryProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final filtered = _filteredItems(inventoryProvider.items);

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 8),
          _buildAppBar(isDark),
          _buildSearchBar(isDark),
          const SizedBox(height: 4),
          _buildSummaryRow(inventoryProvider, isDark),
          const SizedBox(height: 8),
          _buildFilters(inventoryProvider, categoryProvider, isDark),
          const SizedBox(height: 8),
          Expanded(child: _buildContent(inventoryProvider, filtered, isDark)),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('${filtered.length} result(s)',
                  style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text('Inventory', style: AppTextStyles.headlineMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(80), width: 0.5),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search inventory...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                          icon: Icon(Icons.clear_rounded, size: 18, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)))
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              onPressed: _handleBarcodeScan,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(InventoryProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _SumChip(label: 'Total', value: '${provider.totalProducts}', color: AppColors.blue, isDark: isDark),
          const SizedBox(width: 6),
          _SumChip(label: 'Available', value: '${provider.totalAvailable}', color: AppColors.green, isDark: isDark),
          const SizedBox(width: 6),
          _SumChip(label: 'Low', value: '${provider.lowStockCount}', color: AppColors.orange, isDark: isDark),
          const SizedBox(width: 6),
          _SumChip(label: 'Out', value: '${provider.outOfStockCount}', color: AppColors.red, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildFilters(InventoryProvider provider, CategoryProvider categoryProvider, bool isDark) {
    final categories = categoryProvider.categories;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterBtn(
            label: 'All',
            selected: provider.filter.categoryId == null && provider.filter.stockStatus == null,
            isDark: isDark,
            onTap: () => provider.clearFilters(),
          ),
          const SizedBox(width: 6),
          _FilterBtn(
            label: 'In Stock',
            selected: provider.filter.stockStatus == 'in_stock',
            isDark: isDark,
            onTap: () => provider.setStockStatusFilter('in_stock'),
          ),
          const SizedBox(width: 6),
          _FilterBtn(
            label: 'Low Stock',
            selected: provider.filter.stockStatus == 'low_stock',
            isDark: isDark,
            onTap: () => provider.setStockStatusFilter('low_stock'),
          ),
          const SizedBox(width: 6),
          _FilterBtn(
            label: 'Out of Stock',
            selected: provider.filter.stockStatus == 'out_of_stock',
            isDark: isDark,
            onTap: () => provider.setStockStatusFilter('out_of_stock'),
          ),
          const SizedBox(width: 6),
          ...categories.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _FilterBtn(
              label: cat.name,
              selected: provider.filter.categoryId == cat.id,
              isDark: isDark,
              onTap: () => provider.setCategoryFilter(cat.id),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildContent(InventoryProvider provider, List<InventoryItem> items, bool isDark) {
    if (provider.isLoading && provider.items.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 8,
        itemBuilder: (_, _) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 60,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.shimmerBase : const Color(0xFFE5E7EB)).withAlpha(150),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    if (provider.error != null && provider.items.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.error)),
          const SizedBox(height: 16),
          Text(provider.error!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: () => provider.loadInventory(), icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
        ],
      ));
    }
    if (items.isEmpty) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(
            color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200), borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.inventory_2_rounded, size: 36, color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB))),
          const SizedBox(height: 16),
          Text('No inventory items', style: AppTextStyles.headlineSm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
        ],
      ));
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadInventory(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _InventoryRow(item: item, isDark: isDark, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => StockDetailsScreen(productId: item.productId)));
          });
        },
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
}

class _SumChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _SumChip({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.labelMd.copyWith(color: color, fontWeight: FontWeight.w700)),
            Text(label, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _FilterBtn({required this.label, required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(20) : (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(180),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary.withAlpha(80) : (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60), width: 0.5),
        ),
        child: Text(label, style: AppTextStyles.labelSm.copyWith(color: selected ? AppColors.primary : (isDark ? AppColors.textSecondary : const Color(0xFF6B7280)))),
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final InventoryItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _InventoryRow({required this.item, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(item.stockStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.cardDark : Colors.white).withAlpha(200),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200), borderRadius: BorderRadius.circular(10)),
              child: item.imageUrl.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(item.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(Icons.inventory_2_rounded, size: 22, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))))
                  : Icon(Icons.inventory_2_rounded, size: 22, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      Text(item.modelNumber, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.purpleBg, borderRadius: BorderRadius.circular(4)),
                        child: Text(item.categoryName, style: const TextStyle(fontFamily: 'Geist', fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.purple)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.greenBg, borderRadius: BorderRadius.circular(4)),
                      child: Text('${item.availableStock}', style: AppTextStyles.labelSm.copyWith(color: AppColors.green, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.blueBg, borderRadius: BorderRadius.circular(4)),
                      child: Text('${item.soldStock}', style: AppTextStyles.labelSm.copyWith(color: AppColors.blue, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                  child: Text(_formatStatus(item.stockStatus), style: TextStyle(fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_stock': return AppColors.green;
      case 'low_stock': return AppColors.orange;
      case 'out_of_stock': return AppColors.red;
      case 'overstock': return AppColors.blue;
      default: return AppColors.grey;
    }
  }

  String _formatStatus(String status) {
    return status.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
