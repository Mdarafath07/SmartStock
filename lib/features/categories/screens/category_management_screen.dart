import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/categories/models/category_model.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/categories/screens/add_category_screen.dart';
import 'package:smartstock/features/categories/widgets/category_form_dialog.dart';
import 'package:smartstock/features/categories/widgets/category_tile.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategory(context),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(provider.error!,
                      style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                  Debounced(
                    onPressed: () => provider.loadCategories(),
                    builder: (context, isDisabled) => FilledButton(
                      onPressed: isDisabled ? null : () => provider.loadCategories(),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            );
          }
          if (provider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category,
                      size: 64,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'No categories yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showAddCategory(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => provider.loadCategories(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                return CategoryTile(
                  category: category,
                  onEdit: () => _showEditCategory(context, category),
                  onDelete: () =>
                      _confirmDelete(context, category.id, category.name),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _showAddCategory(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCategoryScreen(),
      ),
    );
  }

  void _showEditCategory(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (_) => CategoryFormDialog(
        initialName: category.name,
        onSave: (name) {
          context.read<CategoryProvider>().updateCategory(category.id, name);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          Debounced(
            onPressed: () => Navigator.pop(context),
            builder: (_, isDisabled) => TextButton(
              onPressed: isDisabled ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          Debounced(
            onPressed: () {
              context.read<CategoryProvider>().deleteCategory(id);
              Navigator.pop(context);
            },
            builder: (context, isDisabled) => FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: isDisabled ? null : () {
                context.read<CategoryProvider>().deleteCategory(id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}
