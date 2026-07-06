import 'package:flutter/material.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/products/widgets/barcode_scanner_screen.dart';

class WarrantySearchBar extends StatefulWidget {
  final ValueChanged<String> onSerialChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onCategoryChanged;

  const WarrantySearchBar({
    super.key,
    required this.onSerialChanged,
    required this.onModelChanged,
    required this.onCategoryChanged,
  });

  @override
  State<WarrantySearchBar> createState() => _WarrantySearchBarState();
}

class _WarrantySearchBarState extends State<WarrantySearchBar> {
  final _serialController = TextEditingController();
  final _modelController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _serialController.dispose();
    _modelController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _clearAll() {
    _serialController.clear();
    _modelController.clear();
    _categoryController.clear();
    widget.onSerialChanged('');
    widget.onModelChanged('');
    widget.onCategoryChanged('');
  }

  bool get _hasAnyInput =>
      _serialController.text.isNotEmpty ||
      _modelController.text.isNotEmpty ||
      _categoryController.text.isNotEmpty;

  Future<void> _scanQrCode() async {
    final code = await Navigator.push<String>(
      context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || code.isEmpty) return;
    _serialController.text = code;
    widget.onSerialChanged(code);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _serialController,
            onChanged: widget.onSerialChanged,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: 'Search by serial number...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasAnyInput)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: _clearAll,
                      splashRadius: 18,
                    ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                    onPressed: _scanQrCode,
                    splashRadius: 18,
                  ),
                  IconButton(
                    icon: Icon(
                      _showFilters
                          ? Icons.filter_list_off_rounded
                          : Icons.filter_list_rounded,
                    ),
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                    splashRadius: 18,
                  ),
                ],
              ),
              isDense: true,
            ),
          ),
        ),
        if (_showFilters) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _modelController,
                    onChanged: widget.onModelChanged,
                    style: AppTextStyles.bodyMd.copyWith(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Model #',
                      prefixIcon:
                          Icon(Icons.qr_code_rounded, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    onChanged: widget.onCategoryChanged,
                    style: AppTextStyles.bodyMd.copyWith(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Category',
                      prefixIcon:
                          Icon(Icons.category_rounded, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
