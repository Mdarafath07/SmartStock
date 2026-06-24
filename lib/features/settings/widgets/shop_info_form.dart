import 'package:flutter/material.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/utils/validators.dart';

class ShopInfoForm extends StatefulWidget {
  final String storeName;
  final String currency;
  final String timezone;

  const ShopInfoForm({
    super.key,
    this.storeName = '',
    this.currency = 'USD',
    this.timezone = 'UTC',
  });

  @override
  State<ShopInfoForm> createState() => _ShopInfoFormState();
}

class _ShopInfoFormState extends State<ShopInfoForm> {
  late TextEditingController _storeNameController;
  late TextEditingController _currencyController;
  late TextEditingController _timezoneController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(text: widget.storeName);
    _currencyController = TextEditingController(text: widget.currency);
    _timezoneController = TextEditingController(text: widget.timezone);
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _currencyController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop information saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop Information',
            style: AppTextStyles.titleMd.copyWith(
              color: ColorConstants.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _storeNameController,
            decoration: const InputDecoration(
              labelText: 'Store Name',
              prefixIcon: Icon(Icons.store_rounded),
            ),
            validator: AppValidators.validateRequired,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _currencyController,
            decoration: const InputDecoration(
              labelText: 'Currency',
              prefixIcon: Icon(Icons.attach_money_rounded),
              helperText: 'e.g. USD, EUR, BDT',
            ),
            validator: AppValidators.validateRequired,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _timezoneController,
            decoration: const InputDecoration(
              labelText: 'Timezone',
              prefixIcon: Icon(Icons.access_time_rounded),
              helperText: 'e.g. UTC, America/New_York',
            ),
            validator: AppValidators.validateRequired,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
