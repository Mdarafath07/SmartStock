import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/services/connectivity_service.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/core/widgets/status_badge.dart';
import 'package:smartstock/features/product_issues/providers/product_issue_provider.dart';

class ProductIssueDetailsScreen extends StatefulWidget {
  final String issueId;

  const ProductIssueDetailsScreen({super.key, required this.issueId});

  @override
  State<ProductIssueDetailsScreen> createState() =>
      _ProductIssueDetailsScreenState();
}

class _ProductIssueDetailsScreenState extends State<ProductIssueDetailsScreen> {
  final _resolutionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductIssueProvider>().loadIssueById(widget.issueId);
    });
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details'),
      ),
      body: Consumer<ProductIssueProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedIssue == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final issue = provider.selectedIssue;
          if (issue == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.surfaceLighter : AppColors.whiteMuted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.info_outline,
                        size: 32, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  const Text('Issue not found'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(issue.status),
                const SizedBox(height: 16),
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(Icons.inventory_2, AppColors.blue,
                          'Product Information'),
                      const SizedBox(height: 16),
                      _infoRow('Product', issue.productName),
                      _infoRow('Model', issue.modelNumber),
                      _infoRow('Serial Number', issue.serialNumber),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(Icons.report_problem, AppColors.orange,
                          'Issue Details'),
                      const SizedBox(height: 16),
                      _infoRow('Type', _getIssueTypeLabel(issue.issueType)),
                      _infoRow('Description', issue.issueDescription),
                      _infoRow('Reported', _formatDate(issue.createdAt)),
                    ],
                  ),
                ),
                if (issue.customerName != null) ...[
                  const SizedBox(height: 12),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(
                            Icons.person, AppColors.green, 'Customer Info'),
                        const SizedBox(height: 16),
                        _infoRow('Name', issue.customerName!),
                        if (issue.customerPhone != null)
                          _infoRow('Phone', issue.customerPhone!),
                      ],
                    ),
                  ),
                ],
                if (issue.status == 'resolved') ...[
                  const SizedBox(height: 12),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(Icons.check_circle, AppColors.green,
                            'Resolution'),
                        const SizedBox(height: 16),
                        if (issue.resolutionNotes != null)
                          _infoRow('Notes', issue.resolutionNotes!),
                        if (issue.resolvedAt != null)
                          _infoRow(
                              'Resolved At', _formatDate(issue.resolvedAt!)),
                      ],
                    ),
                  ),
                ],
                if (issue.status != 'resolved') ...[
                  const SizedBox(height: 24),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(Icons.check_circle_rounded,
                            AppColors.green, 'Resolve Issue'),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _resolutionController,
                          decoration: InputDecoration(
                            hintText: 'Enter resolution notes...',
                            filled: true,
                            fillColor: isDark
                                ? AppColors.surfaceLighter
                                : AppColors.whiteSoft,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _resolveIssue,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Mark as Resolved'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (issue.status != 'resolved')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteIssue(issue.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: BorderSide(
                            color: AppColors.red.withAlpha(60)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete Issue'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(IconData icon, Color color, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.titleSm),
      ],
    );
  }

  Widget _buildStatusHeader(String status) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'open':
        color = AppColors.red;
        label = 'Open';
        icon = Icons.bug_report;
      case 'in_progress':
        color = AppColors.orange;
        label = 'In Progress';
        icon = Icons.engineering;
      case 'resolved':
        color = AppColors.green;
        label = 'Resolved';
        icon = Icons.check_circle;
      default:
        color = AppColors.grey;
        label = status;
        icon = Icons.help;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.headlineSm.copyWith(color: color),
              ),
              const SizedBox(height: 2),
              Text(
                'Issue #${widget.issueId.length > 8 ? widget.issueId.substring(0, 8) : widget.issueId}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          StatusBadge.issueStatus(status),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySm.copyWith(
                color: isDark
                    ? AppColors.textPrimary
                    : const Color(0xFF1A1A2E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveIssue() async {
    if (_isSubmitting) return;
    final notes = _resolutionController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add resolution notes')),
      );
      return;
    }

    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.canWrite()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please connect to resolve.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context
          .read<ProductIssueProvider>()
          .resolveIssue(widget.issueId, notes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Issue resolved — product returned to stock')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resolve: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteIssue(String id) async {
    if (_isSubmitting) return;
    final provider = context.read<ProductIssueProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Issue'),
        content:
            const Text('Are you sure you want to delete this issue?'),
        actions: [
          Debounced(
            onPressed: () => Navigator.pop(ctx, false),
            builder: (_, isDisabled) => TextButton(
              onPressed:
                  isDisabled ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
          ),
          Debounced(
            onPressed: () => Navigator.pop(ctx, true),
            builder: (_, isDisabled) => TextButton(
              onPressed:
                  isDisabled ? null : () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.red)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSubmitting = true);
      try {
        await provider.deleteIssue(id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getIssueTypeLabel(String type) {
    switch (type) {
      case 'defect':
        return 'Defect';
      case 'damage':
        return 'Physical Damage';
      case 'malfunction':
        return 'Malfunction';
      case 'wrong_item':
        return 'Wrong Item';
      case 'cosmetic':
        return 'Cosmetic Issue';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }
}
