import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/features/daily_additions/models/daily_addition_model.dart';
import 'package:smartstock/features/daily_additions/providers/daily_addition_provider.dart';
import 'package:smartstock/features/products/widgets/barcode_scanner_screen.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/products/screens/product_details_screen.dart';

class DailyAdditionsScreen extends StatefulWidget {
  const DailyAdditionsScreen({super.key});

  @override
  State<DailyAdditionsScreen> createState() => _DailyAdditionsScreenState();
}

class _DailyAdditionsScreenState extends State<DailyAdditionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<DailyAdditionProvider>()
          .loadAdditionsForDate(DateTime.now());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final provider = context.read<DailyAdditionProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      provider.setDate(picked);
    }
  }

  Future<void> _handleBarcodeScan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || code.isEmpty) return;
    if (!mounted) return;

    final provider = context.read<ProductProvider>();
    final result = await provider.findProductBySerialNumber(code);
    if (result == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No product found for "$code"')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(productId: result.$1.id),
      ),
    );
  }

  List<DailyAddition> _filtered(List<DailyAddition> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((item) {
      final name = item.productName.toLowerCase();
      final cat = item.categoryName.toLowerCase();
      return name.contains(q) || cat.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = '\$';

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldBg : AppColors.whiteSoft,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.glassBg : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF475569)),
                    ),
                  ),
                  Consumer<DailyAdditionProvider>(
                    builder: (context, provider, _) {
                      final today = DateTime.now();
                      final sel = provider.selectedDate;
                      final isToday = sel.year == today.year &&
                          sel.month == today.month &&
                          sel.day == today.day;
                      return GestureDetector(
                        onTap: _pickDate,
                        child: Row(
                          children: [
                            Text(
                              isToday ? "Today's Additions" : 'Additions',
                              style: AppTextStyles.headlineMd.copyWith(
                                color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.glassBg : AppColors.glassBgDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(provider.selectedDate),
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down, size: 16,
                                      color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.greenBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _handleBarcodeScan,
                      icon: const Icon(Icons.qr_code_scanner, color: AppColors.green),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      tooltip: 'Scan barcode',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search additions...',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                    color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: Icon(Icons.clear_rounded, size: 18,
                              color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.surface : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.green.withAlpha(80), width: 1),
                  ),
                ),
                style: AppTextStyles.bodyMd.copyWith(
                  color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            Expanded(
              child: Consumer<DailyAdditionProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.additions.isEmpty) {
                    return const Center(child: CircularProgressIndicator(
                      color: AppColors.green,
                    ));
                  }

                  final items = _filtered(provider.additions);

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 56, color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB)),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No matches found'
                                : 'No additions on this date',
                            style: AppTextStyles.titleSm.copyWith(
                              color: isDark ? AppColors.textMuted : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final grouped = <String, List<DailyAddition>>{};
                  for (final item in items) {
                    grouped.putIfAbsent(item.productName, () => []).add(item);
                  }
                  final keys = grouped.keys.toList()..sort();
                  final grandTotal = items.fold(0.0, (sum, e) => sum + e.totalPrice);
                  final grandQty = items.fold(0, (sum, e) => sum + e.quantity);

                  return RefreshIndicator(
                    onRefresh: () async =>
                        provider.loadAdditionsForDate(provider.selectedDate),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        ModernCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onTap: null,
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long, size: 20, color: AppColors.green),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '$grandQty item${grandQty == 1 ? '' : 's'} · ${grouped.length} product${grouped.length == 1 ? '' : 's'}',
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              Text(
                                '$currencySymbol${grandTotal.toStringAsFixed(2)}',
                                style: AppTextStyles.amountSm.copyWith(
                                  color: AppColors.green,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final name in keys) ...[
                          _buildGroupCard(context, name, grouped[name]!, isDark, currencySymbol),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(
      BuildContext context, String name, List<DailyAddition> items, bool isDark, String symbol) {
    final totalQty = items.fold(0, (sum, e) => sum + e.quantity);
    final totalPrice = items.fold(0.0, (sum, e) => sum + e.totalPrice);
    final unitPrice = items.isNotEmpty ? (totalPrice / totalQty) : 0.0;
    final first = items.first;
    final times = items.map((e) => DateFormat('h:mm a').format(e.dateAdded)).toList();

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2, size: 20, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTextStyles.titleSm.copyWith(
                          color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                        )),
                    if (first.categoryName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(first.categoryName,
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                            )),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: $totalQty × $symbol${unitPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySm.copyWith(
                        color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (times.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Added at: ${times.join(', ')}',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                            fontSize: 10,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Added at: ${times.first}',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$symbol${totalPrice.toStringAsFixed(2)}',
                    style: AppTextStyles.amountSm.copyWith(color: AppColors.green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalQty unit${totalQty == 1 ? '' : 's'}',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
