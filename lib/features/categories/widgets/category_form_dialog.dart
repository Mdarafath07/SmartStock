import 'package:flutter/material.dart';
import 'package:smartstock/core/widgets/debounced.dart';

class CategoryFormDialog extends StatefulWidget {
  final String? initialName;
  final ValueChanged<String> onSave;

  const CategoryFormDialog({
    super.key,
    this.initialName,
    required this.onSave,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
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
      content: Form(
        key: _formKey,
        child: TextFormField(
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
              widget.onSave(_controller.text.trim());
              Navigator.pop(context);
            }
          },
          builder: (context, isDisabled) => FilledButton(
            onPressed: isDisabled ? null : () {
              if (_formKey.currentState!.validate()) {
                widget.onSave(_controller.text.trim());
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
