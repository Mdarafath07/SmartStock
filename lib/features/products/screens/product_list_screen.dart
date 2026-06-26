import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/products/models/product_model.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/products/screens/add_product_screen.dart';
import 'package:smartstock/features/products/screens/product_details_screen.dart';
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

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 8),
          _buildFilterRow(categoryProvider),
          const SizedBox(height: 8),
          Expanded(
            child: _buildContent(sorted, productProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddProductScreen(),
          ),
        ).then((_) {
          if (!context.mounted) return;
          context.read<ProductProvider>().loadProducts();
        }),
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                  icon: const Icon(Icons.clear, color: AppColors.onSurfaceVariant),
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryContainer),
          ),
        ),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: AppColors.onSurface,
        ),
      ),
    );
  }

  Widget _buildFilterRow(CategoryProvider categoryProvider) {
    final categories = categoryProvider.categories;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        children: [
          _buildChip(
            label: 'All',
            selected: _selectedCategoryId == null,
            onTap: () => _onCategoryFilter(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                label: cat.name,
                selected: _selectedCategoryId == cat.id,
                onTap: () => _onCategoryFilter(cat.id),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildSortToggle(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortToggle() {
    return Material(
      color: Colors.transparent,
      child: Debounced(
        onPressed: () {
          setState(() => _sortNewestFirst = !_sortNewestFirst);
        },
        builder: (context, isDisabled) => InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isDisabled ? null : () {
            setState(() => _sortNewestFirst = !_sortNewestFirst);
          },
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _sortNewestFirst ? 'Newest' : 'Oldest',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Debounced(
      onPressed: onTap,
      builder: (context, isDisabled) => GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryContainer : AppColors.outline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildContent(
      List<Product> products, ProductProvider productProvider) {
    if (productProvider.isLoading && products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productProvider.error != null && products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 8),
            Text(
              productProvider.error!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Debounced(
              onPressed: () => productProvider.loadProducts(),
              builder: (context, isDisabled) => FilledButton(
                onPressed: isDisabled ? null : () => productProvider.loadProducts(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 48, color: AppColors.onSurfaceVariant),
            SizedBox(height: 8),
            Text(
              'No products found',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap + to add your first product',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          productProvider.loadProducts(categoryId: _selectedCategoryId),
      child: GridView.builder(
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProductDetailsScreen(productId: products[index].id),
              ),
            ).then((_) {
              if (!context.mounted) return;
              context.read<ProductProvider>().loadProducts();
            }),
          );
        },
      ),
    );
  }
}
