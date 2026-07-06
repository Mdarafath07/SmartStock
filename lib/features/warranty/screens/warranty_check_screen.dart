import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/utils/date_utils.dart';
import 'package:smartstock/core/widgets/empty_state.dart';
import 'package:smartstock/core/widgets/error_widget.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/core/widgets/status_badge.dart';
import 'package:smartstock/features/warranty/models/warranty_model.dart';
import 'package:smartstock/features/warranty/providers/warranty_provider.dart';
import 'package:smartstock/features/warranty/widgets/warranty_search_bar.dart';

class WarrantyCheckScreen extends StatefulWidget {
  const WarrantyCheckScreen({super.key});

  @override
  State<WarrantyCheckScreen> createState() => _WarrantyCheckScreenState();
}

class _WarrantyCheckScreenState extends State<WarrantyCheckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarrantyProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldBg : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Consumer<WarrantyProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                _buildHeader(provider, isDark),
                _buildSearchSection(provider),
                _buildTabRow(provider, isDark),
                const SizedBox(height: 4),
                Expanded(child: _buildContent(provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(WarrantyProvider provider, bool isDark) {
    final activeCount =
        provider.warranties.where((w) => w.isActive).length;
    final expiredCount =
        provider.warranties.where((w) => !w.isActive).length;
    final totalCount = provider.warranties.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34, height: 34,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.glassBg : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF475569)),
                ),
              ),
              Expanded(
                child: Text(
                  'Warranty Check',
                  style: AppTextStyles.titleLg.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              Icon(
                Icons.verified_user_rounded,
                color: isDark ? AppColors.grey : AppColors.greyDark,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _compactStatCard(
                  label: 'Active',
                  value: '$activeCount',
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _compactStatCard(
                  label: 'Expired',
                  value: '$expiredCount',
                  icon: Icons.cancel_rounded,
                  iconColor: AppColors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _compactStatCard(
                  label: 'Total',
                  value: '$totalCount',
                  icon: Icons.inventory_2_rounded,
                  iconColor: AppColors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                )),
                Text(label, style: TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(WarrantyProvider provider) {
    return WarrantySearchBar(
      onSerialChanged: (value) => provider.search(value),
      onModelChanged: (value) => provider.search(value),
      onCategoryChanged: (value) => provider.search(value),
    );
  }

  Widget _buildTabRow(WarrantyProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            _tabChip(
                'All', provider.searchResults.isEmpty, () => provider.loadAll(), isDark),
            const SizedBox(width: 3),
            _tabChip(
                'Active', false, () => provider.loadActive(), isDark),
            const SizedBox(width: 3),
            _tabChip(
                'Expired', false, () => provider.loadExpired(), isDark),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.cardDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: isDark
                        ? AppColors.greyDarker.withAlpha(80)
                        : const Color(0xFFE5E7EB),
                    width: 0.5,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withAlpha(30)
                          : Colors.black.withAlpha(8),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMd.copyWith(
              color: isSelected
                  ? (isDark
                      ? AppColors.textPrimary
                      : const Color(0xFF1A1A2E))
                  : (isDark
                      ? AppColors.textMuted
                      : const Color(0xFF6B7280)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(WarrantyProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return AppErrorWidget(
        message: provider.error!,
        onRetry: () => provider.loadAll(),
      );
    }

    final warranties = provider.searchResults.isNotEmpty
        ? provider.searchResults
        : provider.warranties;

    if (warranties.isEmpty) {
      return EmptyState(
        icon: Icons.verified_user_rounded,
        title: 'No Warranties Found',
        subtitle: 'Warranties from sales will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAll(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: warranties.length,
        itemBuilder: (context, index) {
          final warranty = warranties[index];
          return _buildWarrantyItem(warranty);
        },
      ),
    );
  }

  Widget _buildWarrantyItem(Warranty warranty) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E);
    final textMuted =
        isDark ? AppColors.textMuted : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ModernCard(
        padding: const EdgeInsets.all(10),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.warrantyDetails,
            arguments: warranty.id,
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 40,
                height: 40,
                child: warranty.imageUrl.isNotEmpty
                    ? Image.network(
                        warranty.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _productPlaceholder(isDark),
                      )
                    : _productPlaceholder(isDark),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          warranty.productName,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge.warranty(warranty.isActive),
                    ],
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(
                          ClipboardData(text: warranty.serialNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Serial number copied')),
                      );
                    },
                    child: Text(
                      'S/N: ${warranty.serialNumber}',
                      style: AppTextStyles.caption.copyWith(
                        color: textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 10, color: textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          warranty.customerName,
                          style: AppTextStyles.caption.copyWith(
                            color: textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today_rounded,
                          size: 8, color: textMuted),
                      const SizedBox(width: 3),
                      Text(
                        AppDateUtils.formatDate(warranty.purchaseDate),
                        style: TextStyle(
                          fontSize: 9,
                          color: textMuted,
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

  Widget _productPlaceholder(bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        size: 20,
        color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB),
      ),
    );
  }
}
