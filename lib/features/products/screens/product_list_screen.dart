import 'dart:async';

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
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _sortNewestFirst = true;
  bool _isGridView = true;
  double? _minPrice;
  double? _maxPrice;
  bool _sortPriceAsc = true;
  bool get _priceFilterActive => _minPrice != null || _maxPrice != null;
  Product? _serialSearchedProduct;
  int? _productTypeFilter;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ProductProvider>().loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ProductProvider>().loadProducts();
    }
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _debounceSerialSearch(query);
  }

  void _debounceSerialSearch(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _serialSearchedProduct = null);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final result = await context.read<ProductProvider>().findProductBySerialNumber(query.trim());
      if (mounted) setState(() => _serialSearchedProduct = result?.$1);
    });
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

  void _showPriceFilter(BuildContext context, bool isDark) {
    final minController = TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? '');
    final maxController = TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');
    final symbol = context.read<SettingsProvider>().currencySymbol;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('Price Filter', style: AppTextStyles.headlineSm.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Set a price range to filter products', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minController,
                      decoration: InputDecoration(
                        labelText: 'Min Price',
                        prefixText: '$symbol ',
                        filled: true,
                        fillColor: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxController,
                      decoration: InputDecoration(
                        labelText: 'Max Price',
                        prefixText: '$symbol ',
                        filled: true,
                        fillColor: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_priceFilterActive)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() { _minPrice = null; _maxPrice = null; });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                  if (_priceFilterActive) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _minPrice = double.tryParse(minController.text);
                          _maxPrice = double.tryParse(maxController.text);
                          if (_minPrice != null && _maxPrice != null && _minPrice! > _maxPrice!) {
                            final t = _minPrice; _minPrice = _maxPrice; _maxPrice = t;
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Product> _filterByType(List<Product> products) {
    if (_productTypeFilter == null) return products;
    return products.where((p) => _productTypeFilter == 1 ? p.isSerialized : !p.isSerialized).toList();
  }

  List<Product> _filterByPrice(List<Product> products) {
    if (!_priceFilterActive) return products;
    return products.where((p) {
      if (_minPrice != null && p.sellingPrice < _minPrice!) return false;
      if (_maxPrice != null && p.sellingPrice > _maxPrice!) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final products = productProvider.products;
    final sorted = List<Product>.from(products)
      ..sort((a, b) {
        final cmp = a.sellingPrice.compareTo(b.sellingPrice);
        if (_sortPriceAsc) return -cmp;
        if (cmp != 0) return cmp;
        final da = a.createdAt;
        final db = b.createdAt;
        return _sortNewestFirst ? db.compareTo(da) : da.compareTo(db);
      });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => productProvider.loadProducts(categoryId: _selectedCategoryId),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 8)),
            SliverToBoxAdapter(child: _buildAppBar(context, isDark)),
            SliverToBoxAdapter(child: _buildSearchBar(isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverToBoxAdapter(child: _buildFilterRow(categoryProvider, isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverToBoxAdapter(child: _buildStatsRow(productProvider, isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverToBoxAdapter(child: _buildTypeFilter(isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverToBoxAdapter(child: _buildSortBar(isDark)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ..._buildContentSlivers(sorted, productProvider, isDark),
            if (productProvider.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
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
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Inventory', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
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
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () { _searchController.clear(); _onSearch(''); },
                          icon: Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textPrimary),
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
        ],
      ),
    );
  }

  Widget _buildSortBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _sortNewestFirst = !_sortNewestFirst),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_sortNewestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(_sortNewestFirst ? 'Newest' : 'Oldest', style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _sortPriceAsc = !_sortPriceAsc),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_sortPriceAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('Price ${_sortPriceAsc ? "↑" : "↓"}', style: AppTextStyles.labelSm.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showPriceFilter(context, isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _priceFilterActive ? AppColors.primary.withAlpha(20) : (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(8),
                border: _priceFilterActive ? Border.all(color: AppColors.primary.withAlpha(60), width: 0.5) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list_rounded, size: 14, color: _priceFilterActive ? AppColors.primary : (AppColors.textSecondary)),
                  const SizedBox(width: 4),
                  Text('Filter', style: AppTextStyles.labelSm.copyWith(color: _priceFilterActive ? AppColors.primary : (AppColors.textSecondary))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _isGridView = !_isGridView),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, size: 16, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ProductProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _MiniStat(label: 'Products', value: '${provider.totalProducts}', color: AppColors.primary, isDark: isDark),
          const SizedBox(width: 8),
          _MiniStat(label: 'Items', value: '${provider.totalItems}', color: AppColors.primary, isDark: isDark),
          const SizedBox(width: 8),
          _MiniStat(label: 'In Stock', value: '${provider.inStock}', color: AppColors.success, isDark: isDark),
          const SizedBox(width: 8),
          _MiniStat(label: 'Low', value: '${provider.lowStock}', color: AppColors.warning, isDark: isDark),
          const SizedBox(width: 8),
          _MiniStat(label: 'Out', value: '${provider.outOfStock}', color: AppColors.error, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'All Types',
            selected: _productTypeFilter == null,
            onTap: () => setState(() => _productTypeFilter = null),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Serialized',
            selected: _productTypeFilter == 1,
            onTap: () => setState(() => _productTypeFilter = _productTypeFilter == 1 ? null : 1),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Quantity',
            selected: _productTypeFilter == 2,
            onTap: () => setState(() => _productTypeFilter = _productTypeFilter == 2 ? null : 2),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  List<Product> _filterBySearch(List<Product> products) {
    if (_searchQuery.isEmpty) {
      _serialSearchedProduct = null;
      return products;
    }
    final q = _searchQuery.toLowerCase();
    final matched = products.where((p) =>
      p.productName.toLowerCase().contains(q) ||
      p.brandName.toLowerCase().contains(q) ||
      p.modelNumber.toLowerCase().contains(q)
    ).toList();
    final matchedIds = matched.map((p) => p.id).toSet();
    if (_serialSearchedProduct != null && !matchedIds.contains(_serialSearchedProduct!.id)) {
      matched.add(_serialSearchedProduct!);
    }
    return matched;
  }

  List<Widget> _buildContentSlivers(List<Product> products, ProductProvider productProvider, bool isDark) {
    products = _filterBySearch(products);
    products = _filterByType(products);
    products = _filterByPrice(products);

    if (productProvider.isLoading && products.isEmpty) {
      return [_buildSkeleton(isDark)];
    }

    if (productProvider.error != null && products.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: AppColors.statusOutOfStockBg, borderRadius: BorderRadius.circular(18)),
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
          ),
        ),
      ];
    }

    if (products.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200), borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.inventory_2_rounded, size: 36, color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB)),
                ),
                const SizedBox(height: 16),
                Text('No products found', style: AppTextStyles.headlineSm.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text("Tap + to add your first product", style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ];
    }

    if (_isGridView) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(
                product: products[index],
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: products[index].id))).then((_) {
                  if (!context.mounted) return;
                  context.read<ProductProvider>().loadProducts(categoryId: _selectedCategoryId);
                }),
                isGrid: true,
              ),
              childCount: products.length,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ProductCard(
              product: products[index],
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(productId: products[index].id))).then((_) {
                if (!context.mounted) return;
                context.read<ProductProvider>().loadProducts(categoryId: _selectedCategoryId);
              }),
              isGrid: false,
            ),
            childCount: products.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildSkeleton(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => Container(
            decoration: BoxDecoration(
              color: (isDark ? AppColors.shimmerBase : const Color(0xFFE5E7EB)).withAlpha(150),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          childCount: 6,
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AppTextStyles.labelMd.copyWith(color: color, fontWeight: FontWeight.w700)),
            ),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({required this.label, required this.selected, required this.onTap, required this.isDark});

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
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: selected ? AppColors.primary : (AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}


