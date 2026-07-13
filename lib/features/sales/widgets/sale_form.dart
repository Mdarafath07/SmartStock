import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/products/models/product_model.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/products/widgets/barcode_scanner_screen.dart';
import 'package:smartstock/features/sales/providers/sale_provider.dart';
import 'package:smartstock/features/sales/models/serial_number_model.dart';
import 'package:smartstock/features/sales/widgets/sale_receipt.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class SaleForm extends StatefulWidget {
  final VoidCallback onSaleComplete;
  const SaleForm({super.key, required this.onSaleComplete});

  @override
  State<SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends State<SaleForm> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerNameFocus = FocusNode();
  final _customerPhoneFocus = FocusNode();
  bool _isSubmitting = false;
  int _currentPage = 0;

  final List<_CartItem> _cartItems = [];
  final Set<String> _scannedSerialNumbers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerNameFocus.dispose();
    _customerPhoneFocus.dispose();
    super.dispose();
  }

  double get _cartTotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.itemTotal);
  }

  int get _totalItems {
    return _cartItems.fold(0, (sum, item) => sum + item.itemCount);
  }

  Future<void> _submitSale() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to the cart')),
      );
      return;
    }

    final productProvider = context.read<ProductProvider>();
    for (final item in _cartItems) {
      if (item.isSerialized) {
        for (final serial in item.serials) {
          final current = await productProvider.checkSerialAvailability(serial.serialNumber);
          if (current != null && current != 'available') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${serial.serialNumber} is no longer available')),
              );
            }
            return;
          }
        }
      } else {
        final freshProduct = await productProvider.getFreshProduct(item.product.id);
        if (freshProduct != null && freshProduct.availableQuantity < item.quantity) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Insufficient stock for ${item.product.productName}. Available: ${freshProduct.availableQuantity}')),
            );
          }
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    final saleProvider = context.read<SaleProvider>();
    final items = _cartItems.expand((item) {
      if (item.isSerialized) {
        return item.serials.map((s) => {
          'serialNumberId': s.id,
          'serialNumber': s.serialNumber,
          'productId': item.product.id,
          'productName': item.product.productName,
          'modelNumber': item.product.modelNumber,
          'imageUrl': item.product.imageUrl,
          'categoryId': item.product.categoryId,
          'categoryName': item.product.categoryName,
          'salePrice': item.product.sellingPrice,
          'purchasePrice': item.product.purchasePrice,
          'warrantyExpiryDate': DateTime.now().add(Duration(days: item.product.warrantyMonths * 30)),
          'warrantyMonths': item.product.warrantyMonths,
          'quantity': 1,
        }).toList();
      } else {
        return [{
          'serialNumberId': '',
          'serialNumber': '',
          'productId': item.product.id,
          'productName': item.product.productName,
          'modelNumber': item.product.modelNumber,
          'imageUrl': item.product.imageUrl,
          'categoryId': item.product.categoryId,
          'categoryName': item.product.categoryName,
          'salePrice': item.product.sellingPrice,
          'purchasePrice': item.product.purchasePrice,
          'warrantyExpiryDate': DateTime.now(),
          'warrantyMonths': 0,
          'quantity': item.quantity,
        }];
      }
    }).toList();

    try {
      final customerName = _customerNameController.text.trim();
      final customerPhone = _customerPhoneController.text.trim();
      final finalCustomerName = customerName.isEmpty ? 'Customer${Random().nextInt(900000) + 100000}' : customerName;
      final finalCustomerPhone = customerPhone.isEmpty ? 'N/A' : customerPhone;
      await saleProvider.bulkCreateSales(
        items: items,
        customerId: '',
        customerName: finalCustomerName,
        customerPhone: finalCustomerPhone,
      );
      if (mounted) {
        _showReceipt(finalCustomerName, finalCustomerPhone, items);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete sale: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showReceipt(String customerName, String customerPhone, List<Map<String, dynamic>> items) {
    showSaleReceipt(
      context,
      customerName: customerName,
      customerPhone: customerPhone,
      items: items.map((i) => ReceiptItem(
        productName: i['productName'] as String,
        modelNumber: i['modelNumber'] as String,
        serialNumber: i['serialNumber'] as String? ?? '',
        price: i['salePrice'] as double,
        warrantyMonths: i['warrantyMonths'] as int? ?? 0,
        warrantyExpiry: i['warrantyExpiryDate'] as DateTime? ?? DateTime.now(),
        saleDate: DateTime.now(),
        quantity: i['quantity'] as int? ?? 1,
      )).toList(),
      onDone: widget.onSaleComplete,
    );
  }

  Future<void> _handleBarcodeScan() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<ProductProvider>();
    final code = await Navigator.push<String>(
      context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || code.isEmpty) return;
    if (!mounted) return;

    final result = await provider.findProductBySerialNumber(code);
    if (result == null) {
      if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('No product found for "$code"')));
      return;
    }

    final (product, serialData) = result;

    if (!product.isSerialized) {
      if (mounted) scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Cannot scan serial for quantity-based products. Add manually.')));
      return;
    }
    final serialId = serialData['id'] as String;
    final serialNumber = serialData['serialNumber'] as String;

    if (serialData['status'] != 'available') {
      if (mounted) scaffoldMessenger.showSnackBar(const SnackBar(content: Text('This serial number is already sold')));
      return;
    }
    if (_scannedSerialNumbers.contains(serialNumber)) {
      if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('$serialNumber is already in cart')));
      return;
    }

    final cartCount = _cartItems.where((item) => item.product.id == product.id).fold<int>(0, (sum, item) => sum + item.serials.length);
    final remaining = product.availableQuantity - cartCount;
    if (remaining <= 0) {
      if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('No more stock available for ${product.productName}')));
      return;
    }
    if (!mounted) return;

    var salePriceText = product.sellingPrice.toStringAsFixed(0);
    var warrantyValueText = (product.warrantyMonths > 0)
        ? product.warrantyMonths.toString()
        : (product.warrantyDays > 0 ? product.warrantyDays.toString() : '0');
    var warrantyUnit = (product.warrantyMonths > 0)
        ? 'month'
        : (product.warrantyDays > 0 ? 'day' : 'month');
    var noWarranty = product.warrantyMonths == 0 && product.warrantyDays == 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PriceDialog(
        productName: product.productName,
        serialNumber: serialNumber,
        modelNumber: product.modelNumber,
        initialPrice: product.sellingPrice.toStringAsFixed(0),
        onPriceChanged: (v) => salePriceText = v,
        initialWarrantyValue: warrantyValueText,
        initialWarrantyUnit: warrantyUnit,
        initialNoWarranty: noWarranty,
        onWarrantyValueChanged: (v) => warrantyValueText = v,
        onWarrantyUnitChanged: (v) => warrantyUnit = v,
        onNoWarrantyChanged: (v) => noWarranty = v,
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final salePrice = double.tryParse(salePriceText) ?? product.sellingPrice;

    int warrantyMonths;
    if (noWarranty) {
      warrantyMonths = 0;
    } else {
      final value = int.tryParse(warrantyValueText) ?? 0;
      warrantyMonths = switch (warrantyUnit) {
        'day' => (value / 30).ceil(),
        'year' => value * 12,
        _ => value,
      };
    }

    setState(() {
      _scannedSerialNumbers.add(serialNumber);
      final existingIndex = _cartItems.indexWhere((i) => i.product.id == product.id);
      final serial = SerialNumber(id: serialId, productId: product.id, serialNumber: serialNumber, status: 'available');
      final cartProduct = product.copyWith(sellingPrice: salePrice, warrantyMonths: warrantyMonths);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].serials.add(serial);
      } else {
        _cartItems.add(_CartItem(product: cartProduct, serials: [serial]));
      }
    });
    if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('Added ${product.productName} - $serialNumber')));
  }

  void _showAddItemSheet() {
    final cartItemQtys = {for (final item in _cartItems) item.product.id: item.quantity};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: context.read<CategoryProvider>(),
        child: ChangeNotifierProvider.value(
          value: context.read<ProductProvider>(),
          child: _AddItemSheet(
            onAddToCart: (product, serials) {
              setState(() {
                final existingIndex = _cartItems.indexWhere((i) => i.product.id == product.id);
                if (existingIndex >= 0) {
                  _cartItems[existingIndex].serials.addAll(serials);
                } else {
                  _cartItems.add(_CartItem(product: product, serials: serials));
                }
              });
            },
            onAddQuantityProduct: (product, quantity) {
              setState(() {
                final existingIndex = _cartItems.indexWhere((i) => i.product.id == product.id);
                if (existingIndex >= 0) {
                  _cartItems[existingIndex].quantity += quantity;
                } else {
                  _cartItems.add(_CartItem(product: product, serials: [], quantity: quantity));
                }
              });
            },
            onBarcodeScan: _handleBarcodeScan,
            cartItemQtys: cartItemQtys,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final symbol = context.watch<SettingsProvider>().currencySymbol;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTopBar(isDark),
          Expanded(
            child: _currentPage == 0 ? _buildCustomerStep(isDark) : _buildCartStep(isDark, symbol),
          ),
          _buildBottomBar(isDark),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Sale', style: AppTextStyles.headlineMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                Text(_currentPage == 0 ? 'Customer Information' : 'Cart Review',
                    style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.salesHistory),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.history_rounded, size: 20),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildCustomerStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Details', style: AppTextStyles.titleMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          Text('Enter customer information for the sale',
              style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceLight : const Color(0xFFF9FAFB)).withAlpha(200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _customerNameController,
                  focusNode: _customerNameFocus,
                  decoration: InputDecoration(
                    hintText: 'Customer Name',
                    prefixIcon: Icon(Icons.person_rounded, size: 20, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _customerPhoneFocus.requestFocus(),
                ),
                Divider(height: 1, color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(80)),
                TextFormField(
                  controller: _customerPhoneController,
                  focusNode: _customerPhoneFocus,
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_rounded, size: 20, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartStep(bool isDark, String symbol) {
    return Column(
      children: [
        if (_cartItems.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.shopping_cart_rounded, size: 32, color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB)),
                  ),
                  const SizedBox(height: 16),
                  Text('Cart is empty', style: AppTextStyles.headlineSm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  Text('Add items to start a sale', style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _showAddItemSheet,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return _CartItemTile(
                  item: item,
                  isDark: isDark,
                  onRemoveSerial: (serial) {
                    setState(() {
                      _scannedSerialNumbers.remove(serial.serialNumber);
                      item.serials.remove(serial);
                      if (item.serials.isEmpty) {
                        _cartItems.removeAt(index);
                      }
                    });
                  },
                  onRemoveAll: () {
                    setState(() {
                      _scannedSerialNumbers.removeAll(item.serials.map((s) => s.serialNumber));
                      _cartItems.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(80))),
          ),
          child: Row(
            children: [
              if (_cartItems.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_totalItems items', style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
                      Text('$symbol${_cartTotal.toStringAsFixed(0)}',
                          style: AppTextStyles.amountLg.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E), fontSize: 24)),
                    ],
                  ),
                ),
              if (_cartItems.isEmpty)
                const Spacer(),
              FilledButton.icon(
                onPressed: _showAddItemSheet,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6),
                  foregroundColor: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _handleBarcodeScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(80))),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentPage--),
                child: const Text('Back'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isSubmitting ? null : () {
                if (_currentPage == 0) {
                  setState(() => _currentPage = 1);
                } else {
                  _submitSale();
                }
              },
              child: _isSubmitting && _currentPage == 1
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_currentPage == 1 ? 'Complete Sale' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final _CartItem item;
  final bool isDark;
  final void Function(SerialNumber) onRemoveSerial;
  final VoidCallback onRemoveAll;

  const _CartItemTile({
    required this.item,
    required this.isDark,
    required this.onRemoveSerial,
    required this.onRemoveAll,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.cardDark : Colors.white).withAlpha(200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.product.productName, style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
              ),
              GestureDetector(
                onTap: onRemoveAll,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_rounded, size: 16, color: AppColors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (item.isSerialized) ...[
            ...item.serials.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.serialNumber, style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
                  ),
                  Text('$symbol${item.product.sellingPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onRemoveSerial(s),
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.close_rounded, size: 14, color: AppColors.red),
                    ),
                  ),
                ],
              ),
            )),
            if (item.serials.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${item.serials.length} items × $symbol${item.product.sellingPrice.toStringAsFixed(0)}',
                    style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
              ),
          ] else ...[
            Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Quantity: ${item.quantity}', style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
                ),
                Text('$symbol${item.product.sellingPrice.toStringAsFixed(0)} × ${item.quantity}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceDialog extends StatefulWidget {
  final String productName;
  final String serialNumber;
  final String modelNumber;
  final String initialPrice;
  final ValueChanged<String> onPriceChanged;
  final String initialWarrantyValue;
  final String initialWarrantyUnit;
  final bool initialNoWarranty;
  final ValueChanged<String> onWarrantyValueChanged;
  final ValueChanged<String> onWarrantyUnitChanged;
  final ValueChanged<bool> onNoWarrantyChanged;

  const _PriceDialog({
    required this.productName,
    required this.serialNumber,
    required this.modelNumber,
    required this.initialPrice,
    required this.onPriceChanged,
    required this.initialWarrantyValue,
    required this.initialWarrantyUnit,
    required this.initialNoWarranty,
    required this.onWarrantyValueChanged,
    required this.onWarrantyUnitChanged,
    required this.onNoWarrantyChanged,
  });

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final TextEditingController _priceController;
  late final TextEditingController _warrantyController;
  late String _warrantyUnit;
  late bool _noWarranty;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.initialPrice);
    _warrantyController = TextEditingController(text: widget.initialWarrantyValue);
    _warrantyUnit = widget.initialWarrantyUnit;
    _noWarranty = widget.initialNoWarranty;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _warrantyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.productName, style: AppTextStyles.titleMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text('Serial: ${widget.serialNumber} · Model: ${widget.modelNumber}',
                style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Sale Price',
                prefixText: '$symbol ',
                prefixStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: widget.onPriceChanged,
              style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _warrantyController,
                    readOnly: _noWarranty,
                    decoration: InputDecoration(
                      labelText: _noWarranty ? 'No Warranty' : 'Warranty',
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    keyboardType: _noWarranty ? TextInputType.none : TextInputType.number,
                    onChanged: widget.onWarrantyValueChanged,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _warrantyUnit,
                      isDense: true,
                      onChanged: _noWarranty ? null : (v) {
                        if (v != null) {
                          setState(() => _warrantyUnit = v);
                          widget.onWarrantyUnitChanged(v);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'day', child: Text('Day(s)', style: TextStyle(fontFamily: 'Geist', fontSize: 12))),
                        DropdownMenuItem(value: 'month', child: Text('Month(s)', style: TextStyle(fontFamily: 'Geist', fontSize: 12))),
                        DropdownMenuItem(value: 'year', child: Text('Year(s)', style: TextStyle(fontFamily: 'Geist', fontSize: 12))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  child: Checkbox(
                    value: _noWarranty,
                    onChanged: (v) {
                      setState(() => _noWarranty = v ?? false);
                      widget.onNoWarrantyChanged(v ?? false);
                    },
                    activeColor: AppColors.primary,
                    checkColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() => _noWarranty = !_noWarranty);
                    widget.onNoWarrantyChanged(!_noWarranty);
                  },
                  child: Text('No warranty', style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItem {
  final Product product;
  final List<SerialNumber> serials;
  int quantity;
  _CartItem({required this.product, required this.serials, this.quantity = 1});

  bool get isSerialized => product.isSerialized;
  int get itemCount => isSerialized ? serials.length : quantity;

  double get itemTotal => isSerialized
      ? product.sellingPrice * serials.length
      : product.sellingPrice * quantity;
}

class _AddItemSheet extends StatefulWidget {
  final void Function(Product product, List<SerialNumber> serials) onAddToCart;
  final void Function(Product product, int quantity) onAddQuantityProduct;
  final VoidCallback? onBarcodeScan;
  final Map<String, int> cartItemQtys;
  const _AddItemSheet({
    required this.onAddToCart,
    required this.onAddQuantityProduct,
    this.onBarcodeScan,
    required this.cartItemQtys,
  });

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  String? _categoryId;
  String? _productId;
  Product? _product;
  final Set<String> _selectedSerialIds = {};
  List<SerialNumber> _serialNumbers = [];
  final _salePriceController = TextEditingController();
  final _warrantyValueController = TextEditingController(text: '1');
  final _serialSearchController = TextEditingController();
  String _warrantyUnit = 'month';
  bool _noWarranty = false;
  String _serialQuery = '';
  Product? _serialSearchedProduct;
  Timer? _serialSearchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
    _serialSearchController.addListener(() {
      setState(() => _serialQuery = _serialSearchController.text.trim().toLowerCase());
      _debounceSerialLookup();
    });
  }

  void _debounceSerialLookup() {
    _serialSearchDebounce?.cancel();
    final query = _serialSearchController.text.trim();
    if (query.isEmpty || _productId != null) {
      setState(() => _serialSearchedProduct = null);
      return;
    }
    _serialSearchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final result = await context.read<ProductProvider>().findProductBySerialNumber(query);
      if (mounted) setState(() => _serialSearchedProduct = result?.$1);
    });
  }

  @override
  void dispose() {
    _salePriceController.dispose();
    _warrantyValueController.dispose();
    _serialSearchController.dispose();
    _serialSearchDebounce?.cancel();
    super.dispose();
  }

  int _parseWarrantyMonths() {
    final value = int.tryParse(_warrantyValueController.text) ?? 0;
    return switch (_warrantyUnit) {
      'day' => (value / 30).ceil(),
      'year' => value * 12,
      _ => value,
    };
  }

  void _setWarrantyFromProduct(Product p) {
    if (p.warrantyMonths > 0) {
      _warrantyValueController.text = p.warrantyMonths.toString();
      _warrantyUnit = 'month';
      _noWarranty = false;
    } else if (p.warrantyDays > 0) {
      _warrantyValueController.text = p.warrantyDays.toString();
      _warrantyUnit = 'day';
      _noWarranty = false;
    } else {
      _warrantyValueController.text = '0';
      _warrantyUnit = 'month';
      _noWarranty = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final categoryProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Add Item', style: AppTextStyles.headlineMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 36,
                      child: TextField(
                        controller: _serialSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search serial...',
                          prefixIcon: Icon(Icons.search_rounded, size: 16, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          isDense: true,
                        ),
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (widget.onBarcodeScan != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onBarcodeScan!();
                        },
                        child: Container(width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: AppColors.primary)),
                      ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.close_rounded, size: 18)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(label: 'All', selected: _categoryId == null, isDark: isDark, onTap: () {
                  setState(() { _categoryId = null; _productId = null; _product = null; _selectedSerialIds.clear(); _serialNumbers = []; _serialSearchedProduct = null; });
                  context.read<ProductProvider>().loadProducts();
                }),
                const SizedBox(width: 8),
                ...categoryProvider.categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CategoryChip(
                    label: cat.name,
                    selected: _categoryId == cat.id,
                    isDark: isDark,
                    onTap: () {
                      setState(() { _categoryId = cat.id; _productId = null; _product = null; _selectedSerialIds.clear(); _serialNumbers = []; _serialSearchedProduct = null; });
                      context.read<ProductProvider>().loadProducts(categoryId: cat.id);
                    },
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _productId == null
                ? _buildProductList(products.where((p) => p.availableQuantity > 0).toList(), isDark, symbol)
                : _buildSerialSelection(isDark, symbol),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              border: Border(top: BorderSide(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(80))),
            ),
            child: Row(
              children: [
                if (_productId != null)
                  GestureDetector(
                    onTap: () => setState(() { _productId = null; _product = null; _selectedSerialIds.clear(); _serialNumbers = []; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 16, color: isDark ? AppColors.textSecondary : const Color(0xFF475569)),
                          const SizedBox(width: 4),
                          Text('Back', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: isDark ? AppColors.textSecondary : const Color(0xFF475569))),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                if (_productId != null)
                  Text('${_selectedSerialIds.length} selected',
                      style: AppTextStyles.labelSm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _selectedSerialIds.isEmpty
                      ? null
                      : () {
                          final salePrice = double.tryParse(_salePriceController.text) ?? _product!.sellingPrice;
                          final warrantyMonths = _noWarranty ? 0 : _parseWarrantyMonths();
                          final product = _product!.copyWith(sellingPrice: salePrice, warrantyMonths: warrantyMonths);
                          widget.onAddToCart(product, _serialNumbers.where((s) => _selectedSerialIds.contains(s.id)).toList());
                          Navigator.pop(context);
                        },
                  child: Text('Add (${_selectedSerialIds.length})'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> products, bool isDark, String symbol) {
    List<Product> filtered;
    if (_serialQuery.isNotEmpty) {
      final nameModelMatch = products.where((p) =>
          p.productName.toLowerCase().contains(_serialQuery) ||
          p.modelNumber.toLowerCase().contains(_serialQuery)).toList();
      final matchedIds = nameModelMatch.map((p) => p.id).toSet();
      if (_serialSearchedProduct != null && !matchedIds.contains(_serialSearchedProduct!.id)) {
        nameModelMatch.add(_serialSearchedProduct!);
      }
      filtered = nameModelMatch;
    } else {
      filtered = products;
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _serialQuery.isNotEmpty ? 'No matching products' : 'Select a category to see products',
          style: AppTextStyles.bodyMd.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: filtered.map((p) {
        final inCart = widget.cartItemQtys.containsKey(p.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: inCart
                ? (isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFF3F4F6).withAlpha(200))
                : (isDark ? AppColors.surfaceLight : const Color(0xFFF9FAFB)).withAlpha(180),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60),
              width: 0.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: inCart
                ? null
                : () async {
                    if (p.isSerialized) {
                      setState(() {
                        _productId = p.id;
                        _product = p;
                        _selectedSerialIds.clear();
                        _salePriceController.text = p.sellingPrice.toStringAsFixed(0);
                        _setWarrantyFromProduct(p);
                      });
                      context.read<SaleProvider>().loadAvailableSerialNumbers(p.id);
                    } else {
                      final sym = context.read<SettingsProvider>().currencySymbol;
                      final inCartQty = widget.cartItemQtys[p.id] ?? 0;
                      final maxStock = p.availableQuantity - inCartQty;
                      if (maxStock <= 0) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No more stock available for ${p.productName}')),
                          );
                        }
                        return;
                      }
                      int selectedQty = 1;
                      final result = await showDialog<int>(
                        context: context,
                        builder: (ctx) {
                          return StatefulBuilder(
                            builder: (context, setDialogState) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                                titlePadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                title: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 40, height: 40,
                                        child: p.imageUrl.isNotEmpty
                                            ? Image.network(p.imageUrl, fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) => Container(color: const Color(0xFFE5E7EB), child: const Icon(Icons.inventory_2_rounded, size: 20, color: Color(0xFF9CA3AF))))
                                            : Container(color: const Color(0xFFE5E7EB), child: const Icon(Icons.inventory_2_rounded, size: 20, color: Color(0xFF9CA3AF))),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                          if (p.modelNumber.isNotEmpty)
                                            Text(p.modelNumber, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                content: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Stock', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                                          Text('$maxStock available', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Unit Price', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                                          Text('$sym${p.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Total: $sym${(p.sellingPrice * selectedQty).toStringAsFixed(0)}',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                                            Row(
                                              children: [
                                                _QtyButton(
                                                  icon: Icons.remove_rounded,
                                                  onTap: selectedQty > 1 ? () => setDialogState(() => selectedQty--) : null,
                                                ),
                                                SizedBox(
                                                  width: 40,
                                                  child: Text('$selectedQty', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                                                ),
                                                _QtyButton(
                                                  icon: Icons.add_rounded,
                                                  onTap: selectedQty < maxStock ? () => setDialogState(() => selectedQty++) : null,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, selectedQty),
                                    child: const Text('Add to Cart'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                      if (result != null && result > 0) {
                        widget.onAddQuantityProduct(p.copyWith(warrantyMonths: 0, warrantyDays: 0), result);
                        if (mounted) Navigator.pop(context);
                      }
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.greyDarker.withAlpha(100) : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: p.imageUrl.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(10),
                            child: Image.network(p.imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(Icons.inventory_2_rounded, size: 22, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))))
                        : Icon(Icons.inventory_2_rounded, size: 22, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(p.productName,
                                  style: AppTextStyles.titleSm.copyWith(
                                    color: inCart
                                        ? (isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))
                                        : (isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
                                  ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            if (inCart)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('In Cart',
                                    style: TextStyle(fontFamily: 'Geist', fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.green)),
                              ),
                          ],
                        ),
                        Text('${p.brandName} ${p.modelNumber}',
                            style: AppTextStyles.caption.copyWith(
                              color: inCart
                                  ? (isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB))
                                  : (isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                            )),
                        const SizedBox(height: 4),
                        Text('$symbol${p.sellingPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.labelMd.copyWith(
                              color: inCart ? AppColors.textMuted : AppColors.primary,
                              fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (inCart)
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    )
                  else
                    Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSerialSelection(bool isDark, String symbol) {
    final saleProvider = context.watch<SaleProvider>();
    final allSerials = saleProvider.availableSerialNumbers;

    if (_serialQuery.isNotEmpty) {
      final filteredSerials = allSerials.where((s) =>
        s.serialNumber.toLowerCase().contains(_serialQuery)).toList();
      if (_serialNumbers.length != filteredSerials.length ||
          !_serialNumbers.every((e) => filteredSerials.contains(e))) {
        _serialNumbers = filteredSerials;
      }
    } else if (_serialNumbers.length != allSerials.length ||
        !_serialNumbers.every((e) => allSerials.contains(e))) {
      _serialNumbers = allSerials;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [
        Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.greyDarker.withAlpha(100) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _product!.imageUrl.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(10),
                      child: Image.network(_product!.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(Icons.inventory_2_rounded, size: 22, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))))
                  : Icon(Icons.inventory_2_rounded, size: 22, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_product!.productName, style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${_product!.brandName} ${_product!.modelNumber}',
                      style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _salePriceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixText: '$symbol ',
                  prefixStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
                  filled: true,
                  fillColor: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _warrantyValueController,
                readOnly: _noWarranty,
                decoration: InputDecoration(
                  labelText: _noWarranty ? 'No Warranty' : 'Warranty',
                  filled: true,
                  fillColor: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                keyboardType: _noWarranty ? TextInputType.none : TextInputType.number,
                style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _warrantyUnit,
                  isDense: true,
                  onChanged: _noWarranty ? null : (v) { if (v != null) setState(() => _warrantyUnit = v); },
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Day(s)', style: TextStyle(fontFamily: 'Geist', fontSize: 12))),
                    DropdownMenuItem(value: 'month', child: Text('Month(s)', style: TextStyle(fontFamily: 'Geist', fontSize: 12))),
                    DropdownMenuItem(value: 'year', child: Text('Year(s)', style: TextStyle(fontFamily: 'Geist', fontSize: 12))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              height: 24,
              child: Checkbox(
                value: _noWarranty,
                onChanged: (v) => setState(() => _noWarranty = v ?? false),
                activeColor: AppColors.primary,
                checkColor: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => setState(() => _noWarranty = !_noWarranty),
              child: Text('No warranty', style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Serials (${_serialNumbers.length})', style: AppTextStyles.labelMd.copyWith(color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
        const SizedBox(height: 8),
        if (saleProvider.isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (_serialNumbers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Center(child: Text(
              _serialQuery.isNotEmpty ? 'No serials match your search' : 'No available serial numbers',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted))),
          )
        else
          ..._serialNumbers.map((sn) => CheckboxListTile(
            title: Text(sn.serialNumber, style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
            subtitle: Text('Serial #${sn.serialNumber}', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
            value: _selectedSerialIds.contains(sn.id),
            onChanged: (checked) {
              setState(() {
                if (checked == true) { _selectedSerialIds.add(sn.id); }
                else { _selectedSerialIds.remove(sn.id); }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            checkColor: Colors.black,
          )),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: onTap != null ? Colors.white : const Color(0xFF9CA3AF)),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(20) : (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(180),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary.withAlpha(80) : (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60),
            width: 0.5,
          ),
        ),
        child: Text(label, style: AppTextStyles.labelSm.copyWith(color: selected ? AppColors.primary : (isDark ? AppColors.textSecondary : const Color(0xFF6B7280)))),
      ),
    );
  }
}
