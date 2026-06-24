import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/products/models/product_model.dart';
import 'package:smartstock/features/products/widgets/image_picker_widget.dart';
import 'package:smartstock/features/products/widgets/serial_number_list.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final bool isEdit;
  final void Function(Product product, List<String> serialNumbers) onSave;

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

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  int _warrantyMonths = 12;
  String _imageUrl = '';

  static const _warrantyOptions = [3, 6, 12, 24];

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
      _imageUrl = p.imageUrl;
    }
    _addSerialField();
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

  @override
  void dispose() {
    _brandController.dispose();
    _productNameController.dispose();
    _modelNumberController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _descriptionController.dispose();
    for (final c in _serialControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final serialNumbers = _serialControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

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
      warrantyMonths: _warrantyMonths,
    );

    widget.onSave(product, serialNumbers);
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
          _buildWarrantyDropdown(),
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
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
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
            color: AppColors.primaryContainer,
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
    return DropdownButtonFormField<String>(
      initialValue: value,
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
            color: AppColors.primaryContainer,
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

  Widget _buildWarrantyDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _warrantyMonths,
      items: _warrantyOptions.map((months) {
        return DropdownMenuItem(
          value: months,
          child: Text(
            '$months months',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.onSurface,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _warrantyMonths = value);
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
            color: AppColors.primaryContainer,
            width: 1,
          ),
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.onSurface,
      ),
    );
  }
}
