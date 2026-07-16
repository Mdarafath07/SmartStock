import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/features/integrations/screens/sync_dashboard_screen.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:smartstock/features/settings/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SettingsProvider>().loadSettings();
      if (!mounted) return;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SettingsProvider>().loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: SafeArea(
        child: settings.isLoading
            ? _buildLoading(isDark)
            : RefreshIndicator(
                onRefresh: () => context.read<SettingsProvider>().loadSettings(),
                child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceLight.withAlpha(100) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.settings_rounded, color: isDark ? AppColors.textSecondary : AppColors.iconPrimaryAction, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Settings', style: AppTextStyles.headlineMd.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text('Manage your shop preferences', style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                _buildProfileCard(settings, isDark),
                const SizedBox(height: 16),
                _buildShopSection(settings, isDark),
                const SizedBox(height: 16),
                _buildInventorySection(settings, isDark),
                const SizedBox(height: 16),
                _buildGoogleSheetsSection(settings, isDark),
                const SizedBox(height: 16),

                _buildDataSection(isDark),
                const SizedBox(height: 16),
                _buildAboutSection(isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildProfileCard(SettingsProvider settings, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                (settings.storeName.isNotEmpty ? settings.storeName[0] : 'S').toUpperCase(),
                style: const TextStyle(
                    fontFamily: 'Hanken Grotesk', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(settings.storeName, style: AppTextStyles.titleMd.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
                if (settings.storeAddress.isNotEmpty)
                  Text(settings.storeAddress, style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopSection(SettingsProvider settings, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shop Information', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.store_rounded, label: 'Store Name', value: settings.storeName, isDark: isDark, onTap: () => _showEditStoreNameDialog(settings)),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.attach_money_rounded, label: 'Currency', value: '${settings.currency} (${settings.currencySymbol})', isDark: isDark, onTap: () => _showCurrencySelector(settings)),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.access_time_rounded, label: 'Timezone', value: settings.timezone, isDark: isDark, onTap: () => _showTimezoneSelector(settings)),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.email_rounded, label: 'Store Email', value: settings.storeEmail.isEmpty ? 'Not set' : settings.storeEmail, isDark: isDark, onTap: () => _showEditFieldDialog(settings, 'Store Email', settings.storeEmail, (v) => settings.updateStoreEmail(v))),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.phone_rounded, label: 'Store Phone', value: settings.storePhone.isEmpty ? 'Not set' : settings.storePhone, isDark: isDark, onTap: () => _showEditFieldDialog(settings, 'Store Phone', settings.storePhone, (v) => settings.updateStorePhone(v))),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.location_on_rounded, label: 'Store Address', value: settings.storeAddress.isEmpty ? 'Not set' : settings.storeAddress, isDark: isDark, onTap: () => _showEditFieldDialog(settings, 'Store Address', settings.storeAddress, (v) => settings.updateStoreAddress(v))),
        ],
      ),
    );
  }

  Widget _buildInventorySection(SettingsProvider settings, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inventory Settings', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.inventory_2_rounded, label: 'Low Stock Threshold', value: '≤ ${settings.lowStockThreshold} units', isDark: isDark, onTap: () => _showThresholdDialog(settings, 'low')),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.inventory_rounded, label: 'Overstock Threshold', value: '≥ ${settings.overstockThreshold} units', isDark: isDark, onTap: () => _showThresholdDialog(settings, 'over')),
        ],
      ),
    );
  }

  Widget _buildGoogleSheetsSection(SettingsProvider settings, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncDashboardScreen())),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.table_chart_rounded, size: 20, color: AppColors.primary)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Google Sheets Backup', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Configure and sync data to Google Sheets',
                      style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
                ],
              ),
            ),
            Container(width: 26, height: 26,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF1F5F9)).withAlpha(150),
                borderRadius: BorderRadius.circular(8),
              ),
                child: Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.textMuted : AppColors.iconCardAction),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.download_rounded, label: 'Download Data', value: 'Save all data as CSV file', isDark: isDark, onTap: () => _showSnackBar('Download started')),
        ],
      ),
    );
  }

  Widget _buildAboutSection(bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.info_outline_rounded, label: 'Version', value: '1.0.0', isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40, height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text('Loading settings...',
                  style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingRow({required IconData icon, required String label, required String value, required bool isDark, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: isDark ? AppColors.textSecondary : AppColors.iconCardAction)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(value, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceLight : const Color(0xFFF1F5F9)).withAlpha(150),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.textMuted : AppColors.iconCardAction),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditStoreNameDialog(SettingsProvider settings) {
    final controller = TextEditingController(text: settings.storeName);
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Store Name', style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
          const SizedBox(height: 16),
          TextField(controller: controller, decoration: const InputDecoration(labelText: 'Store Name'), style: TextStyle(color: _getTextColor(context))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () { settings.updateStoreName(controller.text.trim()); _showSnackBar('Store name updated'); Navigator.pop(ctx); }, child: const Text('Save'))),
          ]),
        ]),
      ),
    ));
  }

  void _showEditFieldDialog(SettingsProvider settings, String label, String currentValue, Future<void> Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
          const SizedBox(height: 16),
          TextField(controller: controller, decoration: InputDecoration(labelText: label), maxLines: label == 'Store Address' ? 3 : 1, style: TextStyle(color: _getTextColor(context))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () { onSave(controller.text.trim()); _showSnackBar('$label updated'); Navigator.pop(ctx); }, child: const Text('Save'))),
          ]),
        ]),
      ),
    ));
  }

  void _showCurrencySelector(SettingsProvider settings) {
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select Currency', style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
          const SizedBox(height: 12),
          ...SettingsService.currencies.map((code) {
            final symbol = SettingsService.currencySymbol(code);
            final selected = code == settings.currency;
            return InkWell(
              onTap: () { settings.updateCurrency(code); _showSnackBar('Currency set to $code ($symbol)'); Navigator.pop(ctx); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withAlpha(12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Text('$code ($symbol)', style: AppTextStyles.bodyMd.copyWith(color: _getTextColor(context), fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                  const Spacer(),
                  if (selected) Container(width: 20, height: 20,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5)),
                    child: const Icon(Icons.check_rounded, size: 14, color: Colors.black)),
                ]),
              ),
            );
          }),
        ]),
      ),
    ));
  }

  void _showTimezoneSelector(SettingsProvider settings) {
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select Timezone', style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
          const SizedBox(height: 12),
          Flexible(child: ListView(
            shrinkWrap: true,
            children: SettingsService.timezones.map((tz) {
              final selected = tz == settings.timezone;
              return InkWell(
                onTap: () { settings.updateTimezone(tz); _showSnackBar('Timezone set to $tz'); Navigator.pop(ctx); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(color: selected ? AppColors.primary.withAlpha(12) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Expanded(child: Text(tz, style: AppTextStyles.bodySm.copyWith(color: _getTextColor(context), fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
                    if (selected) Container(width: 20, height: 20,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5)),
                      child: const Icon(Icons.check_rounded, size: 14, color: Colors.black)),
                  ]),
                ),
              );
            }).toList(),
          )),
        ]),
      ),
    ));
  }

  void _showThresholdDialog(SettingsProvider settings, String type) {
    final isLow = type == 'low';
    final current = isLow ? settings.lowStockThreshold : settings.overstockThreshold;
    final controller = TextEditingController(text: current.toString());
    final formKey = GlobalKey<FormState>();
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isLow ? 'Low Stock Threshold' : 'Overstock Threshold', style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
          const SizedBox(height: 16),
          Form(key: formKey, child: TextFormField(
            controller: controller, keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: isLow ? 'Low stock count' : 'Overstock count'),
            validator: (v) { final n = int.tryParse(v ?? ''); if (n == null || n < 0) return 'Enter a valid number'; return null; },
            style: TextStyle(color: _getTextColor(context)),
          )),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              final value = int.tryParse(controller.text) ?? current;
              if (isLow) { settings.updateLowStockThreshold(value); } else { settings.updateOverstockThreshold(value); }
              _showSnackBar('${isLow ? "Low stock" : "Overstock"} threshold updated to $value');
              Navigator.pop(ctx);
            }, child: const Text('Save'))),
          ]),
        ]),
      ),
    ));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _getTextColor(BuildContext context) {
    return AppColors.textPrimary;
  }
}
