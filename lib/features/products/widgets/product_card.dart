import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/products/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final bool isGrid;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onEdit,
    this.isGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isGrid) {
      return _buildGridCard(context, isDark);
    }
    return _buildListCard(context, isDark);
  }

  Widget _buildGridCard(BuildContext context, bool isDark) {
    final stockStatus = _getStockStatus();
    final stockColor = _getStockColor(stockStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? AppColors.cardDark : Colors.white).withAlpha(220),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(80),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 8),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                  child: _buildProductImage(context),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: stockColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: stockColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stockStatus,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: stockColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (product.categoryName.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.purpleBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.categoryName,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: AppTextStyles.titleSm.copyWith(
                      color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.modelNumber,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (product.brandName.isNotEmpty)
                    Text(
                      product.brandName,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${product.sellingPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.amountSm.copyWith(
                              color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Cost: \$${product.purchasePrice.toStringAsFixed(0)}',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (stockStatus == 'In Stock'
                                  ? AppColors.greenBg
                                  : stockStatus == 'Low Stock'
                                      ? AppColors.orangeBg
                                      : AppColors.redBg)
                              .withAlpha(180),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.availableQuantity}',
                          style: AppTextStyles.labelSm.copyWith(
                            color: stockColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, bool isDark) {
    final stockStatus = _getStockStatus();
    final stockColor = _getStockColor(stockStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.cardDark : Colors.white).withAlpha(200),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildProductImage(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.productName,
                    style: AppTextStyles.titleSm.copyWith(
                      color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        product.modelNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                        ),
                      ),
                      if (product.categoryName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.purpleBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.categoryName,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\$${product.sellingPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.titleSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: stockColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: stockColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$stockStatus · ${product.availableQuantity}',
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: stockColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    if (product.imageUrl.isEmpty) {
      return Center(
        child: Icon(
          Icons.inventory_2_rounded,
          size: 28,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.greyDarker
              : const Color(0xFFD1D5DB),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: product.imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textMuted.withAlpha(100),
          ),
        ),
      ),
      errorWidget: (_, _, _) => Center(
        child: Icon(Icons.inventory_2_rounded, size: 28, color: AppColors.textMuted.withAlpha(100)),
      ),
    );
  }

  String _getStockStatus() {
    final qty = product.availableQuantity;
    if (qty <= 0) return 'Out of Stock';
    if (qty <= 5) return 'Low Stock';
    return 'In Stock';
  }

  Color _getStockColor(String status) {
    switch (status) {
      case 'In Stock':
        return AppColors.green;
      case 'Low Stock':
        return AppColors.orange;
      case 'Out of Stock':
        return AppColors.red;
      default:
        return AppColors.grey;
    }
  }
}
