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
            : [AppColors.primary, AppColors.primary.withAlpha(180)],
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
                label: "Today's Profit",
                value: provider.stats?.todayProfit != null ? '\$${provider.stats!.todayProfit.toStringAsFixed(0)}' : '\$0',
                icon: Icons.trending_up_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, DashboardStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final instock = stats.totalProducts - stats.outOfStockProducts;
    final stockedRatio = stats.totalProducts > 0 ? (instock / stats.totalProducts).clamp(0.05, 1.0) : 0.05;
    final stockVsProducts = stats.totalProducts > 0 ? (stats.totalAvailableStock / (stats.totalProducts * 5)).clamp(0.05, 1.0) : 0.05;
    final catRatio = stats.totalProducts > 0 ? (stats.totalCategories / stats.totalProducts * 3).clamp(0.05, 1.0) : 0.05;
    final sellThrough = (stats.todaySoldProducts + stats.totalAvailableStock) > 0
        ? (stats.todaySoldProducts / (stats.todaySoldProducts + stats.totalAvailableStock)).clamp(0.05, 1.0)
        : 0.05;
    final lowStockRatio = stats.totalProducts > 0 ? (stats.lowStockProducts / stats.totalProducts).clamp(0.05, 1.0) : 0.05;
    final oosRatio = stats.totalProducts > 0 ? (stats.outOfStockProducts / stats.totalProducts).clamp(0.05, 1.0) : 0.05;

    final cards = <_OverviewCardData>[
      _OverviewCardData(label: 'Total Products', value: '${stats.totalProducts}', icon: Icons.inventory_2_rounded, color: AppColors.blue, bar: stockedRatio, route: AppRoutes.products),
      _OverviewCardData(label: 'Total Stock', value: '${stats.totalAvailableStock}', icon: Icons.warehouse_rounded, color: AppColors.primary, bar: stockVsProducts, route: AppRoutes.inventory),
      _OverviewCardData(label: 'Categories', value: '${stats.totalCategories}', icon: Icons.category_rounded, color: AppColors.green, bar: catRatio, route: AppRoutes.categories),
      _OverviewCardData(label: 'Sold Today', value: '${stats.todaySoldProducts}', icon: Icons.shopping_cart_rounded, color: AppColors.purple, bar: sellThrough, route: AppRoutes.salesToday),
      _OverviewCardData(label: 'Low Stock', value: '${stats.lowStockProducts}', icon: Icons.warning_rounded, color: AppColors.orange, bar: lowStockRatio, route: AppRoutes.inventory),
      _OverviewCardData(label: 'Out of Stock', value: '${stats.outOfStockProducts}', icon: Icons.error_outline_rounded, color: AppColors.red, bar: oosRatio, route: AppRoutes.inventory),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Overview', 'Your business at a glance'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards.map((c) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 42) / 2,
              child: GestureDetector(
                onTap: c.route != null ? () => Navigator.pushNamed(context, c.route!) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
                      BoxShadow(color: c.color.withAlpha(6), blurRadius: 20, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Positioned(
                            right: -6, top: -6,
                            child: Icon(c.icon, size: 48, color: c.color.withAlpha(10)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [c.color.withAlpha(30), c.color.withAlpha(10)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(c.icon, size: 14, color: c.color),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  c.value,
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    height: 0.95,
                                    color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  c.label,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 2.5,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: c.color.withAlpha(15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: c.bar,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [c.color, c.color.withAlpha(120)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<double> _normalizeBars(List<double> values) {
    if (values.isEmpty) return List.filled(7, 0.1);
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max == 0) return List.filled(values.length, 0.1);
    return values.map((v) => (v / max).clamp(0.05, 1.0)).toList();
  }

  Widget _buildAnalyticsSection(BuildContext context, DashboardStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final salesBars = _normalizeBars(stats.dailySales);
    final profitBars = _normalizeBars(stats.dailyProfit);
    final weeklyAvg = stats.dailySales.isNotEmpty
        ? stats.dailySales.reduce((a, b) => a + b) / stats.dailySales.length
        : 0.0;
    final todayVsAvg = weeklyAvg > 0
        ? ((stats.todaySalesAmount - weeklyAvg) / weeklyAvg * 100)
        : 0.0;

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
                percentage: '${todayVsAvg >= 0 ? '+' : ''}${todayVsAvg.toStringAsFixed(1)}%',
                isUp: todayVsAvg >= 0,
                bars: salesBars,
                color: AppColors.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniChartCard(
                title: 'Profit Trend',
                value: '\$${stats.todayProfit.toStringAsFixed(0)}',
                percentage: '+${stats.dailyProfit.isNotEmpty && stats.dailyProfit.length > 1 ? ((stats.dailyProfit.last - stats.dailyProfit.first) / (stats.dailyProfit.first.abs().clamp(1, double.infinity)) * 100).toStringAsFixed(1) : '0'}%',
                isUp: stats.dailyProfit.isEmpty || stats.dailyProfit.last >= (stats.dailyProfit.length > 1 ? stats.dailyProfit.first : 0),
                bars: profitBars,
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
                percentage: '+${stats.recentlyAddedProducts.isNotEmpty ? ((stats.recentlyAddedProducts.length / stats.totalProducts.clamp(1, double.infinity)) * 100).toStringAsFixed(1) : '0'}%',
                isUp: stats.recentlyAddedProducts.isNotEmpty,
                bars: [0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6],
                color: AppColors.purple,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniChartCard(
                title: 'Profit Margin',
                value: '${_calculateProfitMargin(stats).toStringAsFixed(1)}%',
                percentage: stats.todayProfit > 0 ? '+${(stats.todayProfit / stats.todaySalesAmount.clamp(1, double.infinity) * 100).toStringAsFixed(1)}%' : '0%',
                isUp: stats.todayProfit > 0,
                bars: profitBars.isNotEmpty ? profitBars.sublist(0, profitBars.length > 4 ? 4 : profitBars.length) : [0.1],
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
                      healthScore.toStringAsFixed(0),
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
    final actions = <_QuickAction>[
      _QuickAction(icon: Icons.add_circle_rounded, label: 'Add Product', color: AppColors.primary, route: AppRoutes.productsAdd),
      _QuickAction(icon: Icons.add_shopping_cart_rounded, label: 'New Sale', color: AppColors.green, route: AppRoutes.salesNew),
      _QuickAction(icon: Icons.post_add_rounded, label: 'Add Stock', color: AppColors.orange, route: AppRoutes.dailyAdditions),
      _QuickAction(icon: Icons.inventory_2_rounded, label: 'Products', color: AppColors.blue, route: AppRoutes.products),
      _QuickAction(icon: Icons.warehouse_rounded, label: 'Inventory', color: AppColors.teal, route: AppRoutes.inventory),
      _QuickAction(icon: Icons.category_rounded, label: 'Categories', color: AppColors.purple, route: AppRoutes.categories),
      _QuickAction(icon: Icons.people_rounded, label: 'Customers', color: AppColors.pink, route: AppRoutes.customers),
      _QuickAction(icon: Icons.history_rounded, label: 'Sales History', color: AppColors.purple, route: AppRoutes.salesHistory),
      _QuickAction(icon: Icons.today_rounded, label: "Today's Sales", color: AppColors.orange, route: AppRoutes.salesToday),
      _QuickAction(icon: Icons.assessment_rounded, label: 'Reports', color: AppColors.red, route: AppRoutes.reports),
      _QuickAction(icon: Icons.verified_rounded, label: 'Warranty', color: AppColors.teal, route: AppRoutes.warranty),
      _QuickAction(icon: Icons.bug_report_rounded, label: 'Issues', color: AppColors.red, route: AppRoutes.productIssues),
      _QuickAction(icon: Icons.swap_horiz_rounded, label: 'Replacements', color: AppColors.orange, route: AppRoutes.replacements),
      _QuickAction(icon: Icons.search_rounded, label: 'Search', color: AppColors.grey, route: AppRoutes.search),
      _QuickAction(icon: Icons.settings_rounded, label: 'Settings', color: AppColors.greyDark, route: AppRoutes.settings),
    ];
    final itemWidth = (MediaQuery.of(context).size.width - 56) / 4;
    final totalItems = actions.length;
    final remainder = totalItems % 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Quick Actions', 'All app pages'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...actions.map((a) {
            return SizedBox(
              width: itemWidth,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, a.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: a.color.withAlpha(20),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: a.color.withAlpha(10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              a.color.withAlpha(30),
                              a.color.withAlpha(10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(a.icon, size: 16, color: a.color),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (remainder > 0) ...[
            ...List.generate(4 - remainder, (_) => SizedBox(width: itemWidth)),
          ],
        ],
      ),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    final isDark = true;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 100),
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
    return (stats.todayProfit / stats.todaySalesAmount) * 100;
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(25), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white.withAlpha(180), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                ],
              ),
            ),
          ],
        ),
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
      gradient: LinearGradient(
        colors: [
          color.withAlpha(12),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  title == 'Sales Trend' ? Icons.trending_up_rounded :
                  title == 'Revenue' ? Icons.attach_money_rounded :
                  title == 'Stock Growth' ? Icons.inventory_2_rounded :
                  Icons.pie_chart_rounded,
                  size: 15, color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: (isUp ? AppColors.greenBg : AppColors.redBg).withAlpha(200),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isUp ? Icons.trending_up : Icons.trending_down, size: 10, color: isUp ? AppColors.green : AppColors.red),
                    const SizedBox(width: 2),
                    Text(percentage, style: TextStyle(fontFamily: 'Geist', fontSize: 9, fontWeight: FontWeight.w700, color: isUp ? AppColors.green : AppColors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : const Color(0xFF6B7280))),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.amountSm.copyWith(color: isDark ? AppColors.textPrimary : const Color(0xFF1A1A2E), fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((bar) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    height: 32 * bar,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withAlpha(180), color.withAlpha(60)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
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
        gradient: LinearGradient(
          colors: [
            (isDark ? AppColors.cardDark : Colors.white).withAlpha(200),
            (isDark ? AppColors.cardDark : Colors.white).withAlpha(160),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(25), width: 0.5),
        boxShadow: [
          BoxShadow(color: color.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha(30), color.withAlpha(15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('$rank', style: AppTextStyles.labelMd.copyWith(color: color, fontWeight: FontWeight.w800)),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha(30), color.withAlpha(15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${product.totalSold} sold', style: AppTextStyles.labelSm.copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.route});
}

class _OverviewCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double bar;
  final String? route;
  const _OverviewCardData({required this.label, required this.value, required this.icon, required this.color, this.bar = 0.5, this.route});
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
