import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
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
              context.read<ProductProvider>().deleteProduct(widget.productId);
              Navigator.pop(context);
            },
            builder: (context, isDisabled) => FilledButton(
              onPressed: isDisabled ? null : () {
                Navigator.pop(ctx);
                context.read<ProductProvider>().deleteProduct(widget.productId);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ProductProvider>();
    final product = provider.selectedProduct;
    final showLoading = provider.isLoading || (product != null && product.id != widget.productId);

    return Scaffold(
      body: showLoading
          ? _buildLoading(isDark)
          : provider.error != null && product == null
              ? _buildError(provider)
              : product == null
                  ? _buildNotFound(isDark)
                  : _buildContent(product, isDark),
    );
  }

  Widget _buildLoading(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
      child: Column(
        children: List.generate(6, (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 60,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.shimmerBase : const Color(0xFFE5E7EB)).withAlpha(150),
            borderRadius: BorderRadius.circular(12),
          ),
        )),
      ),
    );
  }

  Widget _buildError(ProductProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.error)),
          const SizedBox(height: 16),
          Text(provider.error!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: () => provider.loadProductById(widget.productId), icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildNotFound(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_rounded, size: 48, color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text('Product not found', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildContent(Product product, bool isDark) {
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: symbol);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final stockStatus = _getStockStatus(product.availableQuantity);
    final stockColor = _getStockColor(stockStatus);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(product, isDark),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: stockColor.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: stockColor, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(stockStatus, style: TextStyle(fontFamily: 'Geist', fontSize: 11, fontWeight: FontWeight.w600, color: stockColor)),
                        ],
                      ),
                    ),
                    if (product.categoryName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.purpleBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(product.categoryName, style: const TextStyle(fontFamily: 'Geist', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.purple)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _buildPricingSection(product, currencyFormat, isDark),
                const SizedBox(height: 16),
                _buildStockSection(product, isDark),
                const SizedBox(height: 16),
                if (product.description.isNotEmpty) _buildDescription(product.description, isDark),
                const SizedBox(height: 16),
                _buildDetails(product, dateFormat, isDark),
                const SizedBox(height: 20),
                _buildSerialNumbers(product.id, dateFormat, isDark),
                const SizedBox(height: 20),
                _buildIssuesSection(product.id, isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Product product, bool isDark) {
    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A1A2E), const Color(0xFF0D0D0D)]
                  : [AppColors.greenLight.withAlpha(50), const Color(0xFFF5F5F7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: product.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _buildPlaceholder(isDark),
                )
              : _buildPlaceholder(isDark),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            icon: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.cardDark : Colors.white).withAlpha(220),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: Row(
            children: [
              _HeaderBtn(
                icon: Icons.edit_rounded,
                isDark: isDark,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductScreen(productId: widget.productId))),
              ),
              const SizedBox(width: 8),
              _HeaderBtn(
                icon: Icons.delete_rounded,
                isDark: isDark,
                onTap: _confirmDelete,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.productName, style: AppTextStyles.headlineMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
              const SizedBox(height: 2),
              Text('${product.brandName.isNotEmpty ? '${product.brandName} · ' : ''}${product.modelNumber}',
                  style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceLight : Colors.white).withAlpha(180),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.inventory_2_rounded, size: 40, color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB)),
      ),
    );
  }

  Widget _buildPricingSection(Product product, NumberFormat fmt, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pricing', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _PriceTile(label: 'Purchase Price', value: fmt.format(product.purchasePrice), color: AppColors.blue, isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _PriceTile(label: 'Selling Price', value: fmt.format(product.sellingPrice), color: AppColors.primary, isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _PriceTile(
                label: 'Margin',
                value: '${((product.sellingPrice - product.purchasePrice) / product.purchasePrice * 100).toStringAsFixed(0)}%',
                color: AppColors.green,
                isDark: isDark,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockSection(Product product, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock Information', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StockIndicator(label: 'Available', value: '${product.availableQuantity}', color: AppColors.green, total: product.availableQuantity + product.soldQuantity, isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _StockIndicator(label: 'Sold', value: '${product.soldQuantity}', color: AppColors.blue, total: product.availableQuantity + product.soldQuantity, isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: FutureBuilder<List<ProductIssue>>(
                future: ProductIssueService().getIssuesByProduct(product.id),
                builder: (context, snapshot) {
                  final count = snapshot.data?.where((i) => i.status != 'resolved').length ?? 0;
                  return _StockIndicator(label: 'Issues', value: '$count', color: AppColors.red, total: count > 0 ? count : 1, isDark: isDark);
                },
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(String description, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text(description, style: AppTextStyles.bodyMd.copyWith(color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildDetails(Product product, DateFormat df, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Details', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _DetailRow(label: 'Warranty', value: '${product.warrantyMonths} months', isDark: isDark),
          _DetailRow(label: 'Created', value: df.format(product.createdAt), isDark: isDark),
          if (product.id.isNotEmpty) _DetailRow(label: 'Product ID', value: product.id, isDark: isDark, mono: true),
        ],
      ),
    );
  }

  Widget _buildSerialNumbers(String productId, DateFormat df, bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<ProductProvider>().getSerialNumbers(widget.productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSectionSkeleton(isDark);
        }
        final allSerials = snapshot.data ?? [];
        final available = allSerials.where((s) => s['status'] == 'available').toList();
        final sold = allSerials.where((s) => s['status'] == 'sold').toList();

        if (allSerials.isEmpty) return const SizedBox.shrink();

        return ModernCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Serial Numbers', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                  Text('${available.length} available · ${sold.length} sold',
                      style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
                ],
              ),
              const SizedBox(height: 12),
              if (available.isNotEmpty) ...[
                Text('Available Stock (${available.length})', style: AppTextStyles.labelSm.copyWith(color: AppColors.green)),
                const SizedBox(height: 6),
                ...available.map((serial) => _SerialTile(serial: serial, dateFormat: df, isDark: isDark)),
                const SizedBox(height: 12),
              ],
              if (sold.isNotEmpty) ...[
                Text('Sold History (${sold.length})', style: AppTextStyles.labelSm.copyWith(color: AppColors.blue)),
                const SizedBox(height: 6),
                ...sold.map((serial) => _SerialTile(
                  serial: serial,
                  dateFormat: df,
                  isDark: isDark,
                  onTap: () {
                    final saleId = serial['saleId'] as String?;
                    if (saleId != null && saleId.isNotEmpty) {
                      Navigator.pushNamed(context, AppRoutes.salesDetails, arguments: saleId);
                    }
                  },
                )),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildIssuesSection(String productId, bool isDark) {
    return FutureBuilder<List<ProductIssue>>(
      future: ProductIssueService().getIssuesByProduct(productId),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final issues = all.where((i) => i.status != 'resolved').toList();
        if (issues.isEmpty) return const SizedBox.shrink();

        return ModernCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bug_report_rounded, size: 16, color: AppColors.red),
                  const SizedBox(width: 6),
                  Text('Open Issues (${issues.length})', style: AppTextStyles.titleSm.copyWith(color: AppColors.red)),
                ],
              ),
              const SizedBox(height: 12),
              ...issues.map((issue) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.redBg.withAlpha(60),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.red.withAlpha(40)),
                ),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.productIssuesDetails, arguments: issue.id),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(issue.issueType.toUpperCase(), style: AppTextStyles.labelSm.copyWith(color: AppColors.red)),
                            Text(issue.issueDescription, style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('SN: ${issue.serialNumber}', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionSkeleton(bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (_) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 40,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.shimmerBase : const Color(0xFFE5E7EB)).withAlpha(150),
            borderRadius: BorderRadius.circular(8),
          ),
        )),
      ),
    );
  }

  String _getStockStatus(int qty) {
    if (qty <= 0) return 'Out of Stock';
    if (qty <= 5) return 'Low Stock';
    return 'In Stock';
  }

  Color _getStockColor(String status) {
    switch (status) {
      case 'In Stock': return AppColors.green;
      case 'Low Stock': return AppColors.orange;
      case 'Out of Stock': return AppColors.red;
      default: return AppColors.grey;
    }
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.cardDark : Colors.white).withAlpha(220),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280)),
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _PriceTile({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.amountSm.copyWith(color: color, fontSize: 16)),
        ],
      ),
    );
  }
}

class _StockIndicator extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final int total;
  final bool isDark;
  const _StockIndicator({required this.label, required this.value, required this.color, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? int.parse(value.replaceAll(RegExp(r'[^0-9]'), '')) / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.amountSm.copyWith(color: color, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
          if (total > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool mono;
  const _DetailRow({required this.label, required this.value, required this.isDark, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280)))),
          Expanded(child: Text(value, style: TextStyle(fontFamily: mono ? 'Geist' : 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)))),
        ],
      ),
    );
  }
}

class _SerialTile extends StatelessWidget {
  final Map<String, dynamic> serial;
  final DateFormat dateFormat;
  final bool isDark;
  final VoidCallback? onTap;

  const _SerialTile({required this.serial, required this.dateFormat, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = serial['status'] as String;
    final isAvailable = status == 'available';
    final created = serial['createdAt'] as dynamic;
    final hasSale = onTap != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceLight : const Color(0xFFF9FAFB)).withAlpha(180),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60), width: 0.5),
      ),
      child: InkWell(
        onTap: hasSale ? onTap : null,
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: isAvailable ? AppColors.green : AppColors.red, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onLongPress: () {
                  final sn = serial['serialNumber'] as String;
                  Clipboard.setData(ClipboardData(text: sn));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Serial number copied')));
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(serial['serialNumber'] as String, style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                    Row(
                      children: [
                        Text(status.toUpperCase(), style: TextStyle(fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w600, color: isAvailable ? AppColors.green : AppColors.red)),
                        if (hasSale) ...[
                          const SizedBox(width: 8),
                          Text('View Sale', style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: AppColors.primary)),
                        ],
                      ],
                    ),
                    if (created != null)
                      Text('Added: ${dateFormat.format(created is Timestamp ? created.toDate() : DateTime.tryParse(created.toString()) ?? DateTime.now())}',
                          style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            ),
            if (hasSale) Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
