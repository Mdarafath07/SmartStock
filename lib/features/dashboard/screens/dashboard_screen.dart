import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/dashboard/providers/dashboard_provider.dart';
import 'package:smartstock/features/dashboard/models/dashboard_stats_model.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:smartstock/core/widgets/animated_counter.dart';

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
      const Duration(seconds: 120),
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
                _buildHeader(context, provider),
                const SizedBox(height: 20),
                _buildKpiRow(context, provider.stats!),
                const SizedBox(height: 20),
                _buildStatsGrid(context, provider.stats!),
                const SizedBox(height: 20),
                _buildAnalyticsRow(context, provider.stats!),
                const SizedBox(height: 20),
                _buildHealthAndTopSelling(context, provider.stats!),
                const SizedBox(height: 20),
                _buildActivity(context, provider.stats!),
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

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Night';
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    if (h < 21) return 'Evening';
    return 'Night';
  }

  // ─── HEADER ───────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, DashboardProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final storeName = settings.storeName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
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
                      'Good ${_timeGreeting()}!',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _iconFromAsset(Icons.store_rounded, size: 22, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Revenue",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedCounter(
                          target: provider.stats?.todaySalesAmount ?? 0,
                          prefix: symbol,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withAlpha(20),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Profit",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AnimatedCounter(
                            target: provider.stats?.todayProfit ?? 0,
                            prefix: symbol,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtAmount(double v) {
    final neg = v < 0;
    final a = neg ? -v : v;
    final p = a.toStringAsFixed(0).split('.');
    final b = StringBuffer();
    int c = 0;
    for (int i = p[0].length - 1; i >= 0; i--) {
      if (c > 0 && c % 3 == 0) b.write(',');
      b.write(p[0][i]);
      c++;
    }
    final r = b.toString().split('').reversed.join();
    return neg ? '-$r' : r;
  }

  // ─── KPI ROW ──────────────────────────────────────────────

  Widget _buildKpiRow(BuildContext context, DashboardStats stats) {
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            label: 'Selling Value',
            value: '$symbol${_fmtAmount(stats.totalStockValue)}',
            subtitle: 'At customer price',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
            label: 'Stock Cost',
            value: '$symbol${_fmtAmount(stats.totalStockCost)}',
            subtitle: 'Total invested',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2A3E)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111111),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATS GRID ───────────────────────────────────────────

  Widget _buildStatsGrid(BuildContext context, DashboardStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = stats.totalProducts > 0 ? stats.totalProducts : 1;

    final stockGroups = [
      _GroupData('Products', [
        _ItemData(Icons.inventory_2_rounded, '${stats.totalProducts}', 'Product Types', route: AppRoutes.products),
        _ItemData(Icons.inventory_rounded, '${stats.totalAvailableStock}', 'Total Items', route: AppRoutes.products),
        _ItemData(Icons.add_circle_rounded, '${stats.todayAddedQuantity}', 'Added Today', route: AppRoutes.dailyAdditions),
      ]),
      _GroupData('Stock Health', [
        _ItemData(Icons.check_circle_rounded, '${stats.totalProducts - stats.outOfStockProducts}', 'In Stock',
            badgeColor: const Color(0xFF22C55E), barValue: ((stats.totalProducts - stats.outOfStockProducts) / total * 100).clamp(0, 100), route: AppRoutes.products),
        _ItemData(Icons.warning_rounded, '${stats.lowStockProducts}', 'Low Stock',
            badgeColor: const Color(0xFFF59E0B), barValue: (stats.lowStockProducts / total * 100).clamp(0, 100), route: AppRoutes.products),
        _ItemData(Icons.error_outline_rounded, '${stats.outOfStockProducts}', 'Out of Stock',
            badgeColor: const Color(0xFFEF4444), barValue: (stats.outOfStockProducts / total * 100).clamp(0, 100), route: AppRoutes.products),
      ]),
      _GroupData('Activity', [
        _ItemData(Icons.shopping_cart_rounded, '${stats.todaySoldProducts}', 'Sold Today', route: AppRoutes.salesToday),
        _ItemData(Icons.verified_rounded, '${stats.activeWarranties}', 'Warranties', route: AppRoutes.warranty),
        _ItemData(Icons.bug_report_rounded, '${stats.openIssueCount}', 'Product Issues', route: AppRoutes.productIssues),
      ]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Overview', 'Everything at a glance'),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A2A3E)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Column(
            children: stockGroups.asMap().entries.map((entry) {
              final i = entry.key;
              final g = entry.value;
              return _buildGroup(g, isDark, context,
                  showBorder: i < stockGroups.length - 1);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGroup(_GroupData g, bool isDark, BuildContext context,
      {required bool showBorder}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: isDark
                        ? AppColors.greyDarker
                        : AppColors.primary,
                  width: 1,
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            g.title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: g.items.map((item) {
              return Expanded(
                child: _groupItem(item, isDark, context),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _groupItem(_ItemData item, bool isDark, BuildContext context) {
    return GestureDetector(
      onTap: item.route != null
          ? () => Navigator.pushNamed(context, item.route!)
          : null,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2A3E)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
                        child: _iconFromAsset(item.icon, size: 20, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            ),
          ),
          if (item.barValue != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: item.barValue! / 100,
                minHeight: 3,
                backgroundColor: isDark
                    ? const Color(0xFF2A2A3E)
                    : const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation(
                  item.badgeColor ?? const Color(0xFF22C55E),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── ANALYTICS ────────────────────────────────────────────

  Widget _buildAnalyticsRow(BuildContext context, DashboardStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final symbol = context.watch<SettingsProvider>().currencySymbol;

    final salesBars = _normBars(stats.dailySales);
    final profitBars = _normBars(stats.dailyProfit);
    final weeklyAvg = stats.dailySales.isNotEmpty
        ? stats.dailySales.reduce((a, b) => a + b) / stats.dailySales.length
        : 0.0;
    final todayVsAvg = weeklyAvg > 0
        ? ((stats.todaySalesAmount - weeklyAvg) / weeklyAvg * 100)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Analytics', '30-day sales & profit trends'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _chartCard(
                title: 'Sales',
                value: '$symbol${_fmtAmount(stats.todaySalesAmount)}',
                pct: todayVsAvg,
                bars: salesBars,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _chartCard(
                title: 'Profit',
                value: '$symbol${_fmtAmount(stats.todayProfit)}',
                pct: stats.dailyProfit.isNotEmpty &&
                        stats.dailyProfit.length > 1
                    ? ((stats.dailyProfit.last - stats.dailyProfit.first) /
                            stats.dailyProfit.first.abs().clamp(1, 1.0))
                        * 100
                    : 0.0,
                bars: profitBars,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chartCard({
    required String title,
    required String value,
    required double pct,
    required List<double> bars,
    required bool isDark,
  }) {
    final isUp = pct >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2A3E)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _iconFromAsset(
                  title == 'Sales' ? Icons.trending_up_rounded : Icons.show_chart_rounded,
                  size: 15,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF374151),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isUp
                      ? const Color(0xFF22C55E).withAlpha(20)
                      : const Color(0xFFEF4444).withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isUp ? '+' : ''}${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isUp
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((b) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    height: 36 * b,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A3E)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
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

  List<double> _normBars(List<double> values) {
    if (values.isEmpty) return List.filled(30, 0.08);
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max == 0) return List.filled(values.length, 0.08);
    return values.map((v) => (v / max).clamp(0.05, 1.0)).toList();
  }

  // ─── HEALTH + TOP SELLING ─────────────────────────────────

  Widget _buildHealthAndTopSelling(
      BuildContext context, DashboardStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final health = _calcHealth(stats);
    final top = stats.topSellingProducts.take(3).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _healthCard(health, stats, isDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _topSellingCard(top, isDark, context),
        ),
      ],
    );
  }

  Widget _healthCard(
      double health, DashboardStats stats, bool isDark) {
    final stockHealth = _calcStockHealth(stats);
    final salesHealth = _calcSalesMomentum(stats);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
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
                    value: health / 100,
                    strokeWidth: 6,
                    backgroundColor: isDark ? AppColors.greyDarker : AppColors.greyLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      health.toStringAsFixed(0),
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    Text(
                      'score',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              health >= 80
                  ? 'Excellent'
                  : health >= 60
                      ? 'Good'
                      : 'Needs Work',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _healthRow(
            icon: Icons.inventory_2_rounded,
            label: 'Stock',
            value: stockHealth,
            detail: '${stats.outOfStockProducts} out',
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _healthRow(
            icon: Icons.trending_up_rounded,
            label: 'Sales',
            value: salesHealth,
            detail: '${stats.todaySoldProducts} today',
            isDark: isDark,
          ),
          if (stats.lowStockProducts > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, size: 12, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.lowStockProducts} low stock ${stats.lowStockProducts == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _healthRow({
    required IconData icon,
    required String label,
    required double value,
    required String detail,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E30) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                detail,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: value / 100,
                    minHeight: 6,
                    backgroundColor: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation(
                      value >= 70
                          ? AppColors.primary
                          : value >= 40
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 28,
                child: Text(
                  '${value.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topSellingCard(
      List<TopSellingProduct> top, bool isDark, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2A2A3E)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconFromAsset(Icons.trending_up_rounded, size: 16, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF374151)),
              const SizedBox(width: 8),
              Text(
                'Top Selling',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No sales data yet',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            )
          else
            ...top.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              return Padding(
                padding: EdgeInsets.only(bottom: i < top.length - 1 ? 10 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF111111),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${p.totalSold} sold',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─── ACTIVITY ─────────────────────────────────────────────

  Widget _buildActivity(BuildContext context, DashboardStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activities = <_Activity>[
      _Activity(
        icon: Icons.add_circle_rounded,
        title: 'Products Added Today',
        value: '${stats.recentlyAddedProducts.length}',
        route: AppRoutes.dailyAdditions,
      ),
      _Activity(
        icon: Icons.shopping_cart_rounded,
        title: 'Products Sold Today',
        value: '${stats.todaySoldProducts}',
        route: AppRoutes.salesToday,
      ),
      _Activity(
        icon: Icons.warning_rounded,
        title: 'Low Stock Items',
        value: '${stats.lowStockProducts}',
        valueColor: stats.lowStockProducts > 0 ? const Color(0xFFF59E0B) : null,
        route: AppRoutes.inventory,
      ),
      _Activity(
        icon: Icons.verified_rounded,
        title: 'Active Warranties',
        value: '${stats.activeWarranties}',
        route: AppRoutes.warranty,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Recent Activity', "Today's updates"),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A2A3E)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Column(
            children: activities.asMap().entries.map((e) {
              final i = e.key;
              final a = e.value;
              return InkWell(
                onTap: () => Navigator.pushNamed(context, a.route),
                borderRadius: i == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : i == activities.length - 1
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(16))
                        : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: i < activities.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? const Color(0xFF2A2A3E)
                                  : const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A3E)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _iconFromAsset(a.icon, size: 18, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF374151)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF111111),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (a.valueColor ?? const Color(0xFF9CA3AF))
                              .withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          a.value,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: a.valueColor ?? (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── QUICK ACTIONS ────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = <_QuickAction>[
      _QuickAction(icon: Icons.add_circle_rounded, label: 'Add Product', route: AppRoutes.productsAdd),
      _QuickAction(icon: Icons.add_shopping_cart_rounded, label: 'New Sale', route: AppRoutes.salesNew),
      _QuickAction(icon: Icons.post_add_rounded, label: 'Add Stock', route: AppRoutes.dailyAdditions),
      _QuickAction(icon: Icons.people_rounded, label: 'Customers', route: AppRoutes.customers),
      _QuickAction(icon: Icons.history_rounded, label: 'Sales History', route: AppRoutes.salesHistory),
      _QuickAction(icon: Icons.assessment_rounded, label: 'Reports', route: AppRoutes.reports),
      _QuickAction(icon: Icons.search_rounded, label: 'Search', route: AppRoutes.search),
      _QuickAction(icon: Icons.settings_rounded, label: 'Settings', route: AppRoutes.settings),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Quick Actions', 'Frequently used tools'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions.map((a) {
            final itemW = (MediaQuery.of(context).size.width - 56) / 4;
            return SizedBox(
              width: itemW,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, a.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A2A3E)
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A3E)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _iconFromAsset(a.icon, size: 18, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF374151)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
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

  // ─── HELPERS ──────────────────────────────────────────────

  Widget _iconFromAsset(IconData icon, {double size = 24, required Color color}) {
    String? asset;
    if (icon == Icons.store_rounded) {
      asset = 'store';
    } else if (icon == Icons.check_circle_rounded || icon == Icons.check_circle) {
      asset = 'instock';
    } else if (icon == Icons.warning_rounded || icon == Icons.warning) {
      asset = 'warning';
    } else if (icon == Icons.error_outline_rounded) {
      asset = 'sold_out';
    } else if (icon == Icons.shopping_cart_rounded || icon == Icons.add_shopping_cart_rounded || icon == Icons.payments) {
      asset = 'sell';
    } else if (icon == Icons.trending_up_rounded) {
      asset = 'top_sell';
    } else if (icon == Icons.verified_rounded) {
      asset = 'warranty';
    } else if (icon == Icons.bug_report_rounded) {
      asset = 'issues';
    } else if (icon == Icons.people_rounded) {
      asset = 'costomer';
    } else if (icon == Icons.history_rounded) {
      asset = 'history';
    } else if (icon == Icons.assessment_rounded) {
      asset = 'report';
    } else if (icon == Icons.search_rounded) {
      asset = 'search';
    } else if (icon == Icons.add_circle_rounded) {
      asset = 'product_add';
    } else if (icon == Icons.post_add_rounded) {
      asset = 'add_stock';
    } else if (icon == Icons.inventory_2_rounded) {
      asset = 'product';
    } else if (icon == Icons.inventory_rounded || icon == Icons.inventory_2) {
      asset = 'product_item';
    } else if (icon == Icons.show_chart_rounded) {
      asset = 'analyics';
    }
    if (asset != null) {
      return Container(
        width: size + 10,
        height: size + 10,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            child: Image.asset("assets/icons/$asset.png", width: size, height: size),
          ),
        ),
      );
    }
    return Icon(icon, size: size, color: color);
  }



  Widget _sectionTitle(BuildContext context, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calcHealth(DashboardStats s) {
    double score = 70;
    if (s.totalProducts > 0) score += 10;
    if (s.totalAvailableStock > s.totalProducts) score += 5;
    if (s.todaySalesAmount > 0) score += 10;
    if (s.lowStockProducts == 0) score += 10;
    if (s.outOfStockProducts == 0) score += 5;
    return score.clamp(0, 100);
  }

  double _calcStockHealth(DashboardStats s) {
    if (s.totalProducts == 0) return 0;
    final h = s.totalProducts - s.outOfStockProducts;
    return (h / s.totalProducts * 100).clamp(0, 100);
  }

  double _calcSalesMomentum(DashboardStats s) {
    if (s.totalProducts == 0) return 0;
    return (s.todaySoldProducts / s.totalProducts * 100).clamp(0, 100);
  }

  // ─── SKELETON ─────────────────────────────────────────────

  Widget _buildSkeletonLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeleton(h: 140, isDark: isDark),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _skeleton(h: 90, isDark: isDark)),
            const SizedBox(width: 12),
            Expanded(child: _skeleton(h: 90, isDark: isDark)),
          ]),
          const SizedBox(height: 20),
          _skeleton(h: 16, w: 160, isDark: isDark),
          const SizedBox(height: 14),
          _skeleton(h: 200, isDark: isDark),
          const SizedBox(height: 20),
          _skeleton(h: 16, w: 160, isDark: isDark),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _skeleton(h: 160, isDark: isDark)),
            const SizedBox(width: 12),
            Expanded(child: _skeleton(h: 160, isDark: isDark)),
          ]),
          const SizedBox(height: 20),
          _skeleton(h: 16, w: 160, isDark: isDark),
          const SizedBox(height: 14),
          _skeleton(h: 160, isDark: isDark),
          const SizedBox(height: 20),
          _skeleton(h: 16, w: 160, isDark: isDark),
          const SizedBox(height: 14),
          _skeleton(h: 120, isDark: isDark),
        ],
      ),
    );
  }

  Widget _skeleton({
    required double h,
    double? w,
    required bool isDark,
  }) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ─── ERROR ────────────────────────────────────────────────

  Widget _buildErrorState(DashboardProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.cloud_off_rounded,
                  size: 36, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 20),
            Text(
              'Connection Error',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Something went wrong',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DATA CLASSES ─────────────────────────────────────────

class _GroupData {
  final String title;
  final List<_ItemData> items;
  const _GroupData(this.title, this.items);
}

class _ItemData {
  final IconData icon;
  final String value;
  final String label;
  final String? route;
  final double? barValue;
  final Color? badgeColor;
  const _ItemData(
    this.icon,
    this.value,
    this.label, {
    this.route,
    this.barValue,
    this.badgeColor,
  });
}

class _Activity {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  final String route;
  const _Activity({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
    required this.route,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.route,
  });
}
