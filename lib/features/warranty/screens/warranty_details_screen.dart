import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/utils/date_utils.dart';
import 'package:smartstock/core/widgets/error_widget.dart';
import 'package:smartstock/features/warranty/models/warranty_model.dart';
import 'package:smartstock/features/warranty/providers/warranty_provider.dart';

class WarrantyDetailsScreen extends StatefulWidget {
  final String warrantyId;

  const WarrantyDetailsScreen({super.key, required this.warrantyId});

  @override
  State<WarrantyDetailsScreen> createState() => _WarrantyDetailsScreenState();
}

class _WarrantyDetailsScreenState extends State<WarrantyDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WarrantyProvider>().loadBySaleId(widget.warrantyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranty Details'),
      ),
      body: Consumer<WarrantyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.loadBySaleId(widget.warrantyId),
            );
          }

          final warranty = provider.selectedWarranty;
          if (warranty == null) {
            return const Center(child: Text('Warranty not found'));
          }

          return _buildDetails(context, warranty);
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Warranty warranty) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(warranty),
          const SizedBox(height: 20),
          _buildSectionTitle('Product Information'),
          const SizedBox(height: 8),
          _buildProductSection(warranty),
          const SizedBox(height: 20),
          _buildSectionTitle('Customer Information'),
          const SizedBox(height: 8),
          _buildCustomerSection(warranty),
          const SizedBox(height: 20),
          _buildSectionTitle('Sale Information'),
          const SizedBox(height: 8),
          _buildSaleSection(warranty),
          const SizedBox(height: 20),
          _buildSectionTitle('Warranty Timeline'),
          const SizedBox(height: 8),
          _buildTimeline(warranty),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(Warranty warranty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: warranty.isActive
            ? ColorConstants.successContainer
            : ColorConstants.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            warranty.isActive
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 64,
            color: warranty.isActive
                ? ColorConstants.success
                : ColorConstants.error,
          ),
          const SizedBox(height: 12),
          Text(
            warranty.isActive ? 'Warranty Active' : 'Warranty Expired',
            style: AppTextStyles.titleMd.copyWith(
              color: warranty.isActive
                  ? ColorConstants.success
                  : ColorConstants.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            warranty.isActive
                ? 'Valid Until: ${AppDateUtils.formatDate(warranty.expiryDate)}'
                : 'Expired On: ${AppDateUtils.formatDate(warranty.expiryDate)}',
            style: AppTextStyles.bodyMd.copyWith(
              color: warranty.isActive
                  ? ColorConstants.success
                  : ColorConstants.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(Warranty warranty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (warranty.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.network(
                    warranty.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(),
                  ),
                ),
              )
            else
              _placeholder(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warranty.productName,
                    style: AppTextStyles.titleMd,
                  ),
                  const SizedBox(height: 4),
                  _infoRow(
                    Icons.qr_code_rounded,
                    'Model: ${warranty.modelNumber}',
                  ),
                  const SizedBox(height: 2),
                  _infoRow(
                    Icons.confirmation_number_rounded,
                    'S/N: ${warranty.serialNumber}',
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: warranty.serialNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Serial number copied')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        color: ColorConstants.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCustomerSection(Warranty warranty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              Icons.person_rounded,
              warranty.customerName,
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.phone_rounded,
              warranty.customerPhone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleSection(Warranty warranty) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              Icons.receipt_long_rounded,
              'Sale ID: ${warranty.saleId}',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.shopping_cart_rounded,
              'Purchase: ${AppDateUtils.formatDate(warranty.purchaseDate)}',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.monetization_on_rounded,
              'Price: ${currencyFormat.format(warranty.salePrice)}',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.update_rounded,
              'Warranty: ${warranty.calculatedMonths} months',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(Warranty warranty) {
    final now = DateTime.now();
    final total = warranty.expiryDate.difference(warranty.purchaseDate);
    final elapsed = now.difference(warranty.purchaseDate);
    final progress = total.inDays > 0
        ? (elapsed.inDays / total.inDays).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _timelineDot(
                  Icons.add_shopping_cart_rounded,
                  ColorConstants.primary,
                ),
                const Expanded(
                  child: Divider(thickness: 2, height: 1),
                ),
                _timelineDot(
                  warranty.isActive
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  warranty.isActive
                      ? ColorConstants.success
                      : ColorConstants.error,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppDateUtils.formatDate(warranty.purchaseDate),
                  style: AppTextStyles.labelMd,
                ),
                Text(
                  warranty.isActive ? 'Today' : AppDateUtils.formatDate(warranty.expiryDate),
                  style: AppTextStyles.labelMd,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: ColorConstants.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  warranty.isActive
                      ? ColorConstants.success
                      : ColorConstants.error,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              warranty.isActive
                  ? '${elapsed.inDays} of ${total.inDays} days used (${(progress * 100).round()}%)'
                  : 'Warranty period ended (${total.inDays} days total)',
              style: AppTextStyles.bodyMd.copyWith(
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
            if (warranty.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${total.inDays - elapsed.inDays} days remaining',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.success,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _timelineDot(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMd.copyWith(
        fontSize: 18,
        color: ColorConstants.onSurface,
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {VoidCallback? onLongPress}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ColorConstants.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: onLongPress != null
              ? GestureDetector(
                  onLongPress: onLongPress,
                  child: Text(
                    text,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: ColorConstants.onSurface,
                    ),
                  ),
                )
              : Text(
                  text,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: ColorConstants.onSurface,
                  ),
                ),
        ),
      ],
    );
  }
}
