import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/product_issues/models/product_issue_model.dart';
import 'package:smartstock/features/product_issues/services/product_issue_service.dart';
import 'package:smartstock/features/products/models/product_model.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/products/screens/edit_product_screen.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductById(widget.productId);
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          Debounced(
            onPressed: () => Navigator.pop(ctx),
            builder: (_, isDisabled) => TextButton(
              onPressed: isDisabled ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ),
          Debounced(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ProductProvider>()
                  .deleteProduct(widget.productId);
              Navigator.pop(context);
            },
            builder: (context, isDisabled) => FilledButton(
              onPressed: isDisabled
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      context
                          .read<ProductProvider>()
                          .deleteProduct(widget.productId);
                      Navigator.pop(context);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final product = provider.selectedProduct;
    final showLoading = provider.isLoading ||
        (product != null && product.id != widget.productId);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProductScreen(productId: widget.productId),
              ),
            ),
            icon: const Icon(Icons.edit, color: AppColors.primaryContainer),
          ),
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete, color: AppColors.error),
          ),
        ],
      ),
      body: showLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && product == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 8),
                      Text(provider.error!),
                      const SizedBox(height: 16),
                      Debounced(
                        onPressed: () =>
                            provider.loadProductById(widget.productId),
                        builder: (context, isDisabled) => FilledButton(
                          onPressed: isDisabled
                              ? null
                              : () =>
                                  provider.loadProductById(widget.productId),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                          ),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                )
              : product == null
                  ? const Center(child: Text('Product not found'))
                  : _buildContent(product),
    );
  }

  Widget _buildContent(Product product) {
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: symbol);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(product.imageUrl),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.productName,
                        style: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    _buildStockBadge(product.availableQuantity),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.brandName} • ${product.modelNumber}',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.categoryName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Pricing'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        label: 'Purchase Price',
                        value: currencyFormat.format(product.purchasePrice),
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        label: 'Selling Price',
                        value: currencyFormat.format(product.sellingPrice),
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Stock Information'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        label: 'Available',
                        value: '${product.availableQuantity}',
                        color: AppColors.statusInStock,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard(
                        label: 'Sold',
                        value: '${product.soldQuantity}',
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FutureBuilder<List<ProductIssue>>(
                        future: ProductIssueService()
                            .getIssuesByProduct(product.id),
                        builder: (context, snapshot) {
                          final count = snapshot.data
                                  ?.where((i) => i.status != 'resolved')
                                  .length ??
                              0;
                          return _buildInfoCard(
                            label: 'Issues',
                            value: '$count',
                            color: AppColors.error,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (product.description.isNotEmpty) ...[
                  _buildSectionTitle('Description'),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildSectionTitle('Details'),
                const SizedBox(height: 8),
                _buildDetailRow('Warranty', '${product.warrantyMonths} months'),
                _buildDetailRow(
                    'Created', dateFormat.format(product.createdAt)),
                if (product.id.isNotEmpty)
                  _buildDetailRow('Product ID', product.id),
                const SizedBox(height: 20),
                _buildSectionTitle('Serial Numbers'),
                const SizedBox(height: 8),
                _buildSerialNumbers(),
                const SizedBox(height: 20),
                _buildIssuesSection(product.id),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
        child: Image.network(
          imageUrl,
          height: 240,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderImage(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholderImage();
          },
        ),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      color: AppColors.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.inventory_2, size: 64, color: AppColors.onSurfaceVariant),
      ),
    );
  }

  Widget _buildStockBadge(int quantity) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    if (quantity == 0) {
      bgColor = AppColors.statusOutOfStockBg;
      textColor = AppColors.statusOutOfStock;
      icon = Icons.error;
      label = 'Out of Stock';
    } else if (quantity <= 5) {
      bgColor = AppColors.statusLowStockBg;
      textColor = AppColors.statusLowStock;
      icon = Icons.warning;
      label = 'Low Stock';
    } else {
      bgColor = AppColors.statusInStockBg;
      textColor = AppColors.statusInStock;
      icon = Icons.check_circle;
      label = 'In Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Hanken Grotesk',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required Color color,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesSection(String productId) {
    return FutureBuilder<List<ProductIssue>>(
      future: ProductIssueService().getIssuesByProduct(productId),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final issues = all.where((i) => i.status != 'resolved').toList();
        if (issues.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Issues (${issues.length})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            ...issues.map((issue) => GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.productIssuesDetails,
                    arguments: issue.id,
                  ),
                  child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bug_report,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue.issueType.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                            Text(
                              issue.issueDescription,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Serial: ${issue.serialNumber}',
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.onSurfaceVariant),
                    ],
                  ),
                ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildSerialNumbers() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<ProductProvider>().getSerialNumbers(
            widget.productId,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final allSerials = snapshot.data ?? [];
        final available =
            allSerials.where((s) => s['status'] == 'available').toList();
        final sold =
            allSerials.where((s) => s['status'] == 'sold').toList();

        if (allSerials.isEmpty) {
          return const Text(
            'No serial numbers registered',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          );
        }

        final dateFormat = DateFormat('MMM dd, yyyy');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (available.isNotEmpty) ...[
              Text(
                'Available Stock (${available.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusInStock,
                ),
              ),
              const SizedBox(height: 8),
              ...available.map((serial) => _SerialTile(
                    serial: serial,
                    dateFormat: dateFormat,
                    onTap: null,
                  )),
              const SizedBox(height: 16),
            ],
            if (sold.isNotEmpty) ...[
              Text(
                'Sold History (${sold.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusOutOfStock,
                ),
              ),
              const SizedBox(height: 8),
              ...sold.map((serial) => _SerialTile(
                    serial: serial,
                    dateFormat: dateFormat,
                    onTap: () {
                      final saleId = serial['saleId'] as String?;
                      if (saleId != null && saleId.isNotEmpty) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.salesDetails,
                          arguments: saleId,
                        );
                      }
                    },
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _SerialTile extends StatelessWidget {
  final Map<String, dynamic> serial;
  final DateFormat dateFormat;
  final VoidCallback? onTap;

  const _SerialTile({
    required this.serial,
    required this.dateFormat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = serial['status'] as String;
    final isAvailable = status == 'available';
    final created = serial['createdAt'] as dynamic;
    final hasSale = onTap != null;

    return GestureDetector(
      onTap: hasSale ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: isAvailable
                      ? AppColors.statusInStock
                      : AppColors.statusOutOfStock,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onLongPress: () {
                      final sn = serial['serialNumber'] as String;
                      Clipboard.setData(ClipboardData(text: sn));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Serial number copied')),
                      );
                    },
                    child: Text(
                      serial['serialNumber'] as String,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
                if (hasSale)
                  const Icon(Icons.chevron_right, size: 18,
                      color: AppColors.onSurfaceVariant),
              ],
            ),
            Row(
              children: [
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAvailable
                        ? AppColors.statusInStock
                        : AppColors.statusOutOfStock,
                  ),
                ),
                if (hasSale) ...[
                  const Spacer(),
                  Text('View Sale',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        color: AppColors.primary,
                      )),
                ],
              ],
            ),
            if (created != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Added: ${dateFormat.format(created is Timestamp ? created.toDate() : DateTime.tryParse(created.toString()) ?? DateTime.now())}',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}