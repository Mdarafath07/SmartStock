import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/services/connectivity_service.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/product_issues/models/product_issue_model.dart';
import 'package:smartstock/features/products/widgets/barcode_scanner_screen.dart';
import 'package:smartstock/features/product_issues/providers/product_issue_provider.dart';
import 'package:smartstock/features/product_issues/services/product_issue_service.dart';

class AddProductIssueScreen extends StatefulWidget {
  const AddProductIssueScreen({super.key});

  @override
  State<AddProductIssueScreen> createState() => _AddProductIssueScreenState();
}

class _AddProductIssueScreenState extends State<AddProductIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _service = ProductIssueService();
  final _focusNode = FocusNode();
  String _issueType = 'defect';
  String? _productId;
  String? _productName;
  String? _modelNumber;
  bool _isSearching = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;

  final List<String> _issueTypes = [
    'defect',
    'damage',
    'malfunction',
    'wrong_item',
    'cosmetic',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _serialController.addListener(_onSerialChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _serialController.removeListener(_onSerialChanged);
    _serialController.dispose();
    _descriptionController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSerialChanged() {
    _debounce?.cancel();
    final text = _serialController.text.trim();
    if (text.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchSerials(text);
    });
  }

  Future<void> _searchSerials(String query) async {
    final results = await _service.searchAvailableSerials(query);
    if (_serialController.text.trim().length < 2) return;
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty;
    });
  }

  Future<bool?> _lookupSerial({String? serial}) async {
    final s = serial ?? _serialController.text.trim();
    if (s.isEmpty) return null;

    setState(() => _isSearching = true);

    try {
      final result = await _service.getProductBySerial(s);
      if (result != null) {
        setState(() {
          _productId = result['productId'] as String;
          _productName = result['productName'] as String;
          _modelNumber = result['modelNumber'] as String;
        });
        return true;
      }

      setState(() {
        _productId = null;
        _productName = null;
        _modelNumber = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Only available products can be reported')),
        );
      }
      return false;
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code != null && code is String && code.isNotEmpty) {
      _serialController.text = code;
      _showSuggestions = false;
      final result = await _lookupSerial(serial: code);
      if (result == null) {
        _serialController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  TextFormField(
                    controller: _serialController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      labelText: 'Serial Number',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.qr_code),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSearching)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          else ...[
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: _scanBarcode,
                              tooltip: 'Scan QR',
                            ),
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () => _lookupSerial(),
                              tooltip: 'Search',
                            ),
                          ],
                        ],
                      ),
                    ),
                    onFieldSubmitted: (_) => _lookupSerial(),
                  ),
                  if (_showSuggestions)
                    Positioned(
                      top: 56,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final item = _suggestions[index];
                              final sn =
                                  item['serialNumber'] as String? ?? '';
                              return ListTile(
                                dense: true,
                                title: Text(sn,
                                    style: const TextStyle(fontSize: 14)),
                                onTap: () {
                                  _serialController.text = sn;
                                  _serialController.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(offset: sn.length),
                                  );
                                  setState(() => _showSuggestions = false);
                                  _lookupSerial(serial: sn);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (_productName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceLighter : const Color(0xFFEAE7EF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? AppColors.greyDarker : const Color(0xFFC6C5D4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _productName!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimary : const Color(0xFF1B1B21),
                              ),
                            ),
                            if (_modelNumber != null &&
                                _modelNumber!.isNotEmpty)
                              Text(
                                'Model: $_modelNumber',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondary : const Color(0xFF454652),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _issueType,
                decoration: const InputDecoration(
                  labelText: 'Issue Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _issueTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getIssueTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _issueType = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Issue Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please describe the issue' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Customer Phone (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitIssue,
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Issue Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitIssue() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('First search and select an available product by serial number')),
      );
      return;
    }

    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.canWrite()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please connect to report issue.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final issue = ProductIssue(
      id: '',
      productId: _productId!,
      productName: _productName ?? 'Unknown',
      modelNumber: _modelNumber ?? '',
      serialNumber: _serialController.text.trim(),
      issueDescription: _descriptionController.text.trim(),
      issueType: _issueType,
      status: 'open',
      customerName: _customerNameController.text.trim().isEmpty
          ? null
          : _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim().isEmpty
          ? null
          : _customerPhoneController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await context.read<ProductIssueProvider>().createIssue(issue);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to report issue: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getIssueTypeLabel(String type) {
    switch (type) {
      case 'defect':
        return 'Defect';
      case 'damage':
        return 'Physical Damage';
      case 'malfunction':
        return 'Malfunction';
      case 'wrong_item':
        return 'Wrong Item';
      case 'cosmetic':
        return 'Cosmetic Issue';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }
}
