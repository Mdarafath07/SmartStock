import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';
import 'package:smartstock/features/sales/providers/sale_provider.dart';
import 'package:smartstock/features/sales/screens/sale_details_screen.dart';

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
    final theme = Theme.of(context);
    final saleProvider = context.watch<SaleProvider>();
    final sales = saleProvider.salesHistory;

    final totalSales = sales.length;
    final totalRevenue = sales.fold(0.0, (s, e) => s + e.salePrice);
    final totalProfit = sales.fold(0.0, (s, e) => s + e.profit);

    final currencyFormat = NumberFormat.currency(symbol: '\$');
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
      appBar: AppBar(
        title: const Text('Sales History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildDateBar(theme, dateFormat),
          _buildSummaryCards(
              theme, currencyFormat, totalSales, totalRevenue, totalProfit),
          const Divider(height: 1),
          Expanded(
            child: sales.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
                    onRefresh: () async => _load(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                          top: 8, bottom: 24),
                      itemCount: grouped.entries.length,
                      itemBuilder: (context, index) {
                        final entry =
                            grouped.entries.elementAt(index);
                        final customerSales = entry.value;
                        final customerTotal = customerSales
                            .fold(0.0, (s, e) => s + e.salePrice);
                        return _buildCustomerGroup(
                            theme, currencyFormat,
                            entry.key, customerSales, customerTotal);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBar(ThemeData theme, DateFormat dateFormat) {
    final label = _selectedDay != null
        ? dateFormat.format(_selectedDay!)
        : 'Select date';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _dateChip(theme, 'Today', _setToday,
                _selectedDay == DateTime(DateTime.now().year,
                    DateTime.now().month, DateTime.now().day)),
            const SizedBox(width: 8),
            _dateChip(theme, 'Yesterday', _setYesterday, false),
            const SizedBox(width: 8),
            _dateChip(theme, 'This Week', _setThisWeek, false),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.calendar_month, size: 18),
              label: Text(label, style: const TextStyle(fontSize: 12)),
              onPressed: _pickDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(
      ThemeData theme, String label, VoidCallback onTap, bool isActive) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isActive,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildSummaryCards(ThemeData theme, NumberFormat currencyFormat,
      int totalSales, double totalRevenue, double totalProfit) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _summaryCard(theme, 'Sales', '$totalSales',
              Icons.shopping_bag, Colors.blue, Colors.blue.shade50),
          const SizedBox(width: 12),
          _summaryCard(theme, 'Revenue', currencyFormat.format(totalRevenue),
              Icons.monetization_on, Colors.green, Colors.green.shade50),
          const SizedBox(width: 12),
          _summaryCard(theme, 'Profit', currencyFormat.format(totalProfit),
              Icons.trending_up, totalProfit >= 0 ? Colors.green : Colors.red,
              (totalProfit >= 0 ? Colors.green : Colors.red).shade50),
        ],
      ),
    );
  }

  Widget _summaryCard(ThemeData theme, String label, String value,
      IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: color.withAlpha(180))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('No sales found',
              style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text('Select a date to view sales',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildCustomerGroup(ThemeData theme, NumberFormat currencyFormat,
      String customerName, List<Sale> sales, double customerTotal) {
    final timeFormat = DateFormat('hh:mm a');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withAlpha(120),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    customerName.isNotEmpty
                        ? customerName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (sales.isNotEmpty && sales.first.customerPhone.isNotEmpty)
                        Text(sales.first.customerPhone,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Text(
                  '${sales.length} item${sales.length > 1 ? 's' : ''}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Text(
                  currencyFormat.format(customerTotal),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...sales.map((sale) => InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SaleDetailsScreen(saleId: sale.id)),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: sale.profit >= 0
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sale.productName,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                            GestureDetector(
                              onLongPress: () {
                                Clipboard.setData(ClipboardData(text: sale.serialNumber));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Serial number copied')),
                                );
                              },
                              child: Text('${sale.modelNumber} | S/N: ${sale.serialNumber}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeFormat.format(sale.saleDate),
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currencyFormat.format(sale.salePrice),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
