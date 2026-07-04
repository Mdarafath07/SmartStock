import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/features/warranty/models/warranty_model.dart';
import 'package:smartstock/features/warranty/providers/warranty_provider.dart';
import 'package:smartstock/features/warranty/widgets/serial_number_picker_dialog.dart';

class WarrantyClaimScreen extends StatefulWidget {
  final Warranty warranty;

  const WarrantyClaimScreen({super.key, required this.warranty});

  @override
  State<WarrantyClaimScreen> createState() => _WarrantyClaimScreenState();
}

class _WarrantyClaimScreenState extends State<WarrantyClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialController = TextEditingController();
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _serialController.dispose();
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await context.read<WarrantyProvider>().processClaim(
        saleId: widget.warranty.saleId,
        serialNumber: widget.warranty.serialNumber,
        newSerialNumber: _serialController.text.trim(),
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Warranty claim processed successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.warranty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranty Claim'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.productName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Model: ${w.modelNumber}'),
                      Text('S/N: ${w.serialNumber}'),
                      Text('Customer: ${w.customerName} (${w.customerPhone})'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serialController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'New Serial Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code_2),
                  helperText: 'Tap to select from available stock',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (_) => const SerialNumberPickerDialog(),
                  );
                  if (selected != null) {
                    _serialController.text = selected;
                  }
                },
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'New serial number is required'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Warranty Claim Reason',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user),
                  label: Text(_isSubmitting
                      ? 'Processing...'
                      : 'Process Warranty Claim'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
