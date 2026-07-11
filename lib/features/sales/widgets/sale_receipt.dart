import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class ReceiptItem {
  final String productName;
  final String modelNumber;
  final String serialNumber;
  final double price;
  final int warrantyMonths;
  final DateTime warrantyExpiry;
  final DateTime saleDate;

  const ReceiptItem({
    required this.productName,
    required this.modelNumber,
    required this.serialNumber,
    required this.price,
    this.warrantyMonths = 0,
    required this.warrantyExpiry,
    required this.saleDate,
  });
}

void showSaleReceipt(BuildContext context, {
  required String customerName,
  required String customerPhone,
  required List<ReceiptItem> items,
  required VoidCallback onDone,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final settings = context.read<SettingsProvider>();
  final symbol = settings.currencySymbol;
  final storeName = settings.storeName;
  final dateStr = DateFormat('MMM dd, yyyy').format(items.first.saleDate);
  final timeStr = DateFormat('hh:mm a').format(items.first.saleDate);
  final total = items.fold(0.0, (s, i) => s + i.price);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  _ReceiptHeader(storeName: storeName, dateStr: dateStr, timeStr: timeStr, isDark: isDark),
                  const SizedBox(height: 14),
                  _ReceiptDivider(isDark: isDark),
                  const SizedBox(height: 12),
                  _CustomerSection(customerName: customerName, customerPhone: customerPhone, isDark: isDark),
                  const SizedBox(height: 12),
                  _ReceiptDivider(isDark: isDark),
                  const SizedBox(height: 8),
                  _ItemsSection(items: items, symbol: symbol, isDark: isDark),
                  const SizedBox(height: 12),
                  _ReceiptDivider(isDark: isDark),
                  const SizedBox(height: 10),
                  _TotalSection(total: total, symbol: symbol, isDark: isDark),
                  const SizedBox(height: 8),
                  _WarrantySection(items: items, isDark: isDark),
                  const SizedBox(height: 12),
                  Text('Thank you for your purchase!', style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF), fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).padding.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { Navigator.pop(ctx); onDone(); },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Done'),
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

class _ReceiptHeader extends StatelessWidget {
  final String storeName;
  final String dateStr;
  final String timeStr;
  final bool isDark;

  const _ReceiptHeader({required this.storeName, required this.dateStr, required this.timeStr, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.receipt_long_rounded, size: 24, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(storeName, style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 2),
        Text('INVOICE', style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF), letterSpacing: 3, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded, size: 12, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
            const SizedBox(width: 4),
            Text('$dateStr  $timeStr', style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
          ],
        ),
      ],
    );
  }
}

class _ReceiptDivider extends StatelessWidget {
  final bool isDark;
  const _ReceiptDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(30),
            (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(120),
            (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(30),
          ],
        ),
      ),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final bool isDark;

  const _CustomerSection({required this.customerName, required this.customerPhone, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceLight : const Color(0xFFF8FAFC)).withAlpha(200),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(50), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text(customerName.isNotEmpty ? customerName[0].toUpperCase() : '?', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customerName, style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                Text(customerPhone, style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
              ],
            ),
          ),
          Icon(Icons.person_outline_rounded, size: 18, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  final List<ReceiptItem> items;
  final String symbol;
  final bool isDark;

  const _ItemsSection({required this.items, required this.symbol, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('ITEMS', style: TextStyle(fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
        ),
        ...items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceLight : const Color(0xFFFAFAFA)).withAlpha(isDark ? 80 : 150),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text('${e.key + 1}', style: TextStyle(fontFamily: 'Geist', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                      Text(item.modelNumber, style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
                      Text('SN: ${item.serialNumber}', style: TextStyle(fontFamily: 'Geist', fontSize: 9, color: AppColors.primary)),
                      if (item.warrantyMonths > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 10, color: AppColors.orange),
                              const SizedBox(width: 3),
                              Text('${item.warrantyMonths}mo warranty (till ${DateFormat('MMM dd, yyyy').format(item.warrantyExpiry)})', style: TextStyle(fontFamily: 'Geist', fontSize: 9, color: AppColors.orange)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text('$symbol${item.price.toStringAsFixed(0)}', style: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TotalSection extends StatelessWidget {
  final double total;
  final String symbol;
  final bool isDark;

  const _TotalSection({required this.total, required this.symbol, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Total Amount', style: AppTextStyles.titleMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
        const Spacer(),
        Text('$symbol${total.toStringAsFixed(2)}', style: AppTextStyles.amountLg.copyWith(color: AppColors.primary, fontSize: 24)),
      ],
    );
  }
}

class _WarrantySection extends StatelessWidget {
  final List<ReceiptItem> items;
  final bool isDark;

  const _WarrantySection({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasWarranty = items.any((i) => i.warrantyMonths > 0);
    if (!hasWarranty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.orange.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.orange.withAlpha(30), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Items with warranty are covered. Keep this receipt for warranty claims.',
              style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }
}
