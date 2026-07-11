import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/sales/models/sale_model.dart';
import 'package:smartstock/features/sales/providers/sale_provider.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:smartstock/features/warranty/screens/warranty_details_screen.dart';

class SaleDetailsScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailsScreen({super.key, required this.saleId});

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  bool _hideSensitive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSaleById(widget.saleId);
    });
  }

  String _mask(String value) => _hideSensitive ? '*****' : value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saleProvider = context.watch<SaleProvider>();
    final sale = saleProvider.selectedSale;
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final priceFormatter = NumberFormat.currency(symbol: symbol);
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('hh:mm a');

    if (saleProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sale Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (sale == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sale Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Sale not found', style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    final isWarrantyValid = sale.warrantyExpiryDate.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Sale Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Sale Information',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (sale.isReplacement)
                          _badge('Replacement', Colors.orange)
                        else if (sale.isWarrantyClaim)
                          _badge('Warranty Claim', Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(theme, 'Sale ID', sale.id),
                    _buildInfoRow(
                        theme, 'Date', dateFormatter.format(sale.saleDate)),
                    _buildInfoRow(
                        theme, 'Time', timeFormatter.format(sale.saleDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product Information',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (sale.imageUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showFullImage(context, sale.imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            sale.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 200,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Icon(Icons.image,
                                    size: 48,
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _buildInfoRow(theme, 'Product', sale.productName),
                    _buildInfoRow(theme, 'Model', sale.modelNumber),
                    if (sale.isWarrantyClaim) ...[
                      _buildInfoRow(theme, 'Old Serial', sale.oldSerialNumber ?? '-'),
                      _buildInfoRow(theme, 'New Serial', sale.serialNumber,
                          valueColor: theme.colorScheme.primary),
                    ] else if (sale.warrantyClaimed) ...[
                      _buildInfoRow(theme, 'Serial Number', sale.serialNumber),
                      if (sale.newSerialNumber != null)
                        _buildInfoRow(theme, 'New Serial', sale.newSerialNumber!,
                            valueColor: Colors.green),
                    ] else
                      _buildInfoRow(theme, 'Serial Number', sale.serialNumber, onLongPress: () {
                        Clipboard.setData(ClipboardData(text: sale.serialNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Serial number copied')),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer Information',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildInfoRow(theme, 'Name', sale.customerName),
                    _buildInfoRow(theme, 'Phone', sale.customerPhone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Price Breakdown',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _hideSensitive = !_hideSensitive),
                          child: Icon(
                            _hideSensitive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 20,
                            color: _hideSensitive ? Colors.orange : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(theme, 'Purchase Price',
                        _mask(priceFormatter.format(sale.purchasePrice))),
                    _buildInfoRow(theme, 'Sale Price',
                        priceFormatter.format(sale.salePrice)),
                    const Divider(),
                    _buildInfoRow(
                      theme,
                      'Profit',
                      _mask(priceFormatter.format(sale.profit)),
                      valueColor:
                          sale.profit >= 0 ? Colors.green : Colors.red,
                    ),
                    _buildInfoRow(
                      theme,
                      'Profit Margin',
                      _mask(sale.salePrice > 0
                          ? '${(sale.profit / sale.salePrice * 100).toStringAsFixed(1)}%'
                          : '0.0%'),
                      valueColor:
                          sale.profit >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Warranty Information',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (sale.warrantyClaimed)
                          _badge('Claimed', Colors.grey)
                        else if (isWarrantyValid)
                          _badge('Active', Colors.green)
                        else
                          _badge('Expired', Colors.red),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (sale.warrantyClaimed) ...[
                      _buildInfoRow(theme, 'Old Serial', sale.serialNumber),
                      if (sale.newSerialNumber != null)
                        _buildInfoRow(theme, 'New Serial', sale.newSerialNumber!,
                            valueColor: theme.colorScheme.primary),
                      _buildInfoRow(theme, 'Status', 'Warranty'),
                      if (sale.claimDate != null)
                        _buildInfoRow(theme, 'Claim Date',
                            dateFormatter.format(sale.claimDate!)),
                      if (sale.relatedSaleId != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SaleDetailsScreen(saleId: sale.relatedSaleId!),
                                ),
                              );
                            },
                            icon: const Icon(Icons.receipt, size: 18),
                            label: const Text('View Claim Sale'),
                          ),
                        ),
                      ],
                    ] else if (isWarrantyValid) ...[
                      _buildInfoRow(theme, 'Expiry Date',
                          dateFormatter.format(sale.warrantyExpiryDate)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _getWarrantyProgress(sale),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: Colors.green,
                      ),
                    ] else ...[
                      _buildInfoRow(theme, 'Expiry Date',
                          dateFormatter.format(sale.warrantyExpiryDate)),
                      _buildInfoRow(theme, 'Status', 'Warranty expired'),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WarrantyDetailsScreen(warrantyId: sale.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('View Warranty Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmVoidSale(context, sale),
                icon: const Icon(Icons.undo_rounded, color: Colors.red),
                label: const Text('Void Sale',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmVoidSale(BuildContext context, Sale sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Sale?'),
        content: Text(
          'This will:\n'
          '• Free serial ${sale.serialNumber} back to available\n'
          '• Restore product stock\n'
          '• Delete this sale record\n\n'
          'Are you sure?',
        ),
        actions: [
          Debounced(
            onPressed: () => Navigator.pop(ctx, false),
            builder: (_, isDisabled) => TextButton(
              onPressed: isDisabled ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
          ),
          Debounced(
            onPressed: () => Navigator.pop(ctx, true),
            builder: (context, isDisabled) => FilledButton(
              onPressed: isDisabled ? null : () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Void Sale'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await context.read<SaleProvider>().voidSale(sale.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale voided successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to void sale: $e')),
      );
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(imageUrl, fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 64, color: Colors.white54)),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value,
      {Color? valueColor, VoidCallback? onLongPress}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Flexible(
            child: onLongPress != null
                ? Debounced(
                    onPressed: onLongPress,
                    builder: (context, isDisabled) => GestureDetector(
                      onTap: isDisabled ? null : onLongPress,
                      child: Text(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: valueColor,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
                    textAlign: TextAlign.end,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double _getWarrantyProgress(Sale sale) {
    final totalDays = 365.0;
    final remaining = sale.warrantyExpiryDate.difference(DateTime.now()).inDays;
    if (remaining <= 0) return 0;
    return remaining / totalDays;
  }
}
