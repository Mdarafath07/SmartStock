import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/inventory/providers/inventory_provider.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class StockDetailsScreen extends StatefulWidget {
  final String productId;

  const StockDetailsScreen({super.key, required this.productId});

  @override
  State<StockDetailsScreen> createState() => _StockDetailsScreenState();
}

class _StockDetailsScreenState extends State<StockDetailsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  void _load() {
    context.read<InventoryProvider>().loadStockDetails(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final details = provider.selectedStockDetails;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Stock Details',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: provider.isLoading && details == null
          ? const Center(child: CircularProgressIndicator())
          : details == null
              ? const Center(child: Text('No details found'))
              : RefreshIndicator(
                  onRefresh: () => context.read<InventoryProvider>().loadStockDetails(widget.productId),
                  child: _buildContent(details),
                ),
    );
  }

  Widget _buildContent(Map<String, dynamic> details) {
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: symbol, decimalDigits: 0);
    final available = details['available'] as int? ?? 0;
    final sold = details['sold'] as int? ?? 0;
    final defective = details['defective'] as int? ?? 0;
    final openIssuesCount = details['openIssuesCount'] as int? ?? 0;
    final total = details['total'] as int? ?? 0;
    final serialNumbers =
        details['serialNumbers'] as List<dynamic>? ?? [];
    final imageUrl = details['imageUrl'] as String? ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(details, imageUrl, currencyFormat),
          const SizedBox(height: 16),
          _buildSummaryCards(available, sold, defective, openIssuesCount, total),
          const SizedBox(height: 16),
          _buildStatusDistribution(serialNumbers),
          const SizedBox(height: 16),
          _buildSectionTitle('Serial Numbers'),
          const SizedBox(height: 8),
          _buildSerialNumbersList(serialNumbers),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProductHeader(
      Map<String, dynamic> details, String imageUrl, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surfaceContainerLowest,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorWidget: (context, error, stackTrace) =>
                        _placeholderImage(),
                    placeholder: (context, url) => _placeholderImage(),
                  )
                : _placeholderImage(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details['productName'] as String? ?? '',
                  style: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${details['categoryName'] as String? ?? ''} • ${details['modelNumber'] as String? ?? ''}',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if ((details['description'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details['description'] as String? ?? '',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.inventory_2,
        size: 32,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildSummaryCards(
      int available, int sold, int defective, int openIssuesCount, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: (MediaQuery.of(context).size.width - 56) / 3,
            child: _buildStatCard(
              'Available', '$available', AppColors.statusInStock, Icons.check_circle,
            ),
          ),
          SizedBox(
            width: (MediaQuery.of(context).size.width - 56) / 3,
            child: _buildStatCard('Sold', '$sold', AppColors.secondary, Icons.sell),
          ),
          SizedBox(
            width: (MediaQuery.of(context).size.width - 56) / 3,
            child: _buildStatCard(
              'Defective', '$defective', AppColors.error, Icons.bug_report,
            ),
          ),
          if (openIssuesCount > 0)
            SizedBox(
              width: (MediaQuery.of(context).size.width - 56) / 3,
              child: _buildStatCard(
                'Open Issues', '$openIssuesCount', AppColors.error, Icons.report_problem,
              ),
            ),
          SizedBox(
            width: (MediaQuery.of(context).size.width - 56) / 3,
            child: _buildStatCard('Total', '$total', AppColors.primaryContainer, Icons.inventory_2),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution(List<dynamic> serialNumbers) {
    final available =
        serialNumbers.where((s) => s['status'] == 'available').length;
    final sold = serialNumbers.where((s) => s['status'] == 'sold').length;
    final defective = serialNumbers.where((s) => s['status'] == 'defective').length;
    final total = serialNumbers.length;
    final availablePercent = total > 0 ? (available / total * 100) : 0.0;
    final soldPercent = total > 0 ? (sold / total * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Distribution',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Flexible(
                    flex: available,
                    child: Container(color: AppColors.statusInStock),
                  ),
                  if (sold > 0)
                    Flexible(
                      flex: sold,
                      child: Container(color: AppColors.statusOutOfStock),
                    ),
                  if (defective > 0)
                    Flexible(
                      flex: defective,
                      child: Container(color: AppColors.error),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegend(AppColors.statusInStock, 'Available ($available)'),
              const SizedBox(width: 16),
              _buildLegend(AppColors.statusOutOfStock, 'Sold ($sold)'),
              if (defective > 0) ...[
                const SizedBox(width: 16),
                _buildLegend(AppColors.error, 'Defective ($defective)'),
              ],
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${availablePercent.toStringAsFixed(1)}% available, ${soldPercent.toStringAsFixed(1)}% sold',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Hanken Grotesk',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
    );
  }

  Widget _buildSerialNumbersList(List<dynamic> serialNumbers) {
    if (serialNumbers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No serial numbers found',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: serialNumbers.length,
      itemBuilder: (context, index) {
        final serial = serialNumbers[index];
        final status = serial['status'] as String? ?? 'available';
        final isAvailable = status == 'available';

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: isAvailable
                    ? AppColors.statusInStock
                    : AppColors.statusOutOfStock,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onLongPress: () {
                    final sn = serial['serialNumber'] as String? ?? '';
                    Clipboard.setData(ClipboardData(text: sn));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Serial number copied')),
                    );
                  },
                  child: Text(
                    serial['serialNumber'] as String? ?? '',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.statusInStockBg
                      : AppColors.statusOutOfStockBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isAvailable
                        ? AppColors.statusInStock
                        : AppColors.statusOutOfStock,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
