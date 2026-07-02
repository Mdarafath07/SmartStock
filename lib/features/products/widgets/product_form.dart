import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/products/models/product_model.dart';
import 'package:smartstock/features/products/widgets/barcode_scanner_screen.dart';
import 'package:smartstock/features/products/widgets/image_picker_widget.dart';
import 'package:smartstock/features/products/widgets/serial_number_list.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final bool isEdit;
  final Future<void> Function(Product product, List<String> serialNumbers) onSave;

  const ProductForm({
    super.key,
    this.product,
    this.isEdit = false,
    required this.onSave,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _productNameController = TextEditingController();
  final _modelNumberController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serialControllers = <TextEditingController>[];
  bool _isSubmitting = false;

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String _imageUrl = '';

  int _warrantyMonths = 0;
  int _warrantyDays = 0;
  String? _warrantyDropdownValue;
  bool _isCustomWarranty = false;
  bool _warrantyUnitIsMonths = true;
  final _customWarrantyController = TextEditingController();

  static const _warrantyOptions = <String>[
    'None',
    'd7', 'd14', 'd30',
    'm3', 'm6', 'm12', 'm24',
    'custom',
  ];

  String _warrantyLabel(String key) {
    return switch (key) {
      'None' => 'None (no warranty)',
      'd7' => '7 days',
      'd14' => '14 days',
      'd30' => '30 days',
      'm3' => '3 months',
      'm6' => '6 months',
      'm12' => '12 months',
      'm24' => '24 months',
      'custom' => 'Custom',
      _ => key,
    };
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _brandController.text = p.brandName;
      _productNameController.text = p.productName;
      _modelNumberController.text = p.modelNumber;
      _purchasePriceController.text = p.purchasePrice.toString();
      _sellingPriceController.text = p.sellingPrice.toString();
      _descriptionController.text = p.description;
      _selectedCategoryId = p.categoryId;
      _selectedCategoryName = p.categoryName;
      _warrantyMonths = p.warrantyMonths;
      _warrantyDays = p.warrantyDays;
      _imageUrl = p.imageUrl;
      _warrantyDropdownValue = _resolveDropdown(p.warrantyMonths, p.warrantyDays);
      if (_warrantyDropdownValue == null) {
        _isCustomWarranty = true;
        _warrantyUnitIsMonths = p.warrantyMonths > 0;
        _customWarrantyController.text = _warrantyUnitIsMonths
            ? p.warrantyMonths.toString()
            : p.warrantyDays.toString();
        _warrantyDropdownValue = 'custom';
      }
    }
    _addSerialField();
  }

  String? _resolveDropdown(int months, int days) {
    if (months == 0 && days == 0) return 'None';
    if (days == 7 && months == 0) return 'd7';
    if (days == 14 && months == 0) return 'd14';
    if (days == 30 && months == 0) return 'd30';
    if (months == 3 && days == 0) return 'm3';
    if (months == 6 && days == 0) return 'm6';
    if (months == 12 && days == 0) return 'm12';
    if (months == 24 && days == 0) return 'm24';
    return null;
  }

  void _addSerialField() {
    setState(() {
      _serialControllers.add(TextEditingController());
    });
  }

  void _removeSerialField(int index) {
    setState(() {
      _serialControllers[index].dispose();
      _serialControllers.removeAt(index);
    });
  }

  void _handleScan(int index) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null && index < _serialControllers.length) {
      _serialControllers[index].text = result;
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _productNameController.dispose();
    _modelNumberController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _descriptionController.dispose();
    _customWarrantyController.dispose();
    for (final c in _serialControllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _resolvedWarrantyMonths {
    if (_isCustomWarranty) {
      if (_warrantyUnitIsMonths) {
        return int.tryParse(_customWarrantyController.text) ?? 0;
      }
      return 0;
    }
    return _warrantyMonths;
  }

  int get _resolvedWarrantyDays {
    if (_isCustomWarranty) {
      if (!_warrantyUnitIsMonths) {
        return int.tryParse(_customWarrantyController.text) ?? 0;
      }
      return 0;
    }
    return _warrantyDays;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    if (!_formKey.currentState!.validate()) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    final serialNumbers = _serialControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (!widget.isEdit && serialNumbers.isEmpty) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one serial number is required')),
        );
      }
      return;
    }

    try {

      final product = Product(
        id: widget.product?.id ?? '',
        categoryId: _selectedCategoryId ?? '',
        categoryName: _selectedCategoryName ?? '',
        brandName: _brandController.text.trim(),
        productName: _productNameController.text.trim(),
        modelNumber: _modelNumberController.text.trim(),
        imageUrl: _imageUrl,
        description: _descriptionController.text.trim(),
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0,
        warrantyMonths: _resolvedWarrantyMonths,
        warrantyDays: _resolvedWarrantyDays,
        availableQuantity: widget.product?.availableQuantity ?? 0,
        soldQuantity: widget.product?.soldQuantity ?? 0,
      );

      await widget.onSave(product, serialNumbers);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ImagePickerWidget(
            initialImageUrl: _imageUrl,
            onImageUploaded: (url) => _imageUrl = url,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Category',
            value: _selectedCategoryId,
            items: categories,
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
                _selectedCategoryName = categories
                    .firstWhere((c) => c.id == value)
                    .name;
              });
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _brandController,
            label: 'Brand Name',
            hint: 'e.g. Samsung, Apple',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Brand is required' : null,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _productNameController,
            label: 'Product Name',
            hint: 'e.g. Galaxy S24 Ultra',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Product name is required' : null,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _modelNumberController,
            label: 'Model Number',
            hint: 'e.g. SM-S928B',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Model number is required' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _purchasePriceController,
                  label: 'Purchase Price',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _sellingPriceController,
                  label: 'Selling Price',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildWarrantySection(),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Product description...',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SerialNumberList(
            controllers: _serialControllers,
            onAdd: _addSerialField,
            onRemove: _removeSerialField,
            onScan: _handleScan,
          ),
          const SizedBox(height: 20),
            SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.isEdit ? 'Update Product' : 'Save Product',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.onSurfaceVariant,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.onSurfaceVariant,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List items,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = items.any((i) => i.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: validValue,
      items: items.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem(
          value: item.id,
          child: Text(
            item.name,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.onSurface,
            ),
          ),
        );
      }).toList(),
      onChanged: items.isEmpty ? null : onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.onSurfaceVariant,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1,
          ),
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.onSurface,
      ),
      validator: (v) => v == null || v.isEmpty ? 'Category is required' : null,
    );
  }

  Widget _buildWarrantySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _warrantyDropdownValue,
          items: _warrantyOptions.map((key) {
            return DropdownMenuItem(
              value: key,
              child: Text(
                _warrantyLabel(key),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            if (value == 'custom') {
              setState(() {
                _isCustomWarranty = true;
                _warrantyDropdownValue = value;
              });
            } else if (value == 'None') {
              setState(() {
                _isCustomWarranty = false;
                _warrantyMonths = 0;
                _warrantyDays = 0;
                _warrantyDropdownValue = value;
              });
            } else {
              setState(() {
                _isCustomWarranty = false;
                _warrantyDropdownValue = value;
                if (value.startsWith('d')) {
                  _warrantyDays = int.parse(value.substring(1));
                  _warrantyMonths = 0;
                } else {
                  _warrantyMonths = int.parse(value.substring(1));
                  _warrantyDays = 0;
                }
              });
            }
          },
          decoration: InputDecoration(
            labelText: 'Warranty Duration',
            labelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1,
              ),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.onSurface,
          ),
        ),
        if (_isCustomWarranty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customWarrantyController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (!_isCustomWarranty) return null;
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Enter valid number';
                    return null;
                  },
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Custom Duration',
                    hintText: 'Enter value',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                    labelStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Months', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                  ButtonSegment(value: false, label: Text('Days', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                ],
                selected: {_warrantyUnitIsMonths},
                onSelectionChanged: (v) {
                  setState(() => _warrantyUnitIsMonths = v.first);
                },
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
