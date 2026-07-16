import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/features/daily_additions/models/daily_addition_model.dart';
import 'package:smartstock/features/daily_additions/providers/daily_addition_provider.dart';
import 'package:smartstock/features/products/widgets/barcode_scanner_screen.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/products/screens/product_details_screen.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class DailyAdditionsScreen extends StatefulWidget {
  const DailyAdditionsScreen({super.key});

  @override
  State<DailyAdditionsScreen> createState() => _DailyAdditionsScreenState();
}

class _DailyAdditionsScreenState extends State<DailyAdditionsScreen> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<DailyAdditionProvider>()
          .loadAdditionsForDate(DateTime.now());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DailyAdditionProvider>().loadAdditionsForDate(DateTime.now());
    }
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
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldBg : AppColors.whiteSoft,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(6),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: 18,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  Consumer<DailyAdditionProvider>(
                    builder: (context, provider, _) {
                      return GestureDetector(
                        onTap: _pickDate,
                        child: Row(
                          children: [
                            Text(
                              'Addition History',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surface : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 11,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(provider.selectedDate),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_down_rounded, size: 14,
                                      color: AppColors.textMuted),
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
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: _handleBarcodeScan,
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(6),
                        fixedSize: const Size(32, 32),
                      ),
                      tooltip: 'Scan barcode',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search additions...',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: AppColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: Icon(Icons.clear_rounded, size: 16,
                              color: AppColors.textMuted),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.surface : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.primary.withAlpha(100), width: 1),
                  ),
                ),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Consumer<DailyAdditionProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.additions.isEmpty) {
                    return const Center(child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ));
                  }

                  final items = _filtered(provider.additions);

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(Icons.inbox_rounded,
                                size: 32, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No matches found'
                                : 'No additions on this date',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try a different search term'
                                : 'Add stock to see items here',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: isDark ? AppColors.textMuted.withAlpha(120) : const Color(0xFF9CA3AF),
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
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      itemCount: 1 + keys.length,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return ModernCard(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            color: Colors.white,
                            onTap: null,
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '$grandQty item${grandQty == 1 ? '' : 's'} · ${grouped.length} product${grouped.length == 1 ? '' : 's'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$currencySymbol${_formatAmount(grandTotal)}',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final name = keys[index - 1];
                        return _buildGroupCard(context, name, grouped[name]!, isDark, currencySymbol);
                      },
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
    final first = items.first;

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      onTap: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    if (first.categoryName.isNotEmpty)
                      Text(first.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AppColors.textMuted,
                          )),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$symbol${_formatAmount(totalPrice)}',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '$totalQty unit${totalQty == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final item in items) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF8FAFC)).withAlpha(180),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 10, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('h:mm a').format(item.dateAdded),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$symbol${_formatAmount(item.unitPrice, decimals: 2)} each',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (item.serialNumbers.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: item.serialNumbers.map((sn) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primary.withAlpha(30), width: 0.5),
                        ),
                        child: Text(
                          sn,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatAmount(double value, {int decimals = 0}) {
    final isNegative = value < 0;
    final abs = isNegative ? -value : value;
    final parts = abs.toStringAsFixed(decimals).split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
      count++;
    }
    final formatted = buffer.toString().split('').reversed.join();
    if (decimals > 0 && parts.length > 1) {
      return '${isNegative ? '-' : ''}$formatted.${parts[1]}';
    }
    return isNegative ? '-$formatted' : formatted;
  }
}
