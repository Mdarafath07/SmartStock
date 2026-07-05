import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/features/integrations/providers/sync_provider.dart';
import 'package:smartstock/features/integrations/services/google_sheets_backup_service.dart';

class SyncDashboardScreen extends StatelessWidget {
  const SyncDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final syncProvider = context.watch<SyncProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sheets Backup'),
        actions: [
          IconButton(
            icon: syncProvider.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            onPressed: syncProvider.isSyncing
                ? null
                : () => syncProvider.syncAll(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                        color:
                            isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      syncProvider.lastSyncTime != null
                          ? 'Last: ${_formatTime(syncProvider.lastSyncTime!)}'
                          : 'Not backed up yet',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.textMuted
                            : const Color(0xFF64748B),
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
                        : () => syncProvider.syncAll(),
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
