import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/categories/models/category_model.dart';

class CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryTile({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.category,
            color: AppColors.primaryContainer,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.inventory_2,
                size: 14, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            FutureBuilder<AggregateQuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('products')
                  .where('categoryId', isEqualTo: category.id)
                  .count()
                  .get(),
              builder: (context, snapshot) {
                final count = snapshot.data?.count ?? 0;
                return Text(
                  '$count product${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              _formatDate(category.createdAt),
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, color: AppColors.primaryContainer),
                title: Text('Edit'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text('Delete', style: TextStyle(color: AppColors.error)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
