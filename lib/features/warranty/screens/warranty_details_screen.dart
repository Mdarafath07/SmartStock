import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/utils/date_utils.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/core/widgets/error_widget.dart';
import 'package:smartstock/features/warranty/models/warranty_model.dart';
import 'package:smartstock/features/sales/screens/sale_details_screen.dart';
import 'package:smartstock/features/warranty/providers/warranty_provider.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:smartstock/features/warranty/widgets/serial_number_picker_dialog.dart';

class WarrantyDetailsScreen extends StatefulWidget {
  final String warrantyId;

  const WarrantyDetailsScreen({super.key, required this.warrantyId});

  @override
  State<WarrantyDetailsScreen> createState() => _WarrantyDetailsScreenState();
}

class _WarrantyDetailsScreenState extends State<WarrantyDetailsScreen> {
  bool _isClaiming = false;
  Map<String, dynamic>? _claimResult;

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
          if (warranty.isClaimable) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isClaiming ? null : _claim,
                icon: _isClaiming
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user),
                label: const Text('Claim Your Warranty'),
              ),
            ),
          ],
          if (warranty.warrantyClaimed) ...[
            const SizedBox(height: 20),
            _buildClaimSummary(warranty),
          ],
        ],
      ),
    );
  }

  Future<void> _claim() async {
    final provider = context.read<WarrantyProvider>();
    final w = provider.selectedWarranty;
    if (w == null) return;

    final newSerial = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ClaimFormDialog(),
    );
    if (newSerial == null || !mounted) return;

    setState(() => _isClaiming = true);
    try {
      await provider.processClaim(
        saleId: w.saleId,
        serialNumber: w.serialNumber,
        newSerialNumber: newSerial,
        notes: 'Claimed from warranty details',
      );
      setState(() {
        _claimResult = {'newSerial': newSerial};
      });
      if (mounted) {
        provider.loadBySaleId(widget.warrantyId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  Widget _buildClaimSummary(Warranty warranty) {
    final isClaimSale = warranty.saleType == 'warranty_claim';
    final dateFormat = DateFormat('MMM dd, yyyy');

    final String oldSerial;
    final String? oldName;
    final String? oldModel;
    final DateTime? oldDate;

    final String newSerial;
    final String? newName;
    final String? newModel;
    final DateTime? newDate;

    if (isClaimSale) {
      oldSerial = warranty.oldSerialNumber ?? '-';
      oldName = null;
      oldModel = null;
      oldDate = warranty.oldPurchaseDate;

      newSerial = warranty.serialNumber;
      newName = warranty.productName;
      newModel = warranty.modelNumber;
      newDate = warranty.purchaseDate;
    } else {
      oldSerial = warranty.serialNumber;
      oldName = warranty.productName;
      oldModel = warranty.modelNumber;
      oldDate = warranty.purchaseDate;

      newSerial = _claimResult != null
          ? _claimResult!['newSerial'] as String
          : warranty.newSerialNumber ?? '-';
      newName = null;
      newModel = null;
      newDate = warranty.claimDate;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_rounded, color: ColorConstants.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('Warranty Claim Summary',
                    style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 24),
            Text('Original Product (Returned)',
                style: AppTextStyles.titleMd.copyWith(fontSize: 14, color: ColorConstants.onSurfaceVariant)),
            const SizedBox(height: 8),
            if (oldName != null) _infoRow(Icons.inventory_2_rounded, 'Product: $oldName'),
            if (oldModel != null) _infoRow(Icons.qr_code_rounded, 'Model: $oldModel'),
            _infoRow(Icons.confirmation_number_rounded, 'Serial: $oldSerial'),
            if (oldDate != null) _infoRow(Icons.date_range_rounded, 'Purchase: ${dateFormat.format(oldDate)}'),
            const Divider(height: 24),
            Text('Replacement Product (Warranty)',
                style: AppTextStyles.titleMd.copyWith(fontSize: 14, color: ColorConstants.onSurfaceVariant)),
            const SizedBox(height: 8),
            if (newName != null) _infoRow(Icons.inventory_2_rounded, 'Product: $newName'),
            if (newModel != null) _infoRow(Icons.qr_code_rounded, 'Model: $newModel'),
            _infoRow(Icons.qr_code_rounded, 'Serial: $newSerial',
                customColor: ColorConstants.primary),
            if (newDate != null) _infoRow(Icons.date_range_rounded, 'Claim Date: ${dateFormat.format(newDate)}',
                customColor: ColorConstants.primary),
            if (warranty.relatedSaleId != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SaleDetailsScreen(saleId: warranty.relatedSaleId!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt, size: 18),
                  label: Text(isClaimSale ? 'View Original Sale' : 'View Claim Sale'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(Warranty warranty) {
    final bool isClaimed = warranty.warrantyClaimed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isClaimed
            ? ColorConstants.surfaceContainerHighest
            : warranty.isActive
                ? ColorConstants.successContainer
                : ColorConstants.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isClaimed
                ? Icons.assignment_rounded
                : warranty.isActive
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
            size: 64,
            color: isClaimed
                ? ColorConstants.onSurfaceVariant
                : warranty.isActive
                    ? ColorConstants.success
                    : ColorConstants.error,
          ),
          const SizedBox(height: 12),
          Text(
            isClaimed
                ? 'Warranty Claimed'
                : warranty.isActive
                    ? 'Warranty Active'
                    : 'Warranty Expired',
            style: AppTextStyles.titleMd.copyWith(
              color: isClaimed
                  ? ColorConstants.onSurfaceVariant
                  : warranty.isActive
                      ? ColorConstants.success
                      : ColorConstants.error,
            ),
          ),
          const SizedBox(height: 4),
          if (isClaimed) ...[
            Text(
              'Old Serial: ${warranty.serialNumber}',
              style: AppTextStyles.bodyMd.copyWith(
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
            if (warranty.newSerialNumber != null)
              Text(
                'New Serial: ${warranty.newSerialNumber}',
                style: AppTextStyles.bodyMd.copyWith(
                  color: ColorConstants.primary,
                ),
              ),
          ] else
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
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: symbol);
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

  Widget _infoRow(IconData icon, String text, {VoidCallback? onLongPress, Color? customColor}) {
    final iconColor = customColor ?? ColorConstants.onSurfaceVariant;
    final textColor = customColor ?? ColorConstants.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: onLongPress != null
              ? Debounced(
                  onPressed: onLongPress,
                  builder: (context, isDisabled) => GestureDetector(
                    onTap: isDisabled ? null : onLongPress,
                    child: Text(
                      text,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
              )
              : Text(
                  text,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: textColor,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ClaimFormDialog extends StatefulWidget {
  const _ClaimFormDialog();

  @override
  State<_ClaimFormDialog> createState() => _ClaimFormDialogState();
}

class _ClaimFormDialogState extends State<_ClaimFormDialog> {
  final _serialCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _serialCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Claim Warranty'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _serialCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'New Serial Number',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.arrow_drop_down),
                helperText: 'Tap to select from available stock',
              ),
              onTap: () async {
                final selected = await showDialog<String>(
                  context: context,
                  builder: (_) => const SerialNumberPickerDialog(),
                );
                if (selected != null) {
                  _serialCtrl.text = selected;
                }
              },
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Serial number is required'
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
            ),
          ],
        ),
      ),
      actions: [
        Debounced(
          onPressed: () => Navigator.pop(context),
          builder: (_, isDisabled) => TextButton(
            onPressed: isDisabled ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        Debounced(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _serialCtrl.text.trim());
            }
          },
          builder: (context, isDisabled) => FilledButton(
            onPressed: isDisabled ? null : () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, _serialCtrl.text.trim());
              }
            },
            child: const Text('Submit'),
          ),
        ),
      ],
    );
  }
}
