import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/dashboard/models/dashboard_stats_model.dart';
import 'package:smartstock/features/dashboard/providers/dashboard_provider.dart';

class DailyAddedProductsSection extends StatefulWidget {
  const DailyAddedProductsSection({super.key});

  @override
  State<DailyAddedProductsSection> createState() =>
      _DailyAddedProductsSectionState();
}

class _DailyAddedProductsSectionState extends State<DailyAddedProductsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDailyAddedProducts();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: context.read<DashboardProvider>().selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select date to view added products',
    );
    if (picked != null) {
      context.read<DashboardProvider>().setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final products = provider.dailyAddedProducts;
        final selectedDate = provider.selectedDate;
        final today = DateTime.now();
        final isToday = selectedDate.year == today.year &&
            selectedDate.month == today.month &&
            selectedDate.day == today.day;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isToday ? "Today's Additions" : 'Added Products',
                  style: AppTextStyles.titleMd.copyWith(
                    color: ColorConstants.onSurface,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    DateFormat('MMM dd, yyyy').format(selectedDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                isToday
                    ? 'Products added today (${products.length})'
                    : 'Products added on ${DateFormat('EEEE, MMMM dd, yyyy').format(selectedDate)} (${products.length})',
                style: AppTextStyles.labelMd.copyWith(
                  color: ColorConstants.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (provider.isDailyLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (products.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: ColorConstants.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No products added on this date',
                          style: AppTextStyles.bodyLg.copyWith(
                            color: ColorConstants.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...products.map((product) =>
                  _ProductAddedTile(product: product)),
          ],
        );
      },
    );
  }
}

class _ProductAddedTile extends StatelessWidget {
  final ProductSummary product;

  const _ProductAddedTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: ColorConstants.surfaceContainerHigh,
                        child: const Icon(Icons.image, size: 24,
                            color: ColorConstants.onSurfaceVariant),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: ColorConstants.surfaceContainerHigh,
                        child: const Icon(Icons.image, size: 24,
                            color: ColorConstants.onSurfaceVariant),
                      ),
                    )
                  : Container(
                      width: 52,
                      height: 52,
                      color: ColorConstants.surfaceContainerHigh,
                      child: const Icon(Icons.image, size: 24,
                          color: ColorConstants.onSurfaceVariant),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Model: ${product.modelNumber}',
                    style: AppTextStyles.labelMd.copyWith(
                      color: ColorConstants.onSurfaceVariant,
                    ),
                  ),
                  if (product.categoryName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorConstants.primaryFixed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.categoryName,
                            style: AppTextStyles.labelSm.copyWith(
                              color: ColorConstants.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stock: ${product.availableQuantity}',
                          style: AppTextStyles.labelSm.copyWith(
                            color: product.availableQuantity == 0
                                ? ColorConstants.error
                                : ColorConstants.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (product.createdAt != null)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(product.createdAt!),
                    style: AppTextStyles.labelSm.copyWith(
                      color: ColorConstants.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd').format(product.createdAt!),
                    style: AppTextStyles.labelSm.copyWith(
                      color: ColorConstants.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

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
        Text(
          title,
          style: AppTextStyles.titleMd.copyWith(
            color: ColorConstants.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No $title data available',
                  style: AppTextStyles.bodyLg.copyWith(
                    color: ColorConstants.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...products.map((product) => _RecentProductTile(
                product: product,
                showQuantity: showQuantity,
              )),
      ],
    );
  }
}

class _RecentProductTile extends StatelessWidget {
  final ProductSummary product;
  final bool showQuantity;

  const _RecentProductTile({required this.product, this.showQuantity = true});

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
                    color: ColorConstants.surfaceContainerHigh,
                    child: const Icon(Icons.image, size: 24),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: ColorConstants.surfaceContainerHigh,
                    child: const Icon(Icons.image, size: 24),
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  color: ColorConstants.surfaceContainerHigh,
                  child: const Icon(Icons.image, size: 24),
                ),
        ),
        title: Text(
          product.productName,
          style: AppTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w600,
            color: ColorConstants.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              product.modelNumber,
              style: AppTextStyles.labelMd.copyWith(
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
            if (product.categoryName.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.categoryName,
                  style: AppTextStyles.labelSm.copyWith(
                    color: ColorConstants.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: showQuantity
            ? Text(
                '${product.availableQuantity}',
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: product.availableQuantity == 0
                      ? ColorConstants.error
                      : ColorConstants.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sell_outlined,
                      color: ColorConstants.primaryContainer, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${product.soldCount}',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: product.soldCount == 0
                          ? ColorConstants.error
                          : ColorConstants.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
