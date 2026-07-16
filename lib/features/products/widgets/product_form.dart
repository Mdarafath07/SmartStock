import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/services/connectivity_service.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/products/models/product_model.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/products/screens/product_details_screen.dart';
import 'package:smartstock/features/products/widgets/barcode_scanner_screen.dart';
import 'package:smartstock/features/products/widgets/image_picker_widget.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final bool isEdit;
  final bool hideSerials;
  final Future<void> Function(Product product, List<String> serialNumbers, {DateTime? stockDate}) onSave;

  const ProductForm({
    super.key,
    this.product,
    this.isEdit = false,
    this.hideSerials = false,
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
  final _serialInputController = TextEditingController();
  final _pendingSerials = <String>[];
  int _qty = 1;
  DateTime _stockDate = DateTime.now();
  bool _isSubmitting = false;
  bool _isSerialized = true;

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
      _isSerialized = p.isSerialized;
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

  void _removePendingSerial(int index) {
    setState(() {
      _pendingSerials.removeAt(index);
    });
  }

  void _handleScan() async {
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
        _serialInputController.clear();
      });
    }
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

  @override
  void dispose() {
    _brandController.dispose();
    _productNameController.dispose();
    _modelNumberController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _descriptionController.dispose();
    _serialInputController.dispose();
    _customWarrantyController.dispose();
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
    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.canWrite()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please connect to save.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    if (!_formKey.currentState!.validate()) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    final serialNumbers = List<String>.from(_pendingSerials);

    if (!widget.isEdit && !widget.hideSerials) {
      if (_isSerialized && serialNumbers.isEmpty) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('At least one serial number is required')),
          );
        }
        return;
      }
      if (!_isSerialized) {
        if (_qty <= 0) {
          if (mounted) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quantity must be greater than 0')),
            );
          }
          return;
        }
      }
    }

    try {
      final qty = _isSerialized ? 0 : _qty;

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
        warrantyMonths: _isSerialized ? _resolvedWarrantyMonths : 0,
        warrantyDays: _isSerialized ? _resolvedWarrantyDays : 0,
        availableQuantity: widget.isEdit ? (widget.product?.availableQuantity ?? 0) : qty,
        soldQuantity: widget.product?.soldQuantity ?? 0,
        isSerialized: _isSerialized,
      );

      await widget.onSave(product, serialNumbers, stockDate: _stockDate);
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
          if (!widget.isEdit) ...[
            const Text('Product Type',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                )),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Serialized', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                ButtonSegment(value: false, label: Text('Quantity Based', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
              ],
              selected: {_isSerialized},
              onSelectionChanged: (v) => setState(() => _isSerialized = v.first),
              style: SegmentedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerLow,
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: Colors.white,
                foregroundColor: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],
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
          if (_isSerialized) ...[
            const SizedBox(height: 14),
            _buildWarrantySection(),
          ],
          const SizedBox(height: 14),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Product description...',
            maxLines: 3,
          ),
          if (!widget.hideSerials && !_isSerialized && !widget.isEdit) ...[
            const SizedBox(height: 20),
            const Text('Initial Stock',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _stockDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _stockDate = DateTime(
                        picked.year, picked.month, picked.day,
                        _stockDate.hour, _stockDate.minute,
                      ));
                    }
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
                const SizedBox(width: 8),
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_stockDate),
                    );
                    if (picked != null) {
                      setState(() => _stockDate = DateTime(
                        _stockDate.year, _stockDate.month, _stockDate.day,
                        picked.hour, picked.minute,
                      ));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('hh:mm a').format(_stockDate),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Quantity',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              onChanged: (value) {
                setState(() {
                  _qty = int.tryParse(value) ?? 1;
                });
              },
            ),
          ],
          if (!widget.hideSerials && _isSerialized) ...[
            const SizedBox(height: 20),
            const Text('Serial Numbers',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _stockDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _stockDate = DateTime(
                        picked.year, picked.month, picked.day,
                        _stockDate.hour, _stockDate.minute,
                      ));
                    }
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
                const SizedBox(width: 8),
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_stockDate),
                    );
                    if (picked != null) {
                      setState(() => _stockDate = DateTime(
                        _stockDate.year, _stockDate.month, _stockDate.day,
                        picked.hour, picked.minute,
                      ));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('hh:mm a').format(_stockDate),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                      fontFamily: 'Geist',
                      fontSize: 13,
                      color: AppColors.onSurface,
                    ),
                    onSubmitted: (_) => _addPendingSerial(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _handleScan,
                  icon: const Icon(Icons.qr_code_scanner,
                      color: AppColors.primary, size: 22),
                  tooltip: 'Scan & add',
                ),
                FilledButton.tonalIcon(
                  onPressed: _addPendingSerial,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            if (_pendingSerials.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...List.generate(_pendingSerials.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_pendingSerials[i],
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 13,
                                color: AppColors.onSurface,
                              )),
                        ),
                        GestureDetector(
                          onTap: () => _removePendingSerial(i),
                          child: const Icon(Icons.close,
                              size: 16, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (!widget.isEdit) ...[
                const SizedBox(height: 14),
                _buildSummary(),
              ],
            ],
          ],
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

  Widget _buildSummary() {
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final serialCount = _pendingSerials.length;
    final count = _isSerialized ? serialCount : _qty;
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text) ?? 0;
    final totalPurchase = count * purchasePrice;
    final totalSelling = count * sellingPrice;

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
