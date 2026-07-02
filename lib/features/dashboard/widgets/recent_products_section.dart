import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
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
    final provider = context.read<DashboardProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select date to view added products',
    );
    if (picked != null) {
      provider.setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    color: isDark ? AppColors.textPrimary : const Color(0xFF1B1B21),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMd.copyWith(
                  color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
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
                          color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No products added on this date',
                          style: AppTextStyles.bodyLg.copyWith(
                            color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                        color: isDark ? AppColors.surfaceLighter : const Color(0xFFEAE7EF),
                        child: const Icon(Icons.image, size: 24,
                            color: Color(0xFF454652)),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: isDark ? AppColors.surfaceLighter : const Color(0xFFEAE7EF),
                        child: const Icon(Icons.image, size: 24,
                            color: Color(0xFF454652)),
                      ),
                    )
                  : Container(
                      width: 52,
                      height: 52,
                      color: isDark ? AppColors.surfaceLighter : const Color(0xFFEAE7EF),
                      child: const Icon(Icons.image, size: 24,
                          color: Color(0xFF454652)),
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
                      color: isDark ? AppColors.textPrimary : const Color(0xFF1B1B21),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Model: ${product.modelNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMd.copyWith(
                      color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
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
                            color: AppColors.greenBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stock: ${product.availableQuantity}',
                          style: AppTextStyles.labelSm.copyWith(
                            color: product.availableQuantity == 0
                                ? AppColors.error
                                : isDark ? AppColors.textSecondary : const Color(0xFF454652),
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
                      color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd').format(product.createdAt!),
                    style: AppTextStyles.labelSm.copyWith(
                      color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMd.copyWith(
            color: isDark ? AppColors.textPrimary : const Color(0xFF1B1B21),
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
                    color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    color: isDark ? AppColors.surfaceLighter : const Color(0xFFEAE7EF),
                    child: const Icon(Icons.image, size: 24),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: isDark ? AppColors.surfaceLighter : const Color(0xFFEAE7EF),
                    child: const Icon(Icons.image, size: 24),
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  color: isDark ? AppColors.surfaceLighter : const Color(0xFFEAE7EF),
                  child: const Icon(Icons.image, size: 24),
                ),
        ),
        title: Text(
          product.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimary : const Color(0xFF1B1B21),
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              product.modelNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMd.copyWith(
                color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
              ),
            ),
            if (product.categoryName.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.categoryName,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
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
                      ? AppColors.error
                      : AppColors.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sell_outlined,
                      color: AppColors.primary.withAlpha(30), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${product.soldCount}',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: product.soldCount == 0
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
