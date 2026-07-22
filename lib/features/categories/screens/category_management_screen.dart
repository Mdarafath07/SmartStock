import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/categories/models/category_model.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/categories/screens/add_category_screen.dart';
import 'package:smartstock/features/categories/widgets/category_form_dialog.dart';
import 'package:smartstock/features/categories/widgets/category_tile.dart';
import 'package:smartstock/core/widgets/empty_state.dart' as es;
import 'package:smartstock/core/widgets/error_widget.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
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
      context.read<CategoryProvider>().loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF475569)),
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.category_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Categories',
                    style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.textPrimary)),
                Consumer<CategoryProvider>(
                  builder: (_, p, _) => Text(
                    '${p.categories.length} category${p.categories.length == 1 ? '' : 'ies'}',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded,
                  color: AppColors.primary),
              onPressed: () => _showAddCategory(context),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyLight, width: 0.5),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search categories...',
            hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: AppColors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded,
                        size: 18, color: AppColors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator(
              color: AppColors.primary));
        }
        if (provider.error != null && provider.categories.isEmpty) {
          return AppErrorWidget(
            message: provider.error!,
            onRetry: () => provider.loadCategories(),
          );
        }

        var categories = provider.categories.where((c) =>
            c.name.toLowerCase().contains(_searchQuery)).toList();

        if (categories.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return es.EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No categories found',
              subtitle: 'Try a different search term',
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.category_rounded,
                      size: 32, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text('No categories yet',
                    style: AppTextStyles.titleSm.copyWith(
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('Add your first category to get started',
                    style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textMuted)),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showAddCategory(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Category'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => provider.loadCategories(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryTile(
                category: category,
                index: index,
                onEdit: () => _showEditCategory(context, category),
                onDelete: () => _deleteCategory(context, provider, category),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddCategory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
    );
  }

  void _deleteCategory(BuildContext context, CategoryProvider provider, Category category) async {
    final count = await provider.getProductCount(category.id);
    if (count > 0) {
      _showSnackBar('Cannot delete "$category.name": $count product${count == 1 ? '' : 's'} linked');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Delete Category', style: AppTextStyles.titleSm.copyWith(color: AppColors.textPrimary)),
        ]),
        content: Text('Are you sure you want to delete "$category.name"?', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.textMuted))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: AppTextStyles.button),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.deleteCategory(category.id);
        if (context.mounted) _showSnackBar('"${category.name}" deleted');
      } catch (e) {
        if (context.mounted) _showSnackBar(e.toString());
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showEditCategory(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: AppColors.warning, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Edit Category',
                style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to rename "$category.name"?',
                style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All products in this category will be updated to the new name.',
                      style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.button.copyWith(
                    color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => CategoryFormDialog(
                  initialName: category.name,
                  initialIcon: category.icon,
                  initialId: category.id,
                  onSave: (name, icon) async {
                    await context.read<CategoryProvider>()
                        .updateCategory(category.id, name, icon: icon);
                  },
                ),
              );
            },
            child: Text('Continue', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }

}
