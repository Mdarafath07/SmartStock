import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/services/connectivity_service.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/categories/widgets/icon_picker.dart';

class CategoryFormDialog extends StatefulWidget {
  final String? initialName;
  final String? initialIcon;
  final String? initialId;
  final Future<void> Function(String name, String icon) onSave;

  const CategoryFormDialog({
    super.key,
    this.initialName,
    this.initialIcon,
    this.initialId,
    required this.onSave,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  late String _selectedIcon;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _selectedIcon = widget.initialIcon ?? 'inventory_2_rounded';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.canWrite()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please connect to save.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_controller.text.trim(), _selectedIcon);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialName != null ? 'Edit Category' : 'Add Category',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Laptops',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a category name';
                    }
                    final provider = context.read<CategoryProvider>();
                    if (provider.isDuplicateName(value.trim(), excludeId: widget.initialId)) {
                      return 'Category name already exists';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                IconPicker(
                  selectedIcon: _selectedIcon,
                  onSelected: (name) => setState(() => _selectedIcon = name),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
