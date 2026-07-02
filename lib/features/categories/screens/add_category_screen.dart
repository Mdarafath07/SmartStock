import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/categories/widgets/icon_picker.dart';
import 'package:smartstock/core/widgets/debounced.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = 'inventory_2_rounded';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await context
          .read<CategoryProvider>()
          .addCategory(_nameController.text.trim(), icon: _selectedIcon);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Laptops, Smartphones',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: IconPicker(
                    selectedIcon: _selectedIcon,
                    onSelected: (name) => setState(() => _selectedIcon = name),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Debounced(
                onPressed: _isSaving ? null : _save,
                builder: (context, isDisabled) => FilledButton(
                  onPressed: (_isSaving || isDisabled) ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : const Text('Save Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
