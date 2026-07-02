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
    return _cartItems.fold(0.0, (sum, item) => sum + item.product.sellingPrice * item.serials.length);
  }

  int get _totalItems {
    return _cartItems.fold(0, (sum, item) => sum + item.serials.length);
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

    setState(() => _isSubmitting = true);

    final saleProvider = context.read<SaleProvider>();
    final items = _cartItems.map((item) {
      final serialNumbers = item.serials.map((s) => {
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
      }).toList();
      return serialNumbers;
    }).expand((x) => x).toList();

    try {
      final customerName = _customerNameController.text.trim();
      final customerPhone = _customerPhoneController.text.trim();
      await saleProvider.bulkCreateSales(
        items: items,
        customerId: '',
        customerName: customerName.isEmpty ? 'Customer${Random().nextInt(900000) + 100000}' : customerName,
        customerPhone: customerPhone.isEmpty ? 'N/A' : customerPhone,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale completed successfully')),
        );
        widget.onSaleComplete();
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

    var salePriceText = product.sellingPrice.toStringAsFixed(2);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PriceDialog(
        productName: product.productName,
        serialNumber: serialNumber,
        modelNumber: product.modelNumber,
        initialPrice: product.sellingPrice.toStringAsFixed(2),
        onPriceChanged: (v) => salePriceText = v,
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final salePrice = double.tryParse(salePriceText) ?? product.sellingPrice;
    _scannedSerialNumbers.add(serialNumber);
    setState(() {
      final existingIndex = _cartItems.indexWhere((i) => i.product.id == product.id);
      final serial = SerialNumber(id: serialId, productId: product.id, serialNumber: serialNumber, status: 'available');
      final cartProduct = product.copyWith(sellingPrice: salePrice);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].serials.add(serial);
      } else {
        _cartItems.add(_CartItem(product: cartProduct, serials: [serial]));
      }
    });
    if (mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text('Added ${product.productName} - $serialNumber')));
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: context.read<CategoryProvider>(),
        child: ChangeNotifierProvider.value(
          value: context.read<ProductProvider>(),
          child: _AddItemSheet(onAddToCart: (product, serials) {
            setState(() {
              final existingIndex = _cartItems.indexWhere((i) => i.product.id == product.id);
              if (existingIndex >= 0) {
                _cartItems[existingIndex].serials.addAll(serials);
              } else {
                _cartItems.add(_CartItem(product: product, serials: serials));
              }
            });
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTopBar(isDark),
          Expanded(
            child: _currentPage == 0 ? _buildCustomerStep(isDark) : _buildCartStep(isDark),
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
            onTap: () => Navigator.pop(context),
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

  Widget _buildCartStep(bool isDark) {
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
                  onRemove: () {
                    setState(() {
                      _scannedSerialNumbers.removeAll(item.serials.map((s) => s.serialNumber));
                      _cartItems.removeAt(index);
                    });
                  },
                );
              },
            ),
          ),
        if (_cartItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(80))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_totalItems items', style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
                      Text('\$${_cartTotal.toStringAsFixed(2)}',
                          style: AppTextStyles.amountLg.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E), fontSize: 24)),
                    ],
                  ),
                ),
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
  final VoidCallback onRemove;

  const _CartItemTile({required this.item, required this.isDark, required this.onRemove});

  @override
  Widget build(BuildContext context) {
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
                onTap: onRemove,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_rounded, size: 16, color: AppColors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...item.serials.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(s.serialNumber, style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
                const Spacer(),
                Text('\$${item.product.sellingPrice.toStringAsFixed(0)}',
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ],
            ),
          )),
          if (item.serials.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${item.serials.length} items × \$${item.product.sellingPrice.toStringAsFixed(0)}',
                  style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
            ),
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

  const _PriceDialog({
    required this.productName,
    required this.serialNumber,
    required this.modelNumber,
    required this.initialPrice,
    required this.onPriceChanged,
  });

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrice);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Sale Price',
                prefixText: '\$ ',
                prefixStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: widget.onPriceChanged,
              style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 20),
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
                    onPressed: () {
                      widget.onPriceChanged(_controller.text);
                      Navigator.pop(context, true);
                    },
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
  _CartItem({required this.product, required this.serials});
}

class _AddItemSheet extends StatefulWidget {
  final void Function(Product product, List<SerialNumber> serials) onAddToCart;
  const _AddItemSheet({required this.onAddToCart});

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
  String _warrantyUnit = 'month';
  bool _noWarranty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _salePriceController.dispose();
    _warrantyValueController.dispose();
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
    final categoryProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Item to Cart', style: AppTextStyles.headlineMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.close_rounded, size: 18)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(label: 'All', selected: _categoryId == null, isDark: isDark, onTap: () {
                  setState(() { _categoryId = null; _productId = null; _product = null; _selectedSerialIds.clear(); _serialNumbers = []; });
                }),
                const SizedBox(width: 8),
                ...categoryProvider.categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CategoryChip(
                    label: cat.name,
                    selected: _categoryId == cat.id,
                    isDark: isDark,
                    onTap: () {
                      setState(() { _categoryId = cat.id; _productId = null; _product = null; _selectedSerialIds.clear(); _serialNumbers = []; });
                      context.read<ProductProvider>().loadProducts(categoryId: cat.id);
                    },
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: products.isEmpty
                ? Center(child: Text('No products in this category', style: AppTextStyles.bodyMd.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...products.map((p) {
                        final selected = _productId == p.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary.withAlpha(12) : (isDark ? AppColors.surfaceLight : const Color(0xFFF9FAFB)).withAlpha(180),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? AppColors.primary.withAlpha(80) : (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60),
                              width: selected ? 1.5 : 0.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _productId = p.id;
                                _product = p;
                                _selectedSerialIds.clear();
                                _salePriceController.text = p.sellingPrice.toStringAsFixed(2);
                                _setWarrantyFromProduct(p);
                              });
                              context.read<SaleProvider>().loadAvailableSerialNumbers(p.id);
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
                                              errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_rounded, size: 22, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))))
                                        : Icon(Icons.inventory_2_rounded, size: 22, color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.productName, style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text('${p.brandName} ${p.modelNumber}',
                                            style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
                                        const SizedBox(height: 4),
                                        Text('\$${p.sellingPrice.toStringAsFixed(2)}',
                                            style: AppTextStyles.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                                      child: const Icon(Icons.check_rounded, size: 16, color: Colors.black),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_productId != null && _product != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.surfaceLight : const Color(0xFFF9FAFB)).withAlpha(180),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60), width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _salePriceController,
                                      decoration: InputDecoration(
                                        labelText: 'Price',
                                        prefixText: '\$ ',
                                        prefixStyle: TextStyle(fontFamily: 'Inter', fontSize: 14, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
                                        filled: true,
                                        fillColor: isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6),
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
                                        fillColor: isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6),
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
                                      color: isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6),
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
                              const SizedBox(height: 12),
                              Text('Select Serial Numbers', style: AppTextStyles.labelMd.copyWith(color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
                              const SizedBox(height: 8),
                              _buildSerialCheckboxList(isDark),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text('${_selectedSerialIds.length} selected',
                                      style: AppTextStyles.labelSm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
                                  const Spacer(),
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
                                    child: const Text('Add to Cart'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialCheckboxList(bool isDark) {
    final saleProvider = context.watch<SaleProvider>();
    final serials = saleProvider.availableSerialNumbers;

    if (saleProvider.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }

    if (serials.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text('No available serial numbers', style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted))),
      );
    }

    _serialNumbers = serials;

    return Container(
      constraints: const BoxConstraints(maxHeight: 100),
      child: ListView(
        children: serials.map((sn) => CheckboxListTile(
          title: Text(sn.serialNumber, style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
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
        )).toList(),
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
