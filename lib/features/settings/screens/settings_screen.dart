import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/core/constants/color_constants.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:smartstock/features/settings/services/settings_service.dart';
import 'package:smartstock/features/settings/widgets/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settings.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                const SizedBox(height: 8),
                _buildSectionHeader('Profile'),
                SettingsTile(
                  leadingIcon: Icons.person_rounded,
                  title: settings.ownerName,
                  subtitle: settings.ownerEmail,
                  onTap: () => _showEditProfileDialog(settings),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('Shop Information'),
                SettingsTile(
                  leadingIcon: Icons.store_rounded,
                  title: 'Store Name',
                  subtitle: settings.storeName,
                  onTap: () => _showEditStoreNameDialog(settings),
                  trailing: Text(settings.storeName,
                      style: AppTextStyles.labelMd
                          .copyWith(color: ColorConstants.onSurfaceVariant)),
                ),
                SettingsTile(
                  leadingIcon: Icons.attach_money_rounded,
                  title: 'Currency',
                  subtitle: '${settings.currency} (${settings.currencySymbol})',
                  onTap: () => _showCurrencySelector(settings),
                  trailing: Text(settings.currency,
                      style: AppTextStyles.labelMd
                          .copyWith(color: ColorConstants.onSurfaceVariant)),
                ),
                SettingsTile(
                  leadingIcon: Icons.access_time_rounded,
                  title: 'Timezone',
                  subtitle: settings.timezone,
                  onTap: () => _showTimezoneSelector(settings),
                  trailing: Text(settings.timezone,
                      style: AppTextStyles.labelMd
                          .copyWith(color: ColorConstants.onSurfaceVariant)),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('Inventory Settings'),
                SettingsTile(
                  leadingIcon: Icons.inventory_2_rounded,
                  title: 'Low Stock Threshold',
                  subtitle: 'Alert when stock ≤ ${settings.lowStockThreshold}',
                  onTap: () => _showThresholdDialog(settings, 'low'),
                ),
                SettingsTile(
                  leadingIcon: Icons.inventory_rounded,
                  title: 'Overstock Threshold',
                  subtitle: 'Alert when stock ≥ ${settings.overstockThreshold}',
                  onTap: () => _showThresholdDialog(settings, 'over'),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('Data & Backup'),
                SettingsTile(
                  leadingIcon: Icons.backup_rounded,
                  title: 'Export Data',
                  subtitle: 'Download all data as CSV',
                  onTap: () => _showSnackBar('Export started'),
                  iconColor: ColorConstants.info,
                ),
                SettingsTile(
                  leadingIcon: Icons.restore_rounded,
                  title: 'Import Data',
                  subtitle: 'Restore data from backup',
                  onTap: () => _showSnackBar('Import started'),
                  iconColor: ColorConstants.warning,
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('About'),
                SettingsTile(
                  leadingIcon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '1.0.0',
                  trailing: Text('1.0.0',
                      style: AppTextStyles.labelMd
                          .copyWith(color: ColorConstants.onSurfaceVariant)),
                ),
                SettingsTile(
                  leadingIcon: Icons.code_rounded,
                  title: 'Developer',
                  subtitle: 'SmartStock Team',
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: AppTextStyles.labelMd.copyWith(
          fontWeight: FontWeight.w600,
          color: ColorConstants.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showEditProfileDialog(SettingsProvider settings) {
    final nameController = TextEditingController(text: settings.ownerName);
    final emailController = TextEditingController(text: settings.ownerEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          Debounced(
            onPressed: () => Navigator.pop(ctx),
            builder: (_, isDisabled) => TextButton(
              onPressed: isDisabled ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ),
          Debounced(
            onPressed: () {
              settings.updateProfile(
                nameController.text.trim(),
                emailController.text.trim(),
              );
              _showSnackBar('Profile updated');
              Navigator.pop(ctx);
            },
            builder: (context, isDisabled) => FilledButton(
              onPressed: isDisabled ? null : () {
                settings.updateProfile(
                  nameController.text.trim(),
                  emailController.text.trim(),
                );
                _showSnackBar('Profile updated');
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditStoreNameDialog(SettingsProvider settings) {
    final controller = TextEditingController(text: settings.storeName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Store Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Store Name'),
        ),
        actions: [
          Debounced(
            onPressed: () => Navigator.pop(ctx),
            builder: (_, isDisabled) => TextButton(
              onPressed: isDisabled ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ),
          Debounced(
            onPressed: () {
              settings.updateStoreName(controller.text.trim());
              _showSnackBar('Store name updated');
              Navigator.pop(ctx);
            },
            builder: (context, isDisabled) => FilledButton(
              onPressed: isDisabled ? null : () {
                settings.updateStoreName(controller.text.trim());
                _showSnackBar('Store name updated');
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencySelector(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Currency'),
        children: SettingsService.currencies.map((code) {
          final symbol = SettingsService.currencySymbol(code);
          return SimpleDialogOption(
            onPressed: () {
              settings.updateCurrency(code);
              _showSnackBar('Currency set to $code ($symbol)');
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Text('$code  ', style: AppTextStyles.bodyMd),
                Text('($symbol)',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: ColorConstants.onSurfaceVariant)),
                if (code == settings.currency)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check, size: 18, color: Colors.green),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showTimezoneSelector(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Timezone'),
        children: SettingsService.timezones.map((tz) {
          return SimpleDialogOption(
            onPressed: () {
              settings.updateTimezone(tz);
              _showSnackBar('Timezone set to $tz');
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Text(tz, style: AppTextStyles.bodyMd),
                if (tz == settings.timezone)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check, size: 18, color: Colors.green),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showThresholdDialog(SettingsProvider settings, String type) {
    final isLow = type == 'low';
    final current = isLow ? settings.lowStockThreshold : settings.overstockThreshold;
    final controller = TextEditingController(text: current.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isLow ? 'Low Stock Threshold' : 'Overstock Threshold'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isLow ? 'Low stock count' : 'Overstock count',
            ),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 0) return 'Enter a valid number';
              return null;
            },
          ),
        ),
        actions: [
          Debounced(
            onPressed: () => Navigator.pop(ctx),
            builder: (_, isDisabled) => TextButton(
              onPressed: isDisabled ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ),
          Debounced(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              final value = int.tryParse(controller.text) ?? current;
              if (isLow) {
                settings.updateLowStockThreshold(value);
              } else {
                settings.updateOverstockThreshold(value);
              }
              _showSnackBar(
                  '${isLow ? "Low stock" : "Overstock"} threshold updated to $value');
              Navigator.pop(ctx);
            },
            builder: (context, isDisabled) => FilledButton(
              onPressed: isDisabled ? null : () {
                if (formKey.currentState?.validate() != true) return;
                final value = int.tryParse(controller.text) ?? current;
                if (isLow) {
                  settings.updateLowStockThreshold(value);
                } else {
                  settings.updateOverstockThreshold(value);
                }
                _showSnackBar(
                    '${isLow ? "Low stock" : "Overstock"} threshold updated to $value');
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
