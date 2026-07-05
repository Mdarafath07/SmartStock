import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/features/integrations/providers/sync_provider.dart';
import 'package:smartstock/features/integrations/screens/sync_dashboard_screen.dart';
import 'package:smartstock/features/integrations/services/google_sheets_backup_service.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:smartstock/features/settings/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _sheetIdController = TextEditingController();
  final _jsonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<SettingsProvider>();
      s.loadSettings();
      _sheetIdController.text = s.sheetsSpreadsheetId;
      _jsonController.text = s.sheetsServiceAccountJson;
    });
  }

  @override
  void dispose() {
    _sheetIdController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: SafeArea(
        child: settings.isLoading
            ? _buildLoading(isDark)
            : ListView(
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
                        child: Icon(Icons.settings_rounded, color: isDark ? AppColors.textSecondary : const Color(0xFF64748B), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Settings', style: AppTextStyles.headlineMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text('Manage your shop preferences', style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF64748B))),
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
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                (settings.ownerName.isNotEmpty ? settings.ownerName[0] : 'S').toUpperCase(),
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
                Text(settings.ownerName.isNotEmpty ? settings.ownerName : 'Shop Owner',
                    style: AppTextStyles.titleMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                if (settings.ownerEmail.isNotEmpty)
                  Text(settings.ownerEmail, style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF64748B))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditProfileDialog(settings),
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.edit_rounded, size: 18, color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
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
          Text('Shop Information', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.store_rounded, label: 'Store Name', value: settings.storeName, isDark: isDark, onTap: () => _showEditStoreNameDialog(settings)),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.attach_money_rounded, label: 'Currency', value: '${settings.currency} (${settings.currencySymbol})', isDark: isDark, onTap: () => _showCurrencySelector(settings)),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.access_time_rounded, label: 'Timezone', value: settings.timezone, isDark: isDark, onTap: () => _showTimezoneSelector(settings)),
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
          Text('Inventory Settings', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.inventory_2_rounded, label: 'Low Stock Threshold', value: '≤ ${settings.lowStockThreshold} units', isDark: isDark, onTap: () => _showThresholdDialog(settings, 'low')),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.inventory_rounded, label: 'Overstock Threshold', value: '≥ ${settings.overstockThreshold} units', isDark: isDark, onTap: () => _showThresholdDialog(settings, 'over')),
        ],
      ),
    );
  }

  Widget _buildGoogleSheetsSection(SettingsProvider settings, bool isDark) {
    final syncProvider = context.watch<SyncProvider>();
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.table_chart_rounded, size: 18, color: AppColors.green)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Google Sheets Backup', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
              ),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncDashboardScreen())),
                child: Container(width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(150),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: TextField(
              controller: _sheetIdController,
              decoration: InputDecoration(
                hintText: 'Sheet ID (from URL: /d/<ID>/edit)',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E)),
              onChanged: (v) {
                settings.updateSheetsSpreadsheetId(v.trim());
                syncProvider.configure(settings.sheetsServiceAccountJson, v.trim());
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(150),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: TextField(
              controller: _jsonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Paste Service Account JSON here',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
              ),
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E), fontFamily: 'monospace'),
              onChanged: (v) {
                settings.updateSheetsServiceAccountJson(v.trim());
                syncProvider.configure(v.trim(), settings.sheetsSpreadsheetId);
              },
            ),
          ),
          const SizedBox(height: 10),
          // Auto Backup Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(100),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.autorenew_rounded, size: 18, color: AppColors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Auto Backup', style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                      )),
                      Text('Auto-sync all data to sheets on changes',
                          style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                Switch(
                  value: syncProvider.autoSyncEnabled,
                  onChanged: _sheetIdController.text.trim().isEmpty || _jsonController.text.trim().isEmpty
                      ? null
                      : (v) async {
                          if (v) {
                            syncProvider.configure(
                              settings.sheetsServiceAccountJson,
                              settings.sheetsSpreadsheetId,
                            );
                          }
                          await syncProvider.setAutoSync(v);
                          await settings.setAutoBackup(v);
                        },
                  activeThumbColor: AppColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: settings.isSyncing || _sheetIdController.text.trim().isEmpty || _jsonController.text.trim().isEmpty
                        ? null
                        : () => _syncAllNow(settings, syncProvider),
                    icon: settings.isSyncing || syncProvider.isSyncing
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.backup_rounded, size: 16),
                    label: Text(settings.isSyncing || syncProvider.isSyncing ? 'Backing up...' : 'Backup All Now', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncDashboardScreen())),
                    icon: Icon(Icons.history_rounded, size: 16),
                    label: Text('Backup History', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withAlpha(80)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: _sheetIdController.text.trim().isEmpty || _jsonController.text.trim().isEmpty
                        ? null
                        : () => _testConnection(settings),
                    icon: Icon(Icons.wifi_tethering_rounded, size: 16),
                    label: Text('Test Connection', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: BorderSide(color: AppColors.green.withAlpha(80)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: _sheetIdController.text.trim().isEmpty || _jsonController.text.trim().isEmpty
                        ? null
                        : () => _runDiagnostic(settings),
                    icon: Icon(Icons.bug_report_rounded, size: 16),
                    label: Text('Diagnostic', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.orange,
                      side: BorderSide(color: AppColors.orange.withAlpha(80)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data & Backup', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.backup_rounded, label: 'Export Data', value: 'Download all data as CSV', isDark: isDark, onTap: () => _showSnackBar('Export started')),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.restore_rounded, label: 'Import Data', value: 'Restore data from backup', isDark: isDark, onTap: () => _showSnackBar('Import started')),
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
          Text('About', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.info_outline_rounded, label: 'Version', value: '1.0.0', isDark: isDark),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.code_rounded, label: 'Developer', value: 'SmartStock Team', isDark: isDark),
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
                  style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8))),
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
                gradient: LinearGradient(
                  colors: [
                    (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                    (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(100),
                  ],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: isDark ? AppColors.textSecondary : const Color(0xFF64748B))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                  const SizedBox(height: 2),
                  Text(value, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8))),
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
                child: Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8)),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(SettingsProvider settings) {
    final nameController = TextEditingController(text: settings.ownerName);
    final emailController = TextEditingController(text: settings.ownerEmail);
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Edit Profile', style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
          const SizedBox(height: 16),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), style: TextStyle(color: _getTextColor(context))),
          const SizedBox(height: 12),
          TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email'), style: TextStyle(color: _getTextColor(context))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () { settings.updateProfile(nameController.text.trim(), emailController.text.trim()); _showSnackBar('Profile updated'); Navigator.pop(ctx); }, child: const Text('Save'))),
          ]),
        ]),
      ),
    ));
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

  Future<void> _syncAllNow(SettingsProvider settings, SyncProvider syncProvider) async {
    final sheetId = _sheetIdController.text.trim();
    final json = _jsonController.text.trim();
    settings.updateSheetsSpreadsheetId(sheetId);
    settings.updateSheetsServiceAccountJson(json);
    syncProvider.configure(json, sheetId);
    final service = GoogleSheetsBackupService();
    final err = service.validateJson(json);
    if (err != null) { _showError(err); return; }
    if (sheetId.isEmpty) { _showError('Sheet ID is empty'); return; }
    settings.setSyncing(true);
    try {
      final result = await service.syncAll(json, sheetId);
      _showSnackBar('Backup complete: ${result.totalRecords} records in ${result.successCount} collections');
      if (result.hasErrors) {
        _showError('Errors in: ${result.errors.join(', ')}');
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
    settings.setSyncing(false);
  }

  Future<void> _testConnection(SettingsProvider settings) async {
    final sheetId = _sheetIdController.text.trim();
    final json = _jsonController.text.trim();
    final service = GoogleSheetsBackupService();
    _showSnackBar('Testing connection...');
    final msg = await service.testConnection(json, sheetId);
    if (msg == 'Connection OK') {
      _showSnackBar('✅ Connection successful!');
    } else {
      _showError(msg);
    }
  }

  Future<void> _runDiagnostic(SettingsProvider settings) async {
    final sheetId = _sheetIdController.text.trim();
    final json = _jsonController.text.trim();
    final service = GoogleSheetsBackupService();
    _showSnackBar('Running diagnostic...');
    try {
      final result = await service.diagnosticCheck(json, sheetId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sheet Diagnostic'),
          content: SingleChildScrollView(
            child: Text(result, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      _showError('Diagnostic failed: $e');
    }
  }

  void _showError(String msg) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Sync Error', style: AppTextStyles.titleSm),
      content: Text(msg, style: AppTextStyles.bodyMd),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK'))],
    ));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : const Color(0xFF1A1A2E);
  }
}
