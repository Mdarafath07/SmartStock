import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/services/connectivity_service.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/products/models/product_model.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/products/screens/product_details_screen.dart';
import 'package:smartstock/features/products/widgets/barcode_scanner_screen.dart';
import 'package:smartstock/features/products/widgets/product_form.dart';
import 'package:smartstock/features/sales/screens/sale_details_screen.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  int _tabIndex = 0;

  final _serialInputController = TextEditingController();
  final _pendingSerials = <String>[];
  DateTime _stockDate = DateTime.now();
  bool _isStockSubmitting = false;
  bool _isEditing = false;
  int _addQty = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductById(widget.productId);
    });
  }

  @override
  void dispose() {
    _serialInputController.dispose();
    super.dispose();
  }

  void _addPendingSerial() async {
    final s = _serialInputController.text.trim();
    if (s.isEmpty) return;
    if (_pendingSerials.contains(s)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serial already added in this form')),
        );
      }
      return;
    }
    final provider = context.read<ProductProvider>();
    final duplicate = await provider.checkDuplicateSerial(s);
    if (duplicate != null && mounted) {
      _showSerialExistsPopup(context, duplicate);
      return;
    }
    setState(() {
      _pendingSerials.add(s);
      _serialInputController.clear();
    });
  }

  void _showSerialExistsPopup(BuildContext ctx, DuplicateSerialInfo dup) {
    final isSold = dup.status == 'sold';
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('Serial Already in Stock')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dup.existingProductName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text('S/N: ${dup.serialNumber}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 2),
            Text('Model: ${dup.existingProductModel}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSold
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isSold ? 'SOLD' : 'Available in Stock',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSold ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(
                      productId: dup.existingProductId),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('View Product'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _removePendingSerial(int index) {
    setState(() {
      _pendingSerials.removeAt(index);
    });
  }

  Future<void> _scanAndAddSerial() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null && result.trim().isNotEmpty) {
      if (!mounted) return;
      if (_pendingSerials.contains(result.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serial already added in this form')),
        );
        return;
      }
      final provider = context.read<ProductProvider>();
      final duplicate = await provider.checkDuplicateSerial(result);
      if (duplicate != null && mounted) {
        _showSerialExistsPopup(context, duplicate);
        return;
      }
      setState(() {
        _pendingSerials.add(result.trim());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          _tabIndex == 0 ? 'Edit Product' : 'Add Stock',
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Edit Details', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                  icon: Icon(Icons.edit_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Add Stock', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                  icon: Icon(Icons.inventory_2_outlined, size: 16),
                ),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (v) => setState(() => _tabIndex = v.first),
              style: SegmentedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerLow,
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: Colors.white,
                foregroundColor: AppColors.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedProduct == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.selectedProduct == null) {
            return const Center(
              child: Text(
                'Product not found',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.error,
                ),
              ),
            );
          }

          if (_tabIndex == 0) {
            return ProductForm(
              product: provider.selectedProduct,
              isEdit: true,
              hideSerials: true,
              onSave: (Product product, List<String> serialNumbers, {DateTime? stockDate}) {
                return _handleEditSave(context, product, symbol);
              },
            );
          }

          return _buildAddStockTab(context, provider, symbol);
        },
      ),
    );
  }

  Widget _buildAddStockTab(BuildContext context, ProductProvider provider, String symbol) {
    final product = provider.selectedProduct!;
    final isSerialized = product.isSerialized;
    final serialCount = _pendingSerials.length;
    final addQty = isSerialized ? serialCount : _addQty;
    final purchasePrice = product.purchasePrice;
    final sellingPrice = product.sellingPrice;
    final totalPurchase = addQty * purchasePrice;
    final totalSelling = addQty * sellingPrice;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.productName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      'Current stock: ${product.availableQuantity} available',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Stock Date: ', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _stockDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _stockDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_stockDate),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          isSerialized ? _buildSerialInput() : _buildQuantityInput(),
          if (addQty > 0) ...[
            const SizedBox(height: 16),
            _buildStockSummary(symbol, addQty, purchasePrice, sellingPrice,
                totalPurchase, totalSelling),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isStockSubmitting
                    ? null
                    : () => _handleAddStock(context, provider, symbol),
                icon: _isStockSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(
                  _isStockSubmitting
                      ? 'Saving...'
                      : 'Add $addQty ${isSerialized ? 'Serial${addQty == 1 ? "" : "s"}' : "unit${addQty == 1 ? "" : "s"}"}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSerialInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Serial Number',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _serialInputController,
                decoration: InputDecoration(
                  hintText: 'Type or scan serial number',
                  hintStyle: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.onSurface),
                onSubmitted: (_) => _addPendingSerial(),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: _scanAndAddSerial,
              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 22),
              tooltip: 'Scan & add',
            ),
            FilledButton.tonalIcon(
              onPressed: _addPendingSerial,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        if (_pendingSerials.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Pending Serials',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              )),
          const SizedBox(height: 8),
          ...List.generate(_pendingSerials.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_pendingSerials[i],
                          style: const TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.onSurface)),
                    ),
                    GestureDetector(
                      onTap: () => _removePendingSerial(i),
                      child: const Icon(Icons.close, size: 16, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildQuantityInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quantity',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: _addQty > 1
                    ? () => setState(() => _addQty--)
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_addQty',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => setState(() => _addQty++),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockSummary(String symbol, int count, double purchasePrice,
      double sellingPrice, double totalPurchase, double totalSelling) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Summary',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              )),
          const SizedBox(height: 10),
          _summaryRow('Total Items', '$count unit${count == 1 ? '' : 's'}'),
          _summaryRow('Purchase Total', '$symbol${totalPurchase.toStringAsFixed(0)}'),
          _summaryRow('Selling Total', '$symbol${totalSelling.toStringAsFixed(0)}'),
          const Divider(height: 18),
          _summaryRow('Est. Profit', '$symbol${(totalSelling - totalPurchase).toStringAsFixed(0)}',
              valueColor: AppColors.success),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              )),
          Text(value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.onSurface,
              )),
        ],
      ),
    );
  }

  Future<void> _handleEditSave(
      BuildContext context, Product product, String symbol) async {
    if (_isEditing) return;
    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.canWrite()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please connect to save.')),
      );
      return;
    }
    setState(() => _isEditing = true);
    try {
      final provider = context.read<ProductProvider>();
      await provider.updateProduct(product);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isEditing = false);
    }
  }

  Future<void> _handleAddStock(
      BuildContext context, ProductProvider provider, String symbol) async {
    if (_isStockSubmitting) return;
    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.canWrite()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please connect to add stock.')),
      );
      return;
    }
    final product = provider.selectedProduct!;

    if (product.isSerialized) {
      if (_pendingSerials.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one serial number is required')),
        );
        return;
      }
    } else {
      if (_addQty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantity must be greater than 0')),
        );
        return;
      }
    }

    setState(() => _isStockSubmitting = true);
    try {
      if (product.isSerialized) {
        await provider.addSerialNumbers(widget.productId, _pendingSerials, stockDate: _stockDate);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_pendingSerials.length} serial(s) added successfully')),
          );
          _serialInputController.clear();
          _pendingSerials.clear();
          if (mounted) setState(() {});
        }
      } else {
        await provider.addQuantity(widget.productId, _addQty, stockDate: _stockDate);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$_addQty unit(s) added successfully')),
          );
          if (mounted) setState(() => _addQty = 1);
        }
      }
    } on DuplicateSerialException catch (e) {
      if (context.mounted) {
        _showDuplicateDialog(context, e.duplicates, symbol);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add stock: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStockSubmitting = false);
    }
  }

  void _showDuplicateDialog(
      BuildContext context, List<DuplicateSerialInfo> duplicates, String symbol) {
    final currencyFormat = NumberFormat.currency(symbol: symbol, decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('Serial Already Exists')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: duplicates.map((dup) {
              final isSold = dup.status == 'sold';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Debounced(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (isSold && dup.saleId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SaleDetailsScreen(saleId: dup.saleId!),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(
                              productId: dup.existingProductId),
                        ),
                      );
                    }
                  },
                  builder: (context, isDisabled) => InkWell(
                    onTap: isDisabled ? null : () {
                      Navigator.pop(ctx);
                      if (isSold && dup.saleId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SaleDetailsScreen(saleId: dup.saleId!),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsScreen(
                                productId: dup.existingProductId),
                          ),
                        );
                      }
                    },
                    child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(dup.existingProductName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            Icon(Icons.open_in_new,
                                size: 14, color: AppColors.textSecondary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('S/N: ${dup.serialNumber}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('Model: ${dup.existingProductModel}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('Added: ${dateFormat.format(dup.createdAt)}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSold
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSold ? 'SOLD' : 'Available',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSold ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                        if (isSold) ...[
                          const SizedBox(height: 6),
                          if (dup.saleDate != null)
                            _detailRow(Icons.calendar_today,
                                'Sold: ${dateFormat.format(dup.saleDate!)}'),
                          if (dup.customerName != null &&
                              dup.customerName!.isNotEmpty)
                            _detailRow(Icons.person, 'Customer: ${dup.customerName}'),
                          if (dup.salePrice != null)
                            _detailRow(Icons.payments,
                                'Price: ${currencyFormat.format(dup.salePrice)}'),
                          if (dup.saleId != null)
                            Text('Tap to view sale details',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ),
                  ),
              );
            }).toList(),
          ),
        ),
        actions: [
          Debounced(
            onPressed: () => Navigator.pop(ctx),
            builder: (_, isDisabled) => TextButton(
              onPressed: isDisabled ? null : () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
