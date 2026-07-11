import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/features/integrations/providers/sync_provider.dart';
import 'package:smartstock/features/integrations/services/google_sheets_backup_service.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class SyncDashboardScreen extends StatefulWidget {
  const SyncDashboardScreen({super.key});

  @override
  State<SyncDashboardScreen> createState() => _SyncDashboardScreenState();
}

class _SyncDashboardScreenState extends State<SyncDashboardScreen> {
  final _sheetIdController = TextEditingController();
  final _jsonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<SettingsProvider>();
      _sheetIdController.text = s.sheetsSpreadsheetId;
      _jsonController.text = s.sheetsServiceAccountJson;
      context.read<SyncProvider>().configure(
        s.sheetsServiceAccountJson,
        s.sheetsSpreadsheetId,
      );
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
    final syncProvider = context.watch<SyncProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sheets Backup'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConfigSection(settings, syncProvider, isDark),
          const SizedBox(height: 16),
          _buildStatusCard(syncProvider, isDark),
          const SizedBox(height: 16),
          if (syncProvider.autoSyncEnabled)
            _buildAutoSyncCard(syncProvider, isDark),
          if (syncProvider.lastResult != null)
            _buildResultCard(context, syncProvider, isDark),
        ],
      ),
    );
  }

  Widget _buildConfigSection(SettingsProvider settings, SyncProvider syncProvider, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configuration', style: AppTextStyles.titleSm.copyWith(
            color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
          )),
          const SizedBox(height: 12),
          _buildField(
            controller: _sheetIdController,
            hint: 'Sheet ID (from URL: /d/<ID>/edit)',
            isDark: isDark,
            onChanged: (v) {
              settings.updateSheetsSpreadsheetId(v.trim());
              syncProvider.configure(settings.sheetsServiceAccountJson, v.trim());
            },
          ),
          const SizedBox(height: 8),
          _buildField(
            controller: _jsonController,
            hint: 'Paste Service Account JSON here',
            isDark: isDark,
            monospace: true,
            maxLines: 4,
            onChanged: (v) {
              settings.updateSheetsServiceAccountJson(v.trim());
              syncProvider.configure(v.trim(), settings.sheetsSpreadsheetId);
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: _jsonController.text.trim().isEmpty
                      ? null
                      : () => _createNewSheet(settings, syncProvider),
                  icon: settings.isSyncing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Create Sheet', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: BorderSide(color: AppColors.green.withAlpha(80)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            if (_sheetIdController.text.trim().isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: settings.isSyncing || syncProvider.isSyncing
                        ? null
                        : () => _syncAllNow(settings, syncProvider),
                    icon: settings.isSyncing || syncProvider.isSyncing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.backup_rounded, size: 16),
                    label: Text(settings.isSyncing || syncProvider.isSyncing ? 'Backing up...' : 'Backup All Now', style: const TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required Function(String) onChanged,
    bool monospace = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(150),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.only(left: 12, right: 4, top: 2, bottom: 2),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8)),
          border: InputBorder.none,
          isDense: true,
        ),
        style: TextStyle(
          fontSize: monospace ? 11 : 13,
          color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
          fontFamily: monospace ? 'monospace' : null,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStatusCard(SyncProvider syncProvider, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: syncProvider.isSyncing
                      ? AppColors.primary.withAlpha(25)
                      : AppColors.green.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  syncProvider.isSyncing
                      ? Icons.sync_rounded
                      : Icons.cloud_done_rounded,
                  color: syncProvider.isSyncing
                      ? AppColors.primary
                      : AppColors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      syncProvider.isSyncing
                          ? 'Syncing...'
                          : 'Backup Status',
                      style: AppTextStyles.titleMd.copyWith(
                        color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      syncProvider.lastSyncTime != null
                          ? 'Last: ${_formatTime(syncProvider.lastSyncTime!)}'
                          : 'Not backed up yet',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (syncProvider.pendingChanges > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${syncProvider.pendingChanges} pending',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: syncProvider.isSyncing
                        ? null
                        : () async {
                            final err = await syncProvider.syncAll();
                            if (err != null && mounted) _showError(err);
                          },
                    icon: syncProvider.isSyncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.backup_rounded, size: 18),
                    label: Text(syncProvider.isSyncing
                        ? 'Backing up...'
                        : 'Backup All Data Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildAutoSyncCard(SyncProvider syncProvider, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Auto-Sync Active',
            style: AppTextStyles.titleSm.copyWith(
              color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All changes are tracked. Data will be synced to Google Sheets '
            'automatically within 30 seconds of any change.',
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: AppColors.green),
              const SizedBox(width: 6),
              Text(
                'Listening for changes',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, SyncProvider syncProvider, bool isDark) {
    final result = syncProvider.lastResult!;
    final textColor = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);

    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.hasErrors
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: result.hasErrors ? AppColors.orange : AppColors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                result.hasErrors
                    ? 'Backup completed with errors'
                    : 'Backup successful',
                style: AppTextStyles.titleSm.copyWith(color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statRow('Duration', '${result.duration.inSeconds}s', textColor),
          _statRow('Collections', '${result.successCount + result.errorCount}', textColor),
          _statRow('Records', '${result.totalRecords}', textColor),
          _statRow('Errors', '${result.errorCount}', textColor),
          if (result.hasErrors) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.red.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.errors.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    e,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.red,
                      fontSize: 11,
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showCollectionDetails(context, result),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View details',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF64748B),
            )),
          ),
          Text(value, style: AppTextStyles.caption.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }

  void _showCollectionDetails(BuildContext context, SyncResult result) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.cardDark
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collection Details',
                style: AppTextStyles.titleMd.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimary
                      : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              ...result.collectionCounts.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      e.value >= 0
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      size: 16,
                      color: e.value >= 0 ? AppColors.green : AppColors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: AppTextStyles.bodySm.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textPrimary
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      e.value >= 0 ? '${e.value} records' : 'Failed',
                      style: AppTextStyles.caption.copyWith(
                        color: e.value >= 0
                            ? AppColors.green
                            : AppColors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Future<void> _createNewSheet(SettingsProvider settings, SyncProvider syncProvider) async {
    final json = _jsonController.text.trim();
    final service = GoogleSheetsBackupService();
    final err = service.validateJson(json);
    if (err != null) { _showError(err); return; }
    settings.setSyncing(true);
    try {
      final sheetId = await service.createSpreadsheet(json);
      _sheetIdController.text = sheetId;
      settings.updateSheetsSpreadsheetId(sheetId);
      syncProvider.configure(json, sheetId);
      _showSnackBar('New Google Sheet created! ID: $sheetId');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
    settings.setSyncing(false);
  }

  void _showError(String msg) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Error', style: AppTextStyles.titleSm),
      content: Text(msg, style: AppTextStyles.bodyMd),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
