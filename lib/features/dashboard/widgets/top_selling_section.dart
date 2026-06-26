import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/dashboard/models/dashboard_stats_model.dart';

class TopSellingSection extends StatelessWidget {
  final List<TopSellingProduct> topSelling;

  const TopSellingSection({super.key, required this.topSelling});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Selling',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            Debounced(
              onPressed: () {},
              builder: (_, isDisabled) => TextButton(
                onPressed: isDisabled ? null : () {},
                child: const Text('View All'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (topSelling.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No sales data yet',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topSelling.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = topSelling[index];
                return _TopSellingCard(
                  rank: index + 1,
                  product: product,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TopSellingCard extends StatelessWidget {
  final int rank;
  final TopSellingProduct product;

  const _TopSellingCard({
    required this.rank,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: rank <= 3
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: rank <= 3
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${product.totalSold} sold',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
placeholder: (_, _) => Container(
    color: AppColors.surfaceContainerHighest),
errorWidget: (_, _, _) => Container(
    color: AppColors.surfaceContainerHighest,
    child: const Icon(Icons.image, size: 20)),
                          )
                        : Container(
                            width: 40,
                            height: 40,
                            color: AppColors.surfaceContainerHighest,
                            child: const Icon(Icons.image, size: 20),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.productName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.modelNumber,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
