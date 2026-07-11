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
                          color: isDark ? AppColors.textPrimary : const Color(0xFF475569)),
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
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
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
                                      color: isDark ? AppColors.textMuted : const Color(0xFF6B7280)),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(provider.selectedDate),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_down_rounded, size: 14,
                                      color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
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
                      gradient: LinearGradient(
                        colors: [AppColors.green, AppColors.green.withAlpha(180)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                    color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: Icon(Icons.clear_rounded, size: 16,
                              color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
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
                    borderSide: BorderSide(color: AppColors.green.withAlpha(100), width: 1),
                  ),
                ),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
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
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.green.withAlpha(20),
                                  AppColors.green.withAlpha(5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(Icons.inbox_rounded,
                                size: 32, color: AppColors.green.withAlpha(100)),
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
                              color: isDark ? AppColors.textMuted : const Color(0xFF6B7280),
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
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      children: [
                        ModernCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.green.withAlpha(12),
                              AppColors.green.withAlpha(4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: null,
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.green, AppColors.green.withAlpha(180)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
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
                                    color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
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
                                  color: AppColors.green,
                                  letterSpacing: -0.5,
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
    final first = items.first;
    final times = items.map((e) => DateFormat('h:mm a').format(e.dateAdded)).toList();

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      onTap: null,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.green.withAlpha(25), AppColors.green.withAlpha(8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_rounded, size: 18, color: AppColors.green),
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
                          color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                        )),
                    if (first.categoryName.isNotEmpty)
                      Text(first.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
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
                      color: AppColors.green,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '$totalQty unit${totalQty == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceLight : const Color(0xFFF8FAFC)).withAlpha(180),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 10, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    times.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$symbol${_formatAmount(first.unitPrice, decimals: 2)} each',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
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
