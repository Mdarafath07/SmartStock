import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/utils/date_utils.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/warranty/models/warranty_model.dart';
import 'package:smartstock/features/warranty/widgets/warranty_status_badge.dart';

class WarrantyCard extends StatelessWidget {
  final Warranty warranty;
  final VoidCallback? onTap;

  const WarrantyCard({
    super.key,
    required this.warranty,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Debounced(
        onPressed: onTap,
        builder: (context, isDisabled) => InkWell(
          onTap: isDisabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (warranty.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: CachedNetworkImage(
                            imageUrl: warranty.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _productPlaceholder(context),
                            placeholder: (_, _) => _productPlaceholder(context),
                          ),
                        ),
                      )
                    else
                      _productPlaceholder(context),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warranty.productName,
                            style: AppTextStyles.titleMd.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Model: ${warranty.modelNumber}',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
                            ),
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onLongPress: () {
                              Clipboard.setData(ClipboardData(text: warranty.serialNumber));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Serial number copied')),
                              );
                            },
                            child: Text(
                              'S/N: ${warranty.serialNumber}',
                              style: AppTextStyles.labelMd.copyWith(
                                color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        warranty.customerName,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Purchased: ${AppDateUtils.formatDate(warranty.purchaseDate)}',
                      style: AppTextStyles.labelMd.copyWith(
                        color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
                      ),
                    ),
                    const Spacer(),
                    WarrantyStatusBadge(
                      isActive: warranty.isActive,
                      isClaimed: warranty.warrantyClaimed,
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _productPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFE4E1EA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
        size: 28,
      ),
    );
  }
}
