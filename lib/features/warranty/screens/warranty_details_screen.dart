import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/utils/date_utils.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/core/widgets/error_widget.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/core/widgets/status_badge.dart';
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

class _WarrantyDetailsScreenState extends State<WarrantyDetailsScreen> with WidgetsBindingObserver {
  bool _isClaiming = false;
  Map<String, dynamic>? _claimResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
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
    context.read<WarrantyProvider>().loadBySaleId(widget.warrantyId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldBg : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Warranty Details'),
        backgroundColor:
            isDark ? AppColors.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: AppTextStyles.titleMd.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
        ),
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
            return Center(
              child: Text('Warranty not found',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  )),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<WarrantyProvider>().loadBySaleId(widget.warrantyId),
            child: _buildDetails(context, warranty, isDark),
          );
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Warranty warranty, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(warranty, isDark),
          const SizedBox(height: 16),
          _buildProductSection(warranty, isDark),
          const SizedBox(height: 12),
          _buildCustomerSection(warranty, isDark),
          const SizedBox(height: 12),
          _buildSaleSection(warranty, isDark),
          const SizedBox(height: 12),
          _buildTimeline(warranty, isDark),
          if (warranty.isClaimable) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isClaiming ? null : _claim,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primary,
                ),
                icon: _isClaiming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_user, size: 20),
                label: const Text('Claim Your Warranty'),
              ),
            ),
          ],
          if (warranty.warrantyClaimed) ...[
            const SizedBox(height: 16),
            _buildClaimSummary(warranty, isDark),
          ],
          const SizedBox(height: 24),
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

  Widget _buildClaimSummary(Warranty warranty, bool isDark) {
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

    final textMuted =
        AppColors.textSecondary;
    final textPrimary =
        AppColors.textPrimary;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment_rounded,
                    size: 16, color: AppColors.warning),
              ),
              const SizedBox(width: 10),
              Text('Claim Summary',
                  style: AppTextStyles.titleSm.copyWith(color: textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceLight
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Original Product (Returned)',
                    style: AppTextStyles.labelMd.copyWith(
                        color: textMuted, letterSpacing: 0.06)),
                const SizedBox(height: 8),
                if (oldName != null)
                  _infoRow(Icons.inventory_2_rounded, 'Product: $oldName',
                      isDark: isDark),
                if (oldModel != null)
                  _infoRow(Icons.qr_code_rounded, 'Model: $oldModel',
                      isDark: isDark),
                _infoRow(Icons.confirmation_number_rounded,
                    'Serial: $oldSerial',
                    isDark: isDark),
                if (oldDate != null)
                  _infoRow(Icons.date_range_rounded,
                      'Purchase: ${dateFormat.format(oldDate)}',
                      isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceLight
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Replacement Product (Warranty)',
                    style: AppTextStyles.labelMd.copyWith(
                        color: textMuted, letterSpacing: 0.06)),
                const SizedBox(height: 8),
                if (newName != null)
                  _infoRow(Icons.inventory_2_rounded, 'Product: $newName',
                      isDark: isDark),
                if (newModel != null)
                  _infoRow(Icons.qr_code_rounded, 'Model: $newModel',
                      isDark: isDark),
                _infoRow(Icons.qr_code_rounded, 'Serial: $newSerial',
                    customColor: AppColors.primary, isDark: isDark),
                if (newDate != null)
                  _infoRow(Icons.date_range_rounded,
                      'Claim Date: ${dateFormat.format(newDate)}',
                      customColor: AppColors.primary, isDark: isDark),
              ],
            ),
          ),
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
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(
                      color: isDark
                          ? AppColors.greyDarker
                          : const Color(0xFFE5E7EB)),
                ),
                icon:
                    const Icon(Icons.receipt, size: 18, color: AppColors.primary),
                label: Text(
                    isClaimSale ? 'View Original Sale' : 'View Claim Sale'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner(Warranty warranty, bool isDark) {
    final isClaimed = warranty.warrantyClaimed;

    final Color accentColor;
    final IconData bannerIcon;
    final String statusText;
    final String? statusSubtext;

    if (isClaimed) {
      accentColor = AppColors.warning;
      bannerIcon = Icons.assignment_rounded;
      statusText = 'Warranty Claimed';
      statusSubtext = 'Old S/N: ${warranty.serialNumber}';
    } else if (warranty.isActive) {
      accentColor = AppColors.success;
      bannerIcon = Icons.check_circle_rounded;
      statusText = 'Warranty Active';
      statusSubtext =
          'Valid until ${AppDateUtils.formatDate(warranty.expiryDate)}';
    } else {
      accentColor = AppColors.error;
      bannerIcon = Icons.cancel_rounded;
      statusText = 'Warranty Expired';
      statusSubtext =
          'Expired on ${AppDateUtils.formatDate(warranty.expiryDate)}';
    }

    return ModernCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(bannerIcon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      statusText,
                      style: AppTextStyles.titleSm.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge.warranty(warranty.isActive),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusSubtext,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (isClaimed && warranty.newSerialNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'New S/N: ${warranty.newSerialNumber}',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(Warranty warranty, bool isDark) {
    return ModernCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: warranty.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: warranty.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _placeholder(isDark),
                      placeholder: (_, _) => _placeholder(isDark),
                    )
                  : _placeholder(isDark),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warranty.productName,
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                _infoRow(Icons.qr_code_rounded,
                    'Model: ${warranty.modelNumber}',
                    isDark: isDark),
                const SizedBox(height: 4),
                _infoRow(
                  Icons.confirmation_number_rounded,
                  'S/N: ${warranty.serialNumber}',
                  isDark: isDark,
                  onLongPress: () {
                    Clipboard.setData(
                        ClipboardData(text: warranty.serialNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Serial number copied')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        size: 32,
        color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB),
      ),
    );
  }

  Widget _buildCustomerSection(Warranty warranty, bool isDark) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer',
            style: AppTextStyles.labelMd.copyWith(
              color:
                  AppColors.textSecondary,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.person_rounded, warranty.customerName,
              isDark: isDark),
          const SizedBox(height: 8),
          _infoRow(Icons.phone_rounded, warranty.customerPhone,
              isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildSaleSection(Warranty warranty, bool isDark) {
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final currencyFormat = NumberFormat.currency(symbol: symbol, decimalDigits: 0);
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sale Info',
            style: AppTextStyles.labelMd.copyWith(
              color:
                  AppColors.textSecondary,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.receipt_long_rounded, 'Sale ID: ${warranty.saleId}',
              isDark: isDark),
          const SizedBox(height: 8),
          _infoRow(
              Icons.shopping_cart_rounded,
              'Purchase: ${AppDateUtils.formatDate(warranty.purchaseDate)}',
              isDark: isDark),
          const SizedBox(height: 8),
          _infoRow(
              Icons.monetization_on_rounded,
              'Price: ${currencyFormat.format(warranty.salePrice)}',
              isDark: isDark),
          const SizedBox(height: 8),
          _infoRow(Icons.update_rounded,
              'Warranty: ${warranty.calculatedMonths} months',
              isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildTimeline(Warranty warranty, bool isDark) {
    final now = DateTime.now();
    final total = warranty.expiryDate.difference(warranty.purchaseDate);
    final elapsed = now.difference(warranty.purchaseDate);
    final progress = total.inDays > 0
        ? (elapsed.inDays / total.inDays).clamp(0.0, 1.0)
        : 0.0;

    final progressColor =
        warranty.isActive ? AppColors.success : AppColors.error;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Warranty Timeline',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _timelineDot(
                  Icons.add_shopping_cart_rounded, AppColors.primary),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: progressColor,
                  ),
                ),
              ),
              _timelineDot(
                warranty.isActive
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                progressColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppDateUtils.formatDate(warranty.purchaseDate),
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                warranty.isActive
                    ? 'Today'
                    : AppDateUtils.formatDate(warranty.expiryDate),
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppColors.surfaceLight
                  : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            warranty.isActive
                ? '${elapsed.inDays} of ${total.inDays} days used (${(progress * 100).round()}%)'
                : 'Warranty period ended (${total.inDays} days total)',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (warranty.isActive)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${total.inDays - elapsed.inDays} days remaining',
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timelineDot(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text, {
    VoidCallback? onLongPress,
    Color? customColor,
    required bool isDark,
  }) {
    final iconColor = customColor ??
        (AppColors.textSecondary);
    final textColor = customColor ??
        (AppColors.textPrimary);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.surface : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.verified_user_rounded,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            'Claim Warranty',
            style: AppTextStyles.titleSm.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _serialCtrl,
              readOnly: true,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                labelText: 'New Serial Number',
                labelStyle: AppTextStyles.labelMd.copyWith(
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.greyDarker
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.greyDarker
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                helperText: 'Tap to select from available stock',
                helperStyle: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
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
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                labelText: 'Reason',
                labelStyle: AppTextStyles.labelMd.copyWith(
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.greyDarker
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.greyDarker
                        : const Color(0xFFE5E7EB),
                  ),
                ),
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
            style: TextButton.styleFrom(
              foregroundColor:
                  AppColors.textSecondary,
            ),
            child: Text('Cancel',
                style: AppTextStyles.button.copyWith(fontSize: 13)),
          ),
        ),
        Debounced(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _serialCtrl.text.trim());
            }
          },
          builder: (context, isDisabled) => FilledButton(
            onPressed: isDisabled
                ? null
                : () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, _serialCtrl.text.trim());
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Submit',
                style: AppTextStyles.button.copyWith(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}
