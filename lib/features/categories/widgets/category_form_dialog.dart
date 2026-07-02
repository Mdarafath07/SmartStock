import 'package:flutter/material.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/categories/widgets/icon_picker.dart';

class CategoryFormDialog extends StatefulWidget {
  final String? initialName;
  final String? initialIcon;
  final void Function(String name, String icon) onSave;

  const CategoryFormDialog({
    super.key,
    this.initialName,
    this.initialIcon,
    required this.onSave,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  late String _selectedIcon;

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
        Debounced(
          onPressed: () => Navigator.pop(context),
          builder: (_, isDisabled) => TextButton(
            onPressed: isDisabled ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        Debounced(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(_controller.text.trim(), _selectedIcon);
              Navigator.pop(context);
            }
          },
          builder: (context, isDisabled) => FilledButton(
            onPressed: isDisabled ? null : () {
              if (_formKey.currentState!.validate()) {
                widget.onSave(_controller.text.trim(), _selectedIcon);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}
