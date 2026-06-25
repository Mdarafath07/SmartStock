import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/products/models/product_model.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
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
  int _currentStep = 0;
  bool _isSubmitting = false;

  final List<_CartItem> _cartItems = [];

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
    return _cartItems.fold(
        0.0, (sum, item) => sum + item.product.sellingPrice * item.serials.length);
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
        'warrantyExpiryDate':
            DateTime.now().add(Duration(days: item.product.warrantyMonths * 30)),
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
        customerName: customerName.isEmpty
            ? 'Customer${Random().nextInt(900000) + 100000}'
            : customerName,
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

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ChangeNotifierProvider.value(
        value: context.read<CategoryProvider>(),
        child: ChangeNotifierProvider.value(
          value: context.read<ProductProvider>(),
          child: _AddItemSheet(
            onAddToCart: (product, serials) {
              setState(() {
                final existingIndex =
                    _cartItems.indexWhere((i) => i.product.id == product.id);
                if (existingIndex >= 0) {
                  _cartItems[existingIndex].serials.addAll(serials);
                } else {
                  _cartItems.add(_CartItem(product: product, serials: serials));
                }
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_formKey.currentState!.validate()) {
              setState(() => _currentStep = 1);
            }
          } else if (_currentStep == 1) {
            _submitSale();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: _isSubmitting ? null : details.onStepContinue,
                  child: _isSubmitting && _currentStep == 1
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_currentStep == 1 ? 'Complete Sale' : 'Next'),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Customer Information'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _customerNameController,
                  focusNode: _customerNameFocus,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      _customerPhoneFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customerPhoneController,
                  focusNode: _customerPhoneFocus,
                  decoration: const InputDecoration(
                    labelText: 'Customer Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Cart Items'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_cartItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No items added yet',
                          style: TextStyle(color: ColorConstants.onSurfaceVariant)),
                    ),
                  )
                else
                  ...List.generate(_cartItems.length, (index) {
                    final item = _cartItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.product.productName),
                        subtitle: Text(
                            '${item.serials.length} × \$${item.product.sellingPrice.toStringAsFixed(2)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: ColorConstants.error),
                          onPressed: () {
                            setState(() => _cartItems.removeAt(index));
                          },
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showAddItemSheet,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
                if (_cartItems.isNotEmpty) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('\$${_cartTotal.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
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
  String _warrantyUnit = 'year';

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

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 0,
        right: 0,
        top: 0,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Item to Cart',
                         style: AppTextStyles.titleMd.copyWith(
                             color: ColorConstants.onSurface)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select Category',
                    style: AppTextStyles.labelMd.copyWith(
                        color: ColorConstants.onSurfaceVariant)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...categoryProvider.categories.map((cat) {
                      final selected = _categoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _categoryId = cat.id;
                              _productId = null;
                              _product = null;
                              _selectedSerialIds.clear();
                              _serialNumbers = [];
                              _salePriceController.clear();
                              _warrantyValueController.text = '1';
                              _warrantyUnit = 'year';
                            });
                            context
                                .read<ProductProvider>()
                                .loadProducts(categoryId: cat.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? ColorConstants.primaryContainer
                                  : ColorConstants.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(24),
                              border: selected
                                  ? Border.all(
                                      color: ColorConstants.primary,
                                      width: 1.5)
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 18,
                                  color: selected
                                      ? ColorConstants.onPrimaryContainer
                                      : ColorConstants.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selected
                                        ? ColorConstants.onPrimaryContainer
                                        : ColorConstants.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_categoryId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Select Product',
                      style: AppTextStyles.labelMd.copyWith(
                          color: ColorConstants.onSurfaceVariant)),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Text('No products in this category',
                              style: AppTextStyles.bodyMd.copyWith(
                                  color: ColorConstants.onSurfaceVariant)))
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ...products.map((p) {
                              final selected = _productId == p.id;
                              final daysSince =
                                  DateTime.now().difference(p.createdAt).inDays;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _productId = p.id;
                                      _product = p;
                                      _selectedSerialIds.clear();
                                      _salePriceController.text =
                                          p.sellingPrice.toStringAsFixed(2);
                                    });
                                    context
                                        .read<SaleProvider>()
                                        .loadAvailableSerialNumbers(p.id);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? ColorConstants.primaryContainer
                                          : ColorConstants.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? ColorConstants.primary
                                            : ColorConstants.outlineVariant,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: SizedBox(
                                              width: 56,
                                              height: 56,
                                              child: p.imageUrl.isNotEmpty
                                                  ? Image.network(
                                                      p.imageUrl,
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (ctx, child, progress) {
                                                        if (progress == null) return child;
                                                        return _productPlaceholder();
                                                      },
                                                      errorBuilder: (_, _, _) =>
                                                          _productPlaceholder(),
                                                    )
                                                  : _productPlaceholder(),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.productName,
                                                  style: AppTextStyles.bodyMd.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: ColorConstants.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${p.brandName} ${p.modelNumber}',
                                                  style: AppTextStyles.labelMd.copyWith(
                                                    color: ColorConstants.onSurfaceVariant,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '\$${p.sellingPrice.toStringAsFixed(2)}',
                                                      style: AppTextStyles.labelMd.copyWith(
                                                        color: ColorConstants.primary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      daysSince == 0
                                                          ? 'today'
                                                          : '${daysSince}d ago',
                                                      style: AppTextStyles.labelSm.copyWith(
                                                        color: ColorConstants.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (selected)
                                            Icon(Icons.check_circle,
                                                color: ColorConstants.primary,
                                                size: 22),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            if (_productId != null && _product != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: TextFormField(
                                            controller:
                                                _salePriceController,
                                            decoration:
                                                const InputDecoration(
                                              labelText: 'Price',
                                              border:
                                                  OutlineInputBorder(),
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 12),
                                            ),
                                            keyboardType:
                                                TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 1,
                                          child: TextFormField(
                                            controller:
                                                _warrantyValueController,
                                            decoration:
                                                const InputDecoration(
                                              labelText: 'Warranty',
                                              border:
                                                  OutlineInputBorder(),
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 12),
                                            ),
                                            keyboardType:
                                                TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 1,
                                          child:
                                              DropdownButtonFormField<
                                                  String>(
                                            initialValue: _warrantyUnit,
                                            decoration:
                                                const InputDecoration(
                                              labelText: 'Unit',
                                              border:
                                                  OutlineInputBorder(),
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 12),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: 'day',
                                                  child:
                                                      Text('Day(s)')),
                                              DropdownMenuItem(
                                                  value: 'month',
                                                  child:
                                                      Text('Month(s)')),
                                              DropdownMenuItem(
                                                  value: 'year',
                                                  child:
                                                      Text('Year(s)')),
                                            ],
                                            onChanged: (v) {
                                              if (v != null) {
                                                setState(() =>
                                                    _warrantyUnit = v);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text('Select Serial Numbers',
                                        style: AppTextStyles.bodyMd.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: ColorConstants.onSurface)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 100,
                                      child:
                                          _buildSerialCheckboxList(),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child:                                           Text(
                                              '${_selectedSerialIds.length} selected',
                                              style: AppTextStyles.labelMd.copyWith(
                                                  color: ColorConstants.onSurfaceVariant)),
                                        ),
                                        FilledButton(
                                          onPressed: _selectedSerialIds
                                                  .isEmpty
                                              ? null
                                              : () {
                                                  final salePrice =
                                                      double.tryParse(
                                                              _salePriceController
                                                                  .text) ??
                                                          _product!
                                                              .sellingPrice;
                                                  final warrantyValue =
                                                      int.tryParse(
                                                              _warrantyValueController
                                                                  .text) ??
                                                          1;
                                                  final warrantyMonths =
                                                      switch (
                                                          _warrantyUnit) {
                                                    'day' =>
                                                      (warrantyValue /
                                                              30)
                                                          .ceil(),
                                                    'year' =>
                                                      warrantyValue *
                                                          12,
                                                    _ => warrantyValue,
                                                  };
                                                  final product = _product!
                                                      .copyWith(
                                                    sellingPrice:
                                                        salePrice,
                                                    warrantyMonths:
                                                        warrantyMonths,
                                                  );
                                                  widget.onAddToCart(
                                                    product,
                                                    _serialNumbers
                                                        .where((s) =>
                                                            _selectedSerialIds
                                                                .contains(
                                                                    s.id))
                                                        .toList(),
                                                  );
                                                  Navigator.pop(
                                                      context);
                                                },
                                          child:
                                              const Text('Add to Cart'),
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
            ],
          );
        },
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      color: ColorConstants.surfaceContainerHigh,
      child: Icon(Icons.inventory_2,
          color: ColorConstants.onSurfaceVariant, size: 28),
    );
  }

  Widget _buildSerialCheckboxList() {
    final saleProvider = context.watch<SaleProvider>();
    final serials = saleProvider.availableSerialNumbers;

    if (saleProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (serials.isEmpty) {
      return ListView(
        children: const [
          Center(child: Text('No available serial numbers')),
        ],
      );
    }

    _serialNumbers = serials;

    return ListView(
      children: serials
          .map((sn) => CheckboxListTile(
                title: Text(sn.serialNumber,
                    style: const TextStyle(fontSize: 14)),
                value: _selectedSerialIds.contains(sn.id),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedSerialIds.add(sn.id);
                    } else {
                      _selectedSerialIds.remove(sn.id);
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ))
          .toList(),
    );
  }
}
