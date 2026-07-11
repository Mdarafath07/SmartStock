import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/dashboard/providers/dashboard_provider.dart';
import 'package:smartstock/features/dashboard/models/dashboard_stats_model.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

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
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  // ─── HEADER ───────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, DashboardProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final storeName = settings.storeName;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF0F172A) : const Color(0xFF1E3A8A))
                .withAlpha(60),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF2563EB), const Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Good ${_timeGreeting()}!',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF93C5FD),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withAlpha(30),
                            Colors.white.withAlpha(10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withAlpha(25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withAlpha(12),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Revenue",
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFBFDBFE),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$symbol${_fmtAmount(provider.stats?.todaySalesAmount ?? 0)}',
                                style: const TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withAlpha(15),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Profit",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFBFDBFE),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$symbol${_fmtAmount(provider.stats?.todayProfit ?? 0)}',
                                  style: const TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
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
          ),
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(6),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(4),
              ),
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
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            icon: null,
            iconColor: AppColors.blue,
            bgColor: AppColors.blueBg,
            label: 'Selling Value',
            value: '$symbol${_fmtAmount(stats.totalStockValue)}',
            subtitle: 'At customer price',
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiCard(
            icon: null,
            iconColor: AppColors.orange,
            bgColor: AppColors.orangeBg,
            label: 'Stock Cost',
            value: '$symbol${_fmtAmount(stats.totalStockCost)}',
            subtitle: 'Total invested',
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required IconData? icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF162032)]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppColors.greyDarker.withAlpha(60)
              : iconColor.withAlpha(25),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: icon == null ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor.withAlpha(30), iconColor.withAlpha(10)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: icon == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: icon == null ? Alignment.center : Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: icon == null ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
                  ),
                ),
              ],
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
      _GroupData('Products', AppColors.blue, [
        _ItemData(Icons.inventory_2_rounded, '${stats.totalProducts}', 'Product Types', AppColors.blue, route: AppRoutes.products),
        _ItemData(Icons.inventory_rounded, '${stats.totalAvailableStock}', 'Total Items', AppColors.teal, route: AppRoutes.products),
        _ItemData(Icons.add_circle_rounded, '${stats.recentlyAddedProducts.length}', 'Added Today', AppColors.primary, route: AppRoutes.dailyAdditions),
      ]),
      _GroupData('Stock Health', AppColors.green, [
        _ItemData(Icons.check_circle_rounded, '${stats.totalAvailableStock}', 'In Stock', AppColors.green, barValue: (stats.totalAvailableStock / total * 100).clamp(0, 100), route: AppRoutes.products),
        _ItemData(Icons.warning_rounded, '${stats.lowStockProducts}', 'Low Stock', AppColors.orange, barValue: (stats.lowStockProducts / total * 100).clamp(0, 100), route: AppRoutes.products),
        _ItemData(Icons.error_outline_rounded, '${stats.outOfStockProducts}', 'Out of Stock', AppColors.red, barValue: (stats.outOfStockProducts / total * 100).clamp(0, 100), route: AppRoutes.products),
      ]),
      _GroupData('Activity', AppColors.purple, [
        _ItemData(Icons.shopping_cart_rounded, '${stats.todaySoldProducts}', 'Sold Today', AppColors.purple, route: AppRoutes.salesToday),
        _ItemData(Icons.verified_rounded, '${stats.activeWarranties}', 'Warranties', AppColors.pink, route: AppRoutes.warranty),
        _ItemData(Icons.bug_report_rounded, '${stats.openIssueCount}', 'Product Issues', AppColors.orange, route: AppRoutes.productIssues),
      ]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Overview', 'Everything at a glance'),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.greyDarker.withAlpha(60)
                  : const Color(0xFFE5E7EB).withAlpha(140),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? AppColors.greyDarker.withAlpha(60)
                      : const Color(0xFFE5E7EB).withAlpha(140),
                  width: 0.5,
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: g.accent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                g.title,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.color.withAlpha(25), item.color.withAlpha(8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.color.withAlpha(15),
                width: 0.5,
              ),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
            ),
          ),
          if (item.barValue != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: item.barValue! / 100,
                minHeight: 3,
                backgroundColor: isDark
                    ? AppColors.greyDarker.withAlpha(80)
                    : const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation(item.color),
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
                color: AppColors.blue,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
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
                color: AppColors.green,
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
    required Color color,
    required bool isDark,
  }) {
    final isUp = pct >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.greyDarker.withAlpha(60)
              : const Color(0xFFE5E7EB).withAlpha(120),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
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
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  title == 'Sales'
                      ? Icons.trending_up_rounded
                      : Icons.show_chart_rounded,
                  size: 15,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: (isUp ? AppColors.greenBg : AppColors.redBg)
                      .withAlpha(200),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isUp ? '+' : ''}${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isUp ? AppColors.green : AppColors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
              letterSpacing: -0.5,
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
                      gradient: LinearGradient(
                        colors: [color.withAlpha(180), color.withAlpha(50)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(3),
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
    if (values.isEmpty) return List.filled(7, 0.08);
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
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: _topSellingCard(top, isDark, context),
        ),
      ],
    );
  }

  Widget _healthCard(
      double health, DashboardStats stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.greyDarker.withAlpha(60)
              : const Color(0xFFE5E7EB).withAlpha(120),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: health / 100,
                  strokeWidth: 5,
                  backgroundColor: isDark
                      ? AppColors.greyDarker.withAlpha(80)
                      : const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation(
                    health >= 80
                        ? AppColors.green
                        : health >= 60
                            ? AppColors.orange
                            : AppColors.red,
                  ),
                ),
                Text(
                  health.toStringAsFixed(0),
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: health >= 80
                        ? AppColors.green
                        : health >= 60
                            ? AppColors.orange
                            : AppColors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            health >= 80
                ? 'Excellent'
                : health >= 60
                    ? 'Good'
                    : 'Needs Work',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          _healthRow('Stock', _calcStockHealth(stats), isDark),
          const SizedBox(height: 4),
          _healthRow('Sales', _calcSalesMomentum(stats), isDark),
        ],
      ),
    );
  }

  Widget _healthRow(String label, double value, bool isDark) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 5,
              backgroundColor: isDark
                  ? AppColors.greyDarker.withAlpha(80)
                  : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(
                value >= 70
                    ? AppColors.green
                    : value >= 40
                        ? AppColors.orange
                        : AppColors.red,
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
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topSellingCard(
      List<TopSellingProduct> top, bool isDark, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.greyDarker.withAlpha(60)
              : const Color(0xFFE5E7EB).withAlpha(120),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  size: 16, color: AppColors.green),
              const SizedBox(width: 6),
              Text(
                'Top Selling',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No sales data yet',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            ...top.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final colors = [
                AppColors.blue,
                AppColors.purple,
                AppColors.orange
              ];
              final c = colors[i];
              return Padding(
                padding: EdgeInsets.only(bottom: i < top.length - 1 ? 8 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: c,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimary
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${p.totalSold} sold',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: c,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (top.length >= 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.reports),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ),
            ),
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
        color: AppColors.blue,
        route: AppRoutes.dailyAdditions,
      ),
      _Activity(
        icon: Icons.shopping_cart_rounded,
        title: 'Products Sold Today',
        value: '${stats.todaySoldProducts}',
        color: AppColors.green,
        route: AppRoutes.salesToday,
      ),
      _Activity(
        icon: Icons.warning_rounded,
        title: 'Low Stock Items',
        value: '${stats.lowStockProducts}',
        color: AppColors.orange,
        route: AppRoutes.inventory,
      ),
      _Activity(
        icon: Icons.verified_rounded,
        title: 'Active Warranties',
        value: '${stats.activeWarranties}',
        color: AppColors.purple,
        route: AppRoutes.warranty,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Recent Activity', 'Today\'s updates'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.greyDarker.withAlpha(60)
                  : const Color(0xFFE5E7EB).withAlpha(120),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
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
                                  ? AppColors.greyDarker.withAlpha(60)
                                  : const Color(0xFFE5E7EB).withAlpha(100),
                              width: 0.5,
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
                          color: a.color.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(a.icon, size: 18, color: a.color),
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
                            color: isDark
                                ? AppColors.textPrimary
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: a.color.withAlpha(12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          a.value,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: a.color,
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
      _QuickAction(
          icon: Icons.add_circle_rounded,
          label: 'Add Product',
          color: AppColors.blue,
          route: AppRoutes.productsAdd),
      _QuickAction(
          icon: Icons.add_shopping_cart_rounded,
          label: 'New Sale',
          color: AppColors.green,
          route: AppRoutes.salesNew),
      _QuickAction(
          icon: Icons.post_add_rounded,
          label: 'Add Stock',
          color: AppColors.orange,
          route: AppRoutes.dailyAdditions),
      _QuickAction(
          icon: Icons.people_rounded,
          label: 'Customers',
          color: AppColors.purple,
          route: AppRoutes.customers),
      _QuickAction(
          icon: Icons.history_rounded,
          label: 'Sales History',
          color: AppColors.teal,
          route: AppRoutes.salesHistory),
      _QuickAction(
          icon: Icons.assessment_rounded,
          label: 'Reports',
          color: AppColors.red,
          route: AppRoutes.reports),
      _QuickAction(
          icon: Icons.search_rounded,
          label: 'Search',
          color: AppColors.grey,
          route: AppRoutes.search),
      _QuickAction(
          icon: Icons.settings_rounded,
          label: 'Settings',
          color: AppColors.greyDark,
          route: AppRoutes.settings),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: a.color.withAlpha(20),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: a.color.withAlpha(8),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: a.color.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(a.icon, size: 17, color: a.color),
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
                          color: isDark
                              ? AppColors.textSecondary
                              : const Color(0xFF475569),
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
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
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
                  color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
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
    final h = s.totalProducts - s.lowStockProducts - s.outOfStockProducts;
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
          _skeleton(h: 130, isDark: isDark),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _skeleton(h: 90, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _skeleton(h: 90, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _skeleton(h: 90, isDark: isDark)),
          ]),
          const SizedBox(height: 20),
          _skeleton(h: 16, w: 160, isDark: isDark),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _skeleton(h: 72, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _skeleton(h: 72, isDark: isDark)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _skeleton(h: 72, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _skeleton(h: 72, isDark: isDark)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _skeleton(h: 72, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _skeleton(h: 72, isDark: isDark)),
          ]),
          const SizedBox(height: 20),
          _skeleton(h: 16, w: 160, isDark: isDark),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _skeleton(h: 150, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _skeleton(h: 150, isDark: isDark)),
          ]),
          const SizedBox(height: 20),
          _skeleton(h: 16, w: 160, isDark: isDark),
          const SizedBox(height: 12),
          _skeleton(h: 180, isDark: isDark),
          const SizedBox(height: 20),
          _skeleton(h: 16, w: 160, isDark: isDark),
          const SizedBox(height: 12),
          _skeleton(h: 100, isDark: isDark),
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
        color: isDark ? AppColors.shimmerBase : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  // ─── ERROR ────────────────────────────────────────────────

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
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 36, color: AppColors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Connection Error',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Something went wrong',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
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
  final Color accent;
  final List<_ItemData> items;
  const _GroupData(this.title, this.accent, this.items);
}

class _ItemData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? route;
  final double? barValue;
  const _ItemData(
    this.icon,
    this.value,
    this.label,
    this.color, {
    this.route,
    this.barValue,
  });
}

class _Activity {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String route;
  const _Activity({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.route,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}
