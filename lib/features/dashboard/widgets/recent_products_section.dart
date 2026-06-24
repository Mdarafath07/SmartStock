import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/dashboard/models/dashboard_stats_model.dart';

class RecentProductsSection extends StatelessWidget {
  final String title;
  final List<ProductSummary> products;
  final bool showQuantity;

  const RecentProductsSection({
    super.key,
    required this.title,
    required this.products,
    this.showQuantity = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No $title data available',
                  style:
                      const TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ),
            ),
          )
        else
          ...products.map((product) =>
              _ProductListTile(product: product, showQuantity: showQuantity)),
      ],
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final ProductSummary product;
  final bool showQuantity;

  const _ProductListTile({required this.product, this.showQuantity = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
placeholder: (_, _) => Container(
    color: AppColors.surfaceContainerHighest,
    child: const Icon(Icons.image, size: 24)),
errorWidget: (_, _, _) => Container(
    color: AppColors.surfaceContainerHighest,
    child: const Icon(Icons.image, size: 24)),
                )
              : Container(
                  width: 48,
                  height: 48,
                  color: AppColors.surfaceContainerHighest,
                  child: const Icon(Icons.image, size: 24),
                ),
        ),
        title: Text(
          product.productName,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              product.modelNumber,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (product.categoryName.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.categoryName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: showQuantity
            ? Text(
                '${product.availableQuantity}',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: product.availableQuantity == 0
                      ? AppColors.statusOutOfStock
                      : AppColors.statusInStock,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sell_outlined,
                      color: AppColors.primaryContainer, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${product.soldCount}',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: product.soldCount == 0
                          ? AppColors.statusOutOfStock
                          : AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
