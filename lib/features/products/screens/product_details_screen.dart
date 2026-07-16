import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
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

class _ProductDetailsScreenState extends State<ProductDetailsScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>>? _serialNumbers;
  List<ProductIssue>? _issues;
  bool _loadingSerials = true;
  Product? _product;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
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

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    if (mounted) setState(() {});
    try {
      final provider = context.read<ProductProvider>();
      await provider.loadProductById(widget.productId);
      _product = provider.selectedProduct;
      if (!mounted) return;
      _serialNumbers = await provider.getSerialNumbers(widget.productId);
      _issues = await ProductIssueService().getIssuesByProduct(widget.productId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    _loadingSerials = false;
    if (mounted) setState(() {});
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
                child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain,
                    errorWidget: (_, _, _) => const Icon(Icons.broken_image, size: 64, color: Colors.white54)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? _buildLoading(isDark)
          : _error != null && _product == null
              ? _buildError()
              : _product == null
                  ? _buildNotFound(isDark)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _buildContent(_product!, isDark),
                    ),
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

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.statusOutOfStockBg, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.error)),
          const SizedBox(height: 16),
          Text(_error ?? 'Unknown error', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
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
    final symbol = context.read<SettingsProvider>().currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: symbol, decimalDigits: 0);
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
                        decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(6)),
                        child: Text(product.categoryName, style: const TextStyle(fontFamily: 'Geist', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
                if (product.isSerialized) ...[
                  _buildSerialNumbers(product.id, dateFormat, isDark),
                  const SizedBox(height: 20),
                  _buildIssuesSection(product.id, isDark),
                ] else ...[
                  const SizedBox(height: 16),
                  _buildQuantityProductInfo(product, isDark),
                ],
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
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F7),
          ),
          child: product.imageUrl.isNotEmpty
              ? GestureDetector(
                  onTap: () => _showFullImage(context, product.imageUrl),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _buildPlaceholder(isDark),
                  ),
                )
              : _buildPlaceholder(isDark),
        ),
        if (product.imageUrl.isNotEmpty)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.75, 1.0],
                ),
              ),
            ),
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
          child: _HeaderBtn(
            icon: Icons.edit_rounded,
            isDark: isDark,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductScreen(productId: widget.productId))),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.productName, style: AppTextStyles.headlineMd.copyWith(
                color: product.imageUrl.isNotEmpty ? Colors.white : (AppColors.textPrimary),
              )),
              const SizedBox(height: 2),
              Text('${product.brandName.isNotEmpty ? '${product.brandName} · ' : ''}${product.modelNumber}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: product.imageUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.85) : (AppColors.textSecondary),
                  )),
              SizedBox(height: product.imageUrl.isNotEmpty ? 16 : 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white.withAlpha(15) : AppColors.primary.withAlpha(10)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (isDark ? Colors.white.withAlpha(20) : AppColors.primary.withAlpha(30)),
            width: 1,
          ),
        ),
        child: Icon(Icons.inventory_2_rounded, size: 48,
            color: isDark ? Colors.white.withAlpha(60) : AppColors.primary.withAlpha(80)),
      ),
    );
  }

  Widget _buildPricingSection(Product product, NumberFormat fmt, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pricing', style: AppTextStyles.titleSm.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _PriceTile(label: 'Purchase Price', value: fmt.format(product.purchasePrice), color: AppColors.primary, isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _PriceTile(label: 'Selling Price', value: fmt.format(product.sellingPrice), color: AppColors.primary, isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _PriceTile(
                label: 'Margin',
                value: '${((product.sellingPrice - product.purchasePrice) / product.purchasePrice * 100).toStringAsFixed(0)}%',
                color: AppColors.success,
                isDark: isDark,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockSection(Product product, bool isDark) {
    final issueCount = _issues?.where((i) => i.status != 'resolved').length ?? 0;
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock Information', style: AppTextStyles.titleSm.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StockIndicator(label: 'Available', value: '${product.availableQuantity}', color: AppColors.success, total: product.availableQuantity + product.soldQuantity, isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _StockIndicator(label: 'Sold', value: '${product.soldQuantity}', color: AppColors.primary, total: product.availableQuantity + product.soldQuantity, isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _StockIndicator(label: 'Issues', value: '$issueCount', color: AppColors.error, total: issueCount > 0 ? issueCount : 1, isDark: isDark)),
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
          Text('Description', style: AppTextStyles.titleSm.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(description, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
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
          Text('Product Details', style: AppTextStyles.titleSm.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _DetailRow(label: 'Warranty', value: '${product.warrantyMonths} months', isDark: isDark),
          _DetailRow(label: 'Created', value: df.format(product.createdAt), isDark: isDark),
          if (product.id.isNotEmpty) _DetailRow(label: 'Product ID', value: product.id, isDark: isDark, mono: true),
        ],
      ),
    );
  }

  Widget _buildSerialNumbers(String productId, DateFormat df, bool isDark) {
    if (_loadingSerials) return _buildSectionSkeleton(isDark);

    final allSerials = _serialNumbers ?? [];
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
              Text('Serial Numbers', style: AppTextStyles.titleSm.copyWith(color: AppColors.textPrimary)),
              Text('${available.length} available · ${sold.length} sold',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          if (available.isNotEmpty) ...[
            Text('Available Stock (${available.length})', style: AppTextStyles.labelSm.copyWith(color: AppColors.success)),
            const SizedBox(height: 6),
            ...available.map((serial) => _SerialTile(serial: serial, dateFormat: df, isDark: isDark)),
            const SizedBox(height: 12),
          ],
          if (sold.isNotEmpty) ...[
            Text('Sold History (${sold.length})', style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
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
  }

  Widget _buildIssuesSection(String productId, bool isDark) {
    final all = _issues ?? [];
    final issues = all.where((i) => i.status != 'resolved').toList();
    if (issues.isEmpty) return const SizedBox.shrink();

        return ModernCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bug_report_rounded, size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Text('Open Issues (${issues.length})', style: AppTextStyles.titleSm.copyWith(color: AppColors.error)),
                ],
              ),
              const SizedBox(height: 12),
              ...issues.map((issue) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusOutOfStockBg.withAlpha(60),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withAlpha(40)),
                ),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.productIssuesDetails, arguments: issue.id),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(issue.issueType.toUpperCase(), style: AppTextStyles.labelSm.copyWith(color: AppColors.error)),
                            Text(issue.issueDescription, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('SN: ${issue.serialNumber}', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
  }

  Widget _buildQuantityProductInfo(Product product, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Stock Information', style: AppTextStyles.titleSm.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Available', value: '${product.availableQuantity} units', isDark: isDark),
          _DetailRow(label: 'Sold', value: '${product.soldQuantity} units', isDark: isDark),
          const SizedBox(height: 8),
          const Text('No serial number tracking (Quantity-based)',
              style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
        ],
      ),
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
      case 'In Stock': return AppColors.success;
      case 'Low Stock': return AppColors.warning;
      case 'Out of Stock': return AppColors.error;
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
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
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
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
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
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
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
          SizedBox(width: 100, child: Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: TextStyle(fontFamily: mono ? 'Geist' : 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
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
    final created = serial['dateAdded'] as dynamic ?? serial['createdAt'] as dynamic;
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
              decoration: BoxDecoration(color: isAvailable ? AppColors.success : AppColors.error, shape: BoxShape.circle),
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
                    Text(serial['serialNumber'] as String, style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.textPrimary)),
                    Row(
                      children: [
                        Text(status.toUpperCase(), style: TextStyle(fontFamily: 'Geist', fontSize: 10, fontWeight: FontWeight.w600, color: isAvailable ? AppColors.success : AppColors.error)),
                        if (hasSale) ...[
                          const SizedBox(width: 8),
                          Text('View Sale', style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: AppColors.primary)),
                        ],
                      ],
                    ),
                    if (created != null)
                      Text('Added: ${dateFormat.format(created is Timestamp ? created.toDate() : DateTime.tryParse(created.toString()) ?? DateTime.now())}',
                          style: TextStyle(fontFamily: 'Geist', fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
            if (hasSale) Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
