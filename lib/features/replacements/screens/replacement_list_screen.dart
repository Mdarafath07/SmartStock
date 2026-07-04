import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/core/widgets/status_badge.dart';
import 'package:smartstock/core/widgets/error_widget.dart';
import 'package:smartstock/features/replacements/providers/replacement_provider.dart';
import 'package:smartstock/features/replacements/screens/add_replacement_screen.dart';
import 'package:smartstock/features/replacements/screens/replacement_details_screen.dart';

class ReplacementListScreen extends StatefulWidget {
  const ReplacementListScreen({super.key});

  @override
  State<ReplacementListScreen> createState() => _ReplacementListScreenState();
}

class _ReplacementListScreenState extends State<ReplacementListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReplacementProvider>().loadReplacements();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldBg : AppColors.whiteSoft,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.glassBg : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF475569)),
                    ),
                  ),
                  Text(
                    'Replacements',
                    style: AppTextStyles.headlineMd.copyWith(
                      color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.orangeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded, color: AppColors.orange),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddReplacementScreen(),
                          ),
                        );
                      },
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.orangeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                dividerColor: Colors.transparent,
                labelColor: AppColors.orange,
                unselectedLabelColor: isDark ? AppColors.textMuted : const Color(0xFF6B7280),
                labelStyle: AppTextStyles.labelMd,
                unselectedLabelStyle: AppTextStyles.labelMd,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<ReplacementProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.replacements.isEmpty) {
                    return const Center(child: CircularProgressIndicator(
                      color: AppColors.orange,
                    ));
                  }

                  if (provider.error != null) {
                    return AppErrorWidget(
                      message: provider.error!,
                      onRetry: () => provider.loadReplacements(),
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(provider.replacements, isDark),
                      _buildList(provider.pendingReplacements, isDark),
                      _buildList(provider.completedReplacements, isDark),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> list, bool isDark) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 56,
              color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              'No records found',
              style: AppTextStyles.titleSm.copyWith(
                color: isDark ? AppColors.textMuted : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<ReplacementProvider>().loadReplacements(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final statusBadge = _buildStatusBadge(item.status);
          return ModernCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.zero,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReplacementDetailsScreen(replacementId: item.id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.orangeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 20,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: AppTextStyles.titleSm.copyWith(
                            color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SN: ${item.oldSerialNumber}',
                          style: AppTextStyles.bodySm.copyWith(
                            color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          item.customerName,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  statusBadge,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'pending':
        return const StatusBadge(label: 'Pending', color: AppColors.orange, icon: Icons.schedule_rounded);
      case 'completed':
        return const StatusBadge(label: 'Completed', color: AppColors.green, icon: Icons.check_circle_rounded);
      case 'rejected':
        return const StatusBadge(label: 'Rejected', color: AppColors.red, icon: Icons.cancel_rounded);
      default:
        return StatusBadge(label: status, color: AppColors.grey);
    }
  }
}
