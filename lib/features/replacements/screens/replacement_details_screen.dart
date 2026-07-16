import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/features/replacements/models/replacement_model.dart';
import 'package:smartstock/features/replacements/providers/replacement_provider.dart';
import 'package:smartstock/features/sales/providers/sale_provider.dart';
import 'package:smartstock/features/sales/screens/sale_details_screen.dart';

class ReplacementDetailsScreen extends StatefulWidget {
  final String replacementId;

  const ReplacementDetailsScreen({super.key, required this.replacementId});

  @override
  State<ReplacementDetailsScreen> createState() =>
      _ReplacementDetailsScreenState();
}

class _ReplacementDetailsScreenState extends State<ReplacementDetailsScreen> with WidgetsBindingObserver {
  final _serialController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  void _load() {
    context.read<ReplacementProvider>().loadReplacementById(widget.replacementId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replacement Details'),
      ),
      body: Consumer<ReplacementProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedReplacement == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final item = provider.selectedReplacement;
          if (item == null) {
            return const Center(child: Text('Request not found'));
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ReplacementProvider>().loadReplacementById(widget.replacementId),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(item),
                const SizedBox(height: 16),
                _buildInfoCard('Product Information', [
                  _infoRow('Product', item.productName),
                  _infoRow('Model', item.modelNumber),
                  _infoRow('Old Serial', item.oldSerialNumber),
                  if (item.newSerialNumber != null)
                    _infoRow('New Serial', item.newSerialNumber!),
                ]),
                const SizedBox(height: 12),
                _buildInfoCard('Request Details', [
                  _infoRow('Reason', item.reason),
                  if (item.notes != null) _infoRow('Notes', item.notes!),
                  _infoRow('Date', _formatDate(item.createdAt)),
                ]),
                const SizedBox(height: 12),
                _buildInfoCard('Customer Info', [
                  _infoRow('Name', item.customerName),
                  _infoRow('Phone', item.customerPhone),
                ]),
                if (item.status == 'completed' && item.saleId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSaleLinkButton(item.saleId),
                ],
                if (item.status == 'pending') ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: _serialController,
                    decoration: const InputDecoration(
                      labelText: 'New Serial Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _complete(item),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Complete'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reject(item.id),
                          icon: const Icon(Icons.cancel, color: AppColors.error),
                          label: const Text('Reject',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildSaleLinkButton(String saleId) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt, color: AppColors.primary),
        title: const Text('View Sale Record'),
        subtitle: const Text('Tap to see the sale created for this replacement'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final saleProvider = context.read<SaleProvider>();
          await saleProvider.loadSaleById(saleId);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SaleDetailsScreen(saleId: saleId),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildStatusHeader(Replacement item) {
    Color color;
    String label;
    IconData icon;
    switch (item.status) {
      case 'pending':
        color = AppColors.warning;
        label = 'Pending';
        icon = Icons.hourglass_empty;
      case 'completed':
        color = AppColors.success;
        label = 'Completed';
        icon = Icons.check_circle;
      case 'rejected':
        color = AppColors.error;
        label = 'Rejected';
        icon = Icons.cancel;
      default:
        color = const Color(0xFF454652);
        label = item.status;
        icon = Icons.help;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.titleMd.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.titleMd.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.labelMd.copyWith(
                    color: const Color(0xFF454652))),
          ),
          Expanded(
            child: Text(value,
                style:
                    AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _complete(Replacement item) async {
    final newSerial = _serialController.text.trim();
    if (newSerial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New serial number is required')),
      );
      return;
    }

    try {
      await context.read<ReplacementProvider>().completeReplacement(
        widget.replacementId,
        newSerialNumber: newSerial,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Replacement completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _reject(String id) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            border: OutlineInputBorder(),
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
            onPressed: () => Navigator.pop(ctx, controller.text),
            builder: (_, isDisabled) => TextButton(
              onPressed: isDisabled ? null : () => Navigator.pop(ctx, controller.text),
              child: const Text('Reject',
                  style: TextStyle(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        if (!mounted) return;
        await context
            .read<ReplacementProvider>()
            .rejectReplacement(id, reason: reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request rejected')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
