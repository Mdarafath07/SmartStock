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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setToday());
  }

  void _setToday() {
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _startDate = _selectedDay;
    _endDate = _selectedDay!.add(const Duration(days: 1));
    _load();
  }

  void _setYesterday() {
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day - 1);
    _startDate = _selectedDay;
    _endDate = _selectedDay!.add(const Duration(days: 1));
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final saleProvider = context.watch<SaleProvider>();
    final sales = saleProvider.salesHistory;

    final totalSales = sales.length;
    final totalRevenue = sales.fold(0.0, (s, e) => s + e.salePrice);
    final totalProfit = sales.fold(0.0, (s, e) => s + e.profit);

    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: symbol);
    final dateFormat = DateFormat('MMM dd, yyyy');

    final grouped = <String, List<Sale>>{};
    for (final sale in sales) {
      final key = sale.customerName.isNotEmpty
          ? sale.customerName
          : 'Unknown Customer';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(sale);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldBg : AppColors.whiteSoft,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Sales History',
                style: AppTextStyles.headlineMd.copyWith(
                  color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            _buildDateBar(isDark, dateFormat),
            if (sales.isNotEmpty)
              _buildSummaryCards(isDark, currencyFormat, totalSales, totalRevenue, totalProfit),
            const SizedBox(height: 4),
            Expanded(
              child: sales.isEmpty
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

  Widget _buildDateBar(bool isDark, DateFormat dateFormat) {
    final label = _selectedDay != null
        ? dateFormat.format(_selectedDay!)
        : 'Select date';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _dateChip(isDark, 'Today', _setToday,
                _selectedDay == DateTime(DateTime.now().year,
                    DateTime.now().month, DateTime.now().day)),
            const SizedBox(width: 6),
            _dateChip(isDark, 'Yesterday', _setYesterday, false),
            const SizedBox(width: 6),
            _dateChip(isDark, 'This Week', _setThisWeek, false),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.greenBg
              : (isDark ? AppColors.surface : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.green.withAlpha(60)
                : (isDark ? AppColors.greyDarker.withAlpha(40) : const Color(0xFFE5E7EB)),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isActive ? AppColors.green : (isDark ? AppColors.textSecondary : const Color(0xFF6B7280)),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark, NumberFormat currencyFormat,
      int totalSales, double totalRevenue, double totalProfit) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Sales',
              value: '$totalSales',
              icon: Icons.shopping_bag_rounded,
              iconColor: AppColors.info,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              label: 'Revenue',
              value: currencyFormat.format(totalRevenue),
              icon: Icons.monetization_on_rounded,
              iconColor: AppColors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              label: 'Profit',
              value: currencyFormat.format(totalProfit),
              icon: Icons.trending_up_rounded,
              iconColor: totalProfit >= 0 ? AppColors.green : AppColors.red,
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
      margin: const EdgeInsets.only(top: 10),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceLight : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.greenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      customerName.isNotEmpty
                          ? customerName[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.titleSm.copyWith(color: AppColors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName,
                          style: AppTextStyles.titleSm.copyWith(
                            color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                          )),
                      if (sales.isNotEmpty && sales.first.customerPhone.isNotEmpty)
                        Text(sales.first.customerPhone,
                            style: AppTextStyles.caption.copyWith(
                              color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                            )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.greenBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${sales.length} item${sales.length > 1 ? 's' : ''}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currencyFormat.format(customerTotal),
                  style: AppTextStyles.amountSm.copyWith(color: AppColors.green),
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
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: sale.profit >= 0
                              ? AppColors.green
                              : AppColors.red,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(sale.productName,
                                      style: AppTextStyles.titleSm.copyWith(
                                        color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                                      )),
                                ),
                                if (sale.isReplacement)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: StatusBadge(label: 'Replacement', color: AppColors.orange, fontSize: 9),
                                  )
                                else if (sale.isWarrantyClaim)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: StatusBadge(label: 'Warranty', color: AppColors.info, fontSize: 9),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Debounced(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: sale.serialNumber));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Serial number copied')),
                                );
                              },
                              builder: (context, isDisabled) => GestureDetector(
                                onTap: isDisabled ? null : () {
                                  Clipboard.setData(ClipboardData(text: sale.serialNumber));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Serial number copied')),
                                  );
                                },
                                child: Text('${sale.modelNumber} | S/N: ${sale.serialNumber}',
                                  style: AppTextStyles.bodySm.copyWith(
                                      color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280)),
                              ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeFormat.format(sale.saleDate),
                        style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currencyFormat.format(sale.salePrice),
                        style: AppTextStyles.titleSm.copyWith(
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
