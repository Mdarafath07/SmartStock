import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/core/widgets/status_badge.dart';
import 'package:smartstock/core/widgets/error_widget.dart';
import 'package:smartstock/features/product_issues/providers/product_issue_provider.dart';
import 'package:smartstock/features/product_issues/screens/add_product_issue_screen.dart';
import 'package:smartstock/features/product_issues/screens/product_issue_details_screen.dart';

class ProductIssueListScreen extends StatefulWidget {
  const ProductIssueListScreen({super.key});

  @override
  State<ProductIssueListScreen> createState() => _ProductIssueListScreenState();
}

class _ProductIssueListScreenState extends State<ProductIssueListScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductIssueProvider>().loadIssues();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ProductIssueProvider>().loadIssues();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Issues'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceLighter : AppColors.whiteMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: AppTextStyles.labelSm,
                unselectedLabelStyle: AppTextStyles.labelSm,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Open'),
                  Tab(text: 'In Progress'),
                  Tab(text: 'Resolved'),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddProductIssueScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<ProductIssueProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.issues.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.loadIssues(),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildIssueList(provider.openIssues, 'open'),
              _buildIssueList(provider.inProgressIssues, 'in_progress'),
              _buildIssueList(provider.resolvedIssues, 'resolved'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIssueList(List list, String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceLighter : AppColors.whiteMuted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                status == 'resolved'
                    ? Icons.check_circle_outline
                    : Icons.bug_report_outlined,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              status == 'resolved'
                  ? 'No resolved issues'
                  : status == 'in_progress'
                      ? 'No in-progress issues'
                      : 'No open issues',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => context.read<ProductIssueProvider>().loadIssues(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final issue = list[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ModernCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductIssueDetailsScreen(issueId: issue.id),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(issue.status).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bug_report_rounded,
                      size: 20,
                      color: _getStatusColor(issue.status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.productName,
                          style: AppTextStyles.titleSm.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SN: ${issue.serialNumber}',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          issue.issueDescription.length > 60
                              ? '${issue.issueDescription.substring(0, 60)}...'
                              : issue.issueDescription,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge.issueStatus(issue.status),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.error;
      case 'in_progress':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      default:
        return AppColors.grey;
    }
  }
}
