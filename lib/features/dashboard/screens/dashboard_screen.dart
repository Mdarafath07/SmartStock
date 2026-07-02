import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/features/dashboard/providers/dashboard_provider.dart';
import 'package:smartstock/features/dashboard/models/dashboard_stats_model.dart';

class DashboardScreen extends StatefulWidget {
  final bool insideShell;
  const DashboardScreen({super.key, this.insideShell = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoRefresh();
      context.read<DashboardProvider>().loadDashboardStats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => context.read<DashboardProvider>().refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DashboardProvider>().refresh();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.stats == null) {
          return _buildSkeletonLoading();
        }
        if (provider.error != null && provider.stats == null) {
          return _buildErrorState(provider);
        }
        return RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 12, 16, 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(context, provider),
                const SizedBox(height: 20),
                _buildSummaryCards(context, provider.stats!),
                const SizedBox(height: 20),
                _buildAnalyticsSection(context, provider.stats!),
                const SizedBox(height: 20),
                _buildBusinessHealth(context, provider.stats!),
                const SizedBox(height: 20),
                _buildActivitySection(context, provider.stats!),
                const SizedBox(height: 20),
                _buildRecentAddedProducts(context, provider.stats!),
                const SizedBox(height: 20),
                _buildTopSelling(context, provider.stats!),
                const SizedBox(height: 20),
                _buildQuickActions(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, DashboardProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ModernCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        colors: isDark
            ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
            : [AppColors.greenDark, AppColors.greenLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getTimeGreeting()},',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: Colors.white.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome Back!',
                      style: AppTextStyles.displaySm.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _WelcomeStat(
                label: "Today's Revenue",
                value: '\$${provider.stats?.todaySalesAmount.toStringAsFixed(0) ?? '0'}',
                icon: Icons.trending_up_rounded,
              ),
              const SizedBox(width: 16),
              _WelcomeStat(
                label: 'Products Sold',
                value: '${provider.stats?.todaySoldProducts ?? 0}',
                icon: Icons.shopping_bag_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Overview', 'Your business at a glance'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Total Products',
                value: '${stats.totalProducts}',
                icon: Icons.inventory_2_rounded,
                iconColor: AppColors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Total Stock',
                value: '${stats.totalAvailableStock}',
                icon: Icons.warehouse_rounded,
                iconColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: "Today's Revenue",
                value: '\$${stats.todaySalesAmount.toStringAsFixed(0)}',
                icon: Icons.attach_money_rounded,
                iconColor: AppColors.green,
                change: 12.5,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Sold Today',
                value: '${stats.todaySoldProducts}',
                icon: Icons.shopping_cart_rounded,
                iconColor: AppColors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Low Stock Items',
                value: '${stats.lowStockProducts}',
                icon: Icons.warning_rounded,
                iconColor: AppColors.orange,
                subtitle: 'Need immediate restock',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Out of Stock',
                value: '${stats.outOfStockProducts}',
                icon: Icons.error_outline_rounded,
                iconColor: AppColors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, DashboardStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Analytics', 'Sales & inventory insights'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniChartCard(
                title: 'Sales Trend',
                value: '\$${stats.todaySalesAmount.toStringAsFixed(0)}',
                percentage: '+12.5%',
                isUp: true,
                bars: [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.75],
                color: AppColors.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniChartCard(
                title: 'Revenue',
                value: '\$${(stats.todaySalesAmount * 3).toStringAsFixed(0)}',
                percentage: '+8.3%',
                isUp: true,
                bars: [0.5, 0.6, 0.45, 0.75, 0.65, 0.85, 0.7],
                color: AppColors.blue,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniChartCard(
                title: 'Stock Growth',
                value: '${stats.totalAvailableStock}',
                percentage: '+5.2%',
                isUp: true,
                bars: [0.6, 0.55, 0.65, 0.6, 0.7, 0.68, 0.75],
                color: AppColors.purple,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniChartCard(
                title: 'Profit Margin',
                value: '${_calculateProfitMargin(stats).toStringAsFixed(1)}%',
                percentage: '+2.1%',
                isUp: true,
                bars: [0.4, 0.45, 0.5, 0.48, 0.52, 0.55, 0.53],
                color: AppColors.orange,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessHealth(BuildContext context, DashboardStats stats) {
    final healthScore = _calculateHealthScore(stats);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Business Health', 'Overall performance score'),
        const SizedBox(height: 12),
        ModernCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: healthScore / 100,
                        strokeWidth: 6,
                        backgroundColor: AppColors.greyDarker.withAlpha(60),
                        valueColor: AlwaysStoppedAnimation(
                          healthScore >= 80
                              ? AppColors.green
                              : healthScore >= 60
                                  ? AppColors.orange
                                  : AppColors.red,
                        ),
                      ),
                    ),
                    Text(
                      '${healthScore.toStringAsFixed(0)}',
                      style: AppTextStyles.amountMd.copyWith(
                        color: healthScore >= 80
                            ? AppColors.green
                            : healthScore >= 60
                                ? AppColors.orange
                                : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      healthScore >= 80
                          ? 'Excellent Health'
                          : healthScore >= 60
                              ? 'Good Health'
                              : 'Needs Attention',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMd.copyWith(
                        color: _getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _HealthMetric(
                      label: 'Stock Health',
                      value: _calculateStockHealth(stats),
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                    const SizedBox(height: 4),
                    _HealthMetric(
                      label: 'Sales Momentum',
                      value: _calculateSalesMomentum(stats),
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                    const SizedBox(height: 4),
                    _HealthMetric(
                      label: 'Inventory Turnover',
                      value: _calculateTurnover(stats),
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, DashboardStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Recent Activity', 'Latest updates from your shop'),
        const SizedBox(height: 12),
        ModernCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ActivityTile(
                icon: Icons.add_circle_rounded,
                title: 'Products Added Today',
                value: '${stats.recentlyAddedProducts.length}',
                color: AppColors.primary,
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, AppRoutes.dailyAdditions),
              ),
              const Divider(height: 1),
              _ActivityTile(
                icon: Icons.shopping_cart_rounded,
                title: 'Products Sold Today',
                value: '${stats.todaySoldProducts}',
                color: AppColors.blue,
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, AppRoutes.salesToday),
              ),
              const Divider(height: 1),
              _ActivityTile(
                icon: Icons.warning_rounded,
                title: 'Low Stock Warnings',
                value: '${stats.lowStockProducts}',
                color: AppColors.orange,
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
              ),
              const Divider(height: 1),
              _ActivityTile(
                icon: Icons.verified_rounded,
                title: 'Active Warranties',
                value: '${stats.totalProducts ~/ 2}',
                color: AppColors.purple,
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, AppRoutes.warranty),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAddedProducts(BuildContext context, DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Recently Added', 'Latest products in inventory'),
        const SizedBox(height: 12),
        Column(
          children: stats.recentlyAddedProducts.take(5).map((product) {
            return _ProductRow(
              product: product,
              isDark: Theme.of(context).brightness == Brightness.dark,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.productsDetails,
                arguments: product.productId,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopSelling(BuildContext context, DashboardStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Top Selling', 'Best performing products'),
        const SizedBox(height: 12),
        if (stats.topSellingProducts.isEmpty)
          ModernCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.trending_flat_rounded, size: 40, color: isDark ? AppColors.greyDarker : const Color(0xFFD1D5DB)),
                  const SizedBox(height: 8),
                  Text('No sales data yet', style: AppTextStyles.bodyMd.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
                ],
              ),
            ),
          )
        else
          ...stats.topSellingProducts.take(5).map((product) {
            return _TopSellingRow(
              product: product,
              rank: stats.topSellingProducts.indexOf(product) + 1,
              isDark: isDark,
            );
          }),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Quick Actions', 'Frequently used tasks'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_circle_rounded,
                label: 'Add Product',
                color: AppColors.primary,
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, AppRoutes.productsAdd),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.add_shopping_cart_rounded,
                label: 'New Sale',
                color: AppColors.blue,
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, AppRoutes.salesNew),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.post_add_rounded,
                label: 'Add Stock',
                color: AppColors.orange,
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, AppRoutes.dailyAdditions),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.assessment_rounded,
                label: 'Reports',
                color: AppColors.purple,
                isDark: isDark,
                onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    final isDark = true;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBlock(height: 120, isDark: isDark),
          const SizedBox(height: 20),
          _buildSectionTitleSkeleton(isDark),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _SkeletonBlock(height: 100, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _SkeletonBlock(height: 100, isDark: isDark)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SkeletonBlock(height: 100, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _SkeletonBlock(height: 100, isDark: isDark)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SkeletonBlock(height: 100, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _SkeletonBlock(height: 100, isDark: isDark)),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitleSkeleton(isDark),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _SkeletonBlock(height: 140, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _SkeletonBlock(height: 140, isDark: isDark)),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitleSkeleton(isDark),
          const SizedBox(height: 12),
          _SkeletonBlock(height: 200, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildSectionTitleSkeleton(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBlock(height: 16, width: 160, isDark: isDark),
        const SizedBox(height: 4),
        _SkeletonBlock(height: 12, width: 120, isDark: isDark),
      ],
    );
  }

  Widget _buildErrorState(DashboardProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.redBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.red),
            ),
            const SizedBox(height: 20),
            Text(
              'Connection Error',
              style: AppTextStyles.headlineMd.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Something went wrong',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headlineSm.copyWith(
            color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySm.copyWith(
            color: isDark ? AppColors.textMuted : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  double _calculateHealthScore(DashboardStats stats) {
    double score = 70;
    if (stats.totalProducts > 0) score += 10;
    if (stats.totalAvailableStock > stats.totalProducts) score += 5;
    if (stats.todaySalesAmount > 0) score += 10;
    if (stats.lowStockProducts == 0) score += 10;
    if (stats.outOfStockProducts == 0) score += 5;
    return score.clamp(0, 100);
  }

  double _calculateStockHealth(DashboardStats stats) {
    if (stats.totalProducts == 0) return 0;
    final healthyStock = stats.totalProducts - stats.lowStockProducts - stats.outOfStockProducts;
    return (healthyStock / stats.totalProducts * 100).clamp(0, 100);
  }

  double _calculateSalesMomentum(DashboardStats stats) {
    if (stats.totalProducts == 0) return 0;
    return (stats.todaySoldProducts / stats.totalProducts * 100).clamp(0, 100);
  }

  double _calculateTurnover(DashboardStats stats) {
    if (stats.totalAvailableStock == 0 && stats.todaySoldProducts == 0) return 0;
    final total = stats.totalAvailableStock + stats.todaySoldProducts;
    if (total == 0) return 0;
    return (stats.todaySoldProducts / total * 100).clamp(0, 100);
  }

  double _calculateProfitMargin(DashboardStats stats) {
    if (stats.todaySalesAmount == 0) return 0;
    return 25.5;
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textPrimary
        : const Color(0xFF1A1A2E);
  }
}

class _WelcomeStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _WelcomeStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withAlpha(180)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white.withAlpha(160))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniChartCard extends StatelessWidget {
  final String title;
  final String value;
  final String percentage;
  final bool isUp;
  final List<double> bars;
  final Color color;
  final bool isDark;

  const _MiniChartCard({
    required this.title,
    required this.value,
    required this.percentage,
    required this.isUp,
    required this.bars,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isUp ? AppColors.greenBg : AppColors.redBg).withAlpha(180),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isUp ? Icons.trending_up : Icons.trending_down, size: 10, color: isUp ? AppColors.green : AppColors.red),
                    const SizedBox(width: 2),
                    Text(percentage, style: TextStyle(fontFamily: 'Geist', fontSize: 9, fontWeight: FontWeight.w600, color: isUp ? AppColors.green : AppColors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.amountSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((bar) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: 32 * bar,
                    decoration: BoxDecoration(
                      color: color.withAlpha(120),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final String label;
  final double value;
  final bool isDark;

  const _HealthMetric({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.greyDarker.withAlpha(80) : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(
                value >= 70 ? AppColors.green : value >= 40 ? AppColors.orange : AppColors.red,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${value.toStringAsFixed(0)}%',
            style: AppTextStyles.labelSm.copyWith(color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value, style: AppTextStyles.labelMd.copyWith(color: color, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final ProductSummary product;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductRow({required this.product, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      color: isDark ? AppColors.cardDark.withAlpha(150) : Colors.white.withAlpha(200),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_rounded, size: 20, color: AppColors.textMuted)))
                : Icon(Icons.inventory_2_rounded, size: 20, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E))),
                Text('${product.modelNumber} · ${product.categoryName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${product.availableQuantity} in stock', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.labelSm.copyWith(color: AppColors.green)),
          ),
        ],
      ),
    );
  }
}

class _TopSellingRow extends StatelessWidget {
  final TopSellingProduct product;
  final int rank;
  final bool isDark;

  const _TopSellingRow({required this.product, required this.rank, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.primary, AppColors.blue, AppColors.purple, AppColors.orange, AppColors.green];
    final color = colors[rank - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.cardDark : Colors.white).withAlpha(180),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$rank', style: AppTextStyles.labelMd.copyWith(color: color, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMd.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E), fontWeight: FontWeight.w600)),
                Text(product.modelNumber, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${product.totalSold} sold', style: AppTextStyles.labelSm.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.cardDark : Colors.white).withAlpha(200),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (isDark ? AppColors.greyDarker : const Color(0xFFE5E7EB)).withAlpha(60), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.labelSm.copyWith(color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double height;
  final double? width;
  final bool isDark;

  const _SkeletonBlock({required this.height, this.width, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppColors.shimmerBase : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
