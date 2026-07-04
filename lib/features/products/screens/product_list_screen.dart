import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/products/models/product_model.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/products/screens/product_details_screen.dart';
import 'package:smartstock/features/products/widgets/barcode_scanner_screen.dart';
import 'package:smartstock/features/products/widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _sortNewestFirst = true;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    context
        .read<ProductProvider>()
        .loadProducts(categoryId: _selectedCategoryId);
  }

  void _onCategoryFilter(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    context
        .read<ProductProvider>()
        .loadProducts(categoryId: categoryId);
  }

  Future<void> _handleBarcodeScan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || code.isEmpty) return;
    if (!mounted) return;

    final provider = context.read<ProductProvider>();
    final result = await provider.findProductBySerialNumber(code);
    if (result == null) {
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
        builder: (_) => ProductDetailsScreen(productId: result.$1.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final products = productProvider.products;
    final sorted = List<Product>.from(products)
      ..sort((a, b) {
        final da = a.createdAt;
        final db = b.createdAt;
        return _sortNewestFirst ? db.compareTo(da) : da.compareTo(db);
      });

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 8),
          _buildAppBar(context, isDark),
          _buildSearchBar(isDark),
          const SizedBox(height: 4),
          _buildFilterRow(categoryProvider, isDark),
          const SizedBox(height: 4),
          _buildStatsRow(sorted, isDark),
          const SizedBox(height: 8),
          Expanded(
            child: _buildContent(sorted, productProvider, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Text(
            'Products',
            style: AppTextStyles.headlineMd.copyWith(
              color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(),
          _IconBtn(
            icon: Icons.category_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.categories),
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          _IconBtn(
            icon: Icons.warehouse_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          _IconBtn(
            icon: _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            onTap: () => setState(() => _isGridView = !_isGridView),
            isDark: isDark,
          ),
        ],
      ),
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
                border: Border.all(
                  color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(80),
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () { _searchController.clear(); _onSearch(''); },
                          icon: Icon(Icons.clear_rounded, size: 18, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                        )
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _handleBarcodeScan,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(CategoryProvider categoryProvider, bool isDark) {
    final categories = categoryProvider.categories;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        children: [
          _FilterChip(
            label: 'All',
            selected: _selectedCategoryId == null,
            onTap: () => _onCategoryFilter(null),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: cat.name,
                selected: _selectedCategoryId == cat.id,
                onTap: () => _onCategoryFilter(cat.id),
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: _sortNewestFirst ? 'Newest' : 'Oldest',
            selected: false,
            icon: _sortNewestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            onTap: () => setState(() => _sortNewestFirst = !_sortNewestFirst),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<Product> products, bool isDark) {
    final inStock = products.where((p) => p.availableQuantity > 5).length;
    final lowStock = products.where((p) => p.availableQuantity > 0 && p.availableQuantity <= 5).length;
    final outOfStock = products.where((p) => p.availableQuantity <= 0).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _MiniStat(label: 'Total', value: '${products.length}', color: AppColors.blue, isDark: isDark),
          const SizedBox(width: 8),
          _MiniStat(label: 'In Stock', value: '$inStock', color: AppColors.green, isDark: isDark),
          const SizedBox(width: 8),
          _MiniStat(label: 'Low', value: '$lowStock', color: AppColors.orange, isDark: isDark),
          const SizedBox(width: 8),
          _MiniStat(label: 'Out', value: '$outOfStock', color: AppColors.red, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildContent(List<Product> products, ProductProvider productProvider, bool isDark) {
    if (productProvider.isLoading && products.isEmpty) {
      return _buildSkeleton(isDark);
    }

    if (productProvider.error != null && products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text(productProvider.error!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => productProvider.loadProducts(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200), borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.inventory_2_rounded, size: 36, color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB)),
            ),
            const SizedBox(height: 16),
            Text('No products found', style: AppTextStyles.headlineSm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Text("Tap + to add your first product", style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => productProvider.loadProducts(categoryId: _selectedCategoryId),
      child: _isGridView
          ? GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: products[index],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: products[index].id))).then((_) {
                    if (!context.mounted) return;
                    context.read<ProductProvider>().loadProducts();
                  }),
                  isGrid: true,
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: products[index],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: products[index].id))).then((_) {
                    if (!context.mounted) return;
                    context.read<ProductProvider>().loadProducts();
                  }),
                  isGrid: false,
                );
              },
            ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: (isDark ? AppColors.shimmerBase : const Color(0xFFE5E7EB)).withAlpha(150),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _IconBtn({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({required this.label, required this.selected, this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(20)
              : (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(180),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary.withAlpha(80)
                : (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(80),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? AppColors.primary : (isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: selected ? AppColors.primary : (isDark ? AppColors.textSecondary : const Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MiniStat({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(8),
        ),
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
