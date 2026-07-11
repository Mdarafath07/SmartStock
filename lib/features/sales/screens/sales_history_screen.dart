import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/core/widgets/status_badge.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';
import 'package:smartstock/features/sales/providers/sale_provider.dart';
import 'package:smartstock/features/sales/screens/sale_details_screen.dart';
import 'package:smartstock/features/sales/widgets/sale_receipt.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _selectedDay;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _prevSerialSearch = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setToday());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setToday() {
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _startDate = _selectedDay;
    _endDate = _selectedDay!.add(const Duration(days: 1));
    _load();
  }

  void _setThisMonth() {
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, 1);
    _startDate = _selectedDay;
    _endDate = DateTime(now.year, now.month + 1, 1);
    _load();
  }

  void _setThisWeek() {
    final now = DateTime.now();
    final weekStart =
        now.subtract(Duration(days: now.weekday - 1));
    _selectedDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
    _startDate = _selectedDay;
    _endDate = _startDate!.add(const Duration(days: 7));
    _load();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      _selectedDay = picked;
      _startDate = picked;
      _endDate = picked.add(const Duration(days: 1));
      _load();
    }
  }

  void _load() {
    context.read<SaleProvider>().loadSalesHistory(
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    context.read<SaleProvider>().searchSaleBySerialNumber(query.length >= 4 ? query : '');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final saleProvider = context.watch<SaleProvider>();
    final sales = saleProvider.salesHistory;

    final searchedSales = saleProvider.searchedSales;

    if (_searchQuery.length >= 4 && searchedSales.isEmpty && _searchQuery != _prevSerialSearch) {
      _prevSerialSearch = _searchQuery;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<SaleProvider>().searchSaleBySerialNumber(_searchQuery),
      );
    } else if (_searchQuery.length < 4) {
      _prevSerialSearch = '';
    }

    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: symbol);
    final dateFormat = DateFormat('MMM dd, yyyy');

    final filteredSales = _searchQuery.isEmpty
        ? sales
        : sales.where((s) {
            final q = _searchQuery.toLowerCase();
            if (s.customerName.toLowerCase().contains(q)) return true;
            if (s.productName.toLowerCase().contains(q)) return true;
            if (s.serialNumber.toLowerCase().contains(q)) return true;
            if (s.customerPhone.contains(q)) return true;
            return false;
          }).toList();

    final grouped = <String, List<Sale>>{};
    if (_searchQuery.isNotEmpty && filteredSales.length < sales.length) {
      final matchedCustomerNames = filteredSales.map((s) => s.customerName).toSet();
      for (final sale in sales) {
        if (matchedCustomerNames.contains(sale.customerName)) {
          final key = sale.customerName.isNotEmpty ? sale.customerName : 'Unknown Customer';
          grouped.putIfAbsent(key, () => []);
          grouped[key]!.add(sale);
        }
      }
    } else {
      for (final sale in filteredSales) {
        final key = sale.customerName.isNotEmpty ? sale.customerName : 'Unknown Customer';
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(sale);
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldBg : AppColors.whiteSoft,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.glassBg : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF475569)),
                    ),
                  ),
                  Text(
                    'Sales History',
                    style: AppTextStyles.titleLg.copyWith(
                      color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
            _buildSearchBar(isDark),
            _buildDateBar(isDark, dateFormat),
            if (filteredSales.isNotEmpty)
              _buildSummaryCards(isDark, currencyFormat, filteredSales.length, filteredSales.fold(0.0, (s, e) => s + e.salePrice), filteredSales.fold(0.0, (s, e) => s + e.profit)),
            if (searchedSales.isNotEmpty) ...[
              _buildCustomerGroup(isDark, currencyFormat, searchedSales.first.customerName.isNotEmpty ? searchedSales.first.customerName : 'Unknown Customer', searchedSales, searchedSales.fold(0.0, (s, e) => s + e.salePrice)),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            Expanded(
              child: filteredSales.isEmpty && searchedSales.isEmpty
                  ? _buildEmptyState(isDark)
                  : RefreshIndicator(
                      onRefresh: () async => _load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: grouped.entries.length,
                        itemBuilder: (context, index) {
                          final entry =
                              grouped.entries.elementAt(index);
                          final customerSales = entry.value;
                          final customerTotal = customerSales
                              .fold(0.0, (s, e) => s + e.salePrice);
                          return _buildCustomerGroup(
                              isDark, currencyFormat,
                              entry.key, customerSales, customerTotal);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(80), width: 0.5),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Search by product, serial, or customer...',
            prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () { _searchController.clear(); _onSearch(''); },
                    icon: Icon(Icons.clear_rounded, size: 18, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
        ),
      ),
    );
  }

  Widget _buildDateBar(bool isDark, DateFormat dateFormat) {
    final label = _selectedDay != null
        ? dateFormat.format(_selectedDay!)
        : 'Select date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final thisMonthStart = DateTime(now.year, now.month, 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _dateChip(isDark, 'Today', _setToday, _selectedDay == today),
            const SizedBox(width: 6),
            _dateChip(isDark, 'This Week', _setThisWeek, _selectedDay == thisWeekStart),
            const SizedBox(width: 6),
            _dateChip(isDark, 'This Month', _setThisMonth, _selectedDay == thisMonthStart),
            const SizedBox(width: 6),
            ModernCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hasShadow: false,
              hasBorder: true,
              onTap: _pickDate,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month, size: 14,
                      color: isDark ? AppColors.textMuted : const Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Text(label,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(
      bool isDark, String label, VoidCallback onTap, bool isActive) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.greenBg
              : (isDark ? AppColors.surface : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.green.withAlpha(60)
                : (isDark ? AppColors.greyDarker.withAlpha(40) : const Color(0xFFE5E7EB)),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppColors.green : (isDark ? AppColors.textSecondary : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark, NumberFormat currencyFormat,
      int totalSales, double totalRevenue, double totalProfit) {
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _compactStatCard(
              label: 'Sales',
              value: '$totalSales',
              icon: Icons.shopping_bag_rounded,
              iconColor: AppColors.info,
              bg: cardBg,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _compactStatCard(
              label: 'Revenue',
              value: currencyFormat.format(totalRevenue),
              icon: Icons.monetization_on_rounded,
              iconColor: AppColors.green,
              bg: cardBg,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _compactStatCard(
              label: 'Profit',
              value: currencyFormat.format(totalProfit),
              icon: Icons.trending_up_rounded,
              iconColor: totalProfit >= 0 ? AppColors.green : AppColors.red,
              bg: cardBg,
            ),
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
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 13, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: -0.02,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded,
              size: 56, color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text('No sales found',
              style: AppTextStyles.titleSm.copyWith(
                color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
              )),
          const SizedBox(height: 4),
          Text('Select a date to view sales',
              style: AppTextStyles.bodySm.copyWith(
                color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
              )),
        ],
      ),
    );
  }

  Widget _buildCustomerGroup(bool isDark, NumberFormat currencyFormat,
      String customerName, List<Sale> sales, double customerTotal) {
    final timeFormat = DateFormat('hh:mm a');
    return ModernCard(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: EdgeInsets.zero,
      borderRadius: 12,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceLight : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.greenBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      customerName.isNotEmpty
                          ? customerName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                          )),
                      if (sales.isNotEmpty && sales.first.customerPhone.isNotEmpty)
                        Text(sales.first.customerPhone,
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 11,
                              color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                            )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.greenBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${sales.length} item${sales.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => showSaleReceipt(
                    context,
                    customerName: customerName,
                    customerPhone: sales.isNotEmpty ? sales.first.customerPhone : '',
                    items: sales.map((s) => ReceiptItem(
                      productName: s.productName,
                      modelNumber: s.modelNumber,
                      serialNumber: s.serialNumber,
                      price: s.salePrice,
                      warrantyMonths: s.warrantyExpiryDate.isAfter(DateTime.now()) ? s.warrantyExpiryDate.difference(s.saleDate).inDays ~/ 30 : 0,
                      warrantyExpiry: s.warrantyExpiryDate,
                      saleDate: s.saleDate,
                    )).toList(),
                    onDone: () {},
                  ),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(Icons.receipt_long_rounded, size: 15, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  currencyFormat.format(customerTotal),
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          ...sales.map((sale) => Debounced(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SaleDetailsScreen(saleId: sale.id)),
                ),
                builder: (context, isDisabled) => InkWell(
                  onTap: isDisabled ? null : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SaleDetailsScreen(saleId: sale.id)),
                  ),
                  child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 32,
                        decoration: BoxDecoration(
                          color: sale.profit >= 0
                              ? AppColors.green
                              : AppColors.red,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(sale.productName,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                                      )),
                                ),
                                if (sale.isReplacement)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: StatusBadge(label: 'Replacement', color: AppColors.orange, fontSize: 8),
                                  )
                                else if (sale.isWarrantyClaim)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: StatusBadge(label: 'Warranty', color: AppColors.info, fontSize: 8),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: sale.serialNumber));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Serial number copied')),
                                );
                              },
                              child: Text('${sale.modelNumber} | ${sale.serialNumber}',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 10,
                                  color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeFormat.format(sale.saleDate),
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 10,
                          color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currencyFormat.format(sale.salePrice),
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                )),
        ],
      ),
    );
  }
}
