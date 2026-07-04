import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartstock/features/replacements/models/replacement_model.dart';
import 'package:smartstock/features/replacements/providers/replacement_provider.dart';

class AddReplacementScreen extends StatefulWidget {
  const AddReplacementScreen({super.key});

  @override
  State<AddReplacementScreen> createState() => _AddReplacementScreenState();
}

class _AddReplacementScreenState extends State<AddReplacementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialController = TextEditingController();
  final _newSerialController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  String? _saleId;
  String? _productId;
  String? _productName;
  String? _modelNumber;
  String? _customerName;
  String? _customerPhone;
  bool _isSearching = false;

  @override
  void dispose() {
    _serialController.dispose();
    _newSerialController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _lookupSaleBySerial() async {
    final serial = _serialController.text.trim();
    if (serial.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sales')
          .where('serialNumber', isEqualTo: serial)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _saleId = snapshot.docs.first.id;
          _productId = data['productId'] as String?;
          _productName = data['productName'] as String?;
          _modelNumber = data['modelNumber'] as String?;
          _customerName = data['customerName'] as String?;
          _customerPhone = data['customerPhone'] as String?;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No sale found for this serial number')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Replacement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _serialController,
                decoration: InputDecoration(
                  labelText: 'Original Serial Number',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _lookupSaleBySerial,
                        ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Serial number is required' : null,
              ),
              if (_productName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _productName!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (_modelNumber != null)
                        Text('Model: $_modelNumber',
                            style: const TextStyle(fontSize: 12)),
                      if (_customerName != null)
                        Text('Customer: $_customerName ($_customerPhone)',
                            style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Replacement Reason',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newSerialController,
                decoration: const InputDecoration(
                  labelText: 'New Serial Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'New serial number is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Replacement Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final replacement = Replacement(
      id: '',
      saleId: _saleId ?? '',
      productId: _productId ?? '',
      productName: _productName ?? 'Unknown',
      modelNumber: _modelNumber ?? '',
      oldSerialNumber: _serialController.text.trim(),
      newSerialNumber: _newSerialController.text.trim(),
      customerId: '',
      customerName: _customerName ?? '',
      customerPhone: _customerPhone ?? '',
      reason: _reasonController.text.trim(),
      type: 'replacement',
      status: 'pending',
      createdAt: DateTime.now(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      await context.read<ReplacementProvider>().createReplacement(replacement);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }
}
