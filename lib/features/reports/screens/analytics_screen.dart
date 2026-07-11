import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/utils/formatters.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/reports/providers/report_provider.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:smartstock/features/reports/widgets/download_report_button.dart';
import 'package:smartstock/features/reports/widgets/sales_chart.dart';

class _AnimatedCounter extends StatefulWidget {
  final double target;
  final TextStyle? style;

  const _AnimatedCounter({required this.target, this.style});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _startValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _startValue = _animation.value * oldWidget.target;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        final val = _startValue + (widget.target - _startValue) * _animation.value;
        return Text(val.toStringAsFixed(0), style: widget.style);
      },
    );
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _tab = 0;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  List<Color> get _heroColors {
    return [
      [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)], // daily
      [const Color(0xFF047857), const Color(0xFF10B981)], // monthly
      [const Color(0xFF6D28D9), const Color(0xFF8B5CF6)], // yearly
    ][_tab];
  }

  Color get _heroAccent => _heroColors.last;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadAllReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final stockValue = context.watch<ProductProvider>().products.fold<double>(0, (sum, p) => sum + p.sellingPrice * p.availableQuantity);

    return SafeArea(
      child: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.dailyReport == null) {
            return _buildSkeleton();
          }
          if (provider.error != null) {
            return _buildError(provider);
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadAllReports(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 24),
                  _buildSegmentedControl(),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: KeyedSubtree(
                      key: ValueKey(_tab),
                      child: Column(
                        children: [
                          if (_tab == 0) _buildDaily(provider, symbol, stockValue),
                          if (_tab == 1) _buildMonthly(provider, symbol, stockValue),
                          if (_tab == 2) _buildYearly(provider, symbol, stockValue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildAllTime(provider, symbol, isDark),
                  if (provider.categorySales.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCategory(provider, symbol),
                  ],
                  if (provider.topSellingProducts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildTopProducts(provider, symbol),
                  ],
                  if (provider.yearlyReports.length >= 2) ...[
                    const SizedBox(height: 16),
                    _buildChart(provider),
                  ],
                  const SizedBox(height: 16),
                  DownloadReportButton(onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report download started')),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceLight.withAlpha(100) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.analytics_rounded, color: isDark ? AppColors.textSecondary : const Color(0xFF64748B), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics',
                      style: AppTextStyles.headlineMd.copyWith(
                          color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text('Track your business performance',
                      style: AppTextStyles.bodySm.copyWith(
                          color: isDark ? AppColors.textMuted : const Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Segmented Control ───
  Widget _buildSegmentedControl() {
    final items = [
      (icon: Icons.today_rounded, label: 'Daily', color: const Color(0xFF3B82F6)),
      (icon: Icons.calendar_month_rounded, label: 'Monthly', color: const Color(0xFF10B981)),
      (icon: Icons.auto_graph_rounded, label: 'Yearly', color: const Color(0xFF8B5CF6)),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final sel = _tab == i;
          final item = items[i];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _tab = i);
                if (i == 1) {
                  context.read<ReportProvider>()
                      .loadMonthlyReportFor(DateTime.now().year, _month);
                }
                if (i == 2) {
                  context.read<ReportProvider>().loadYearlyReport();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: sel
                      ? LinearGradient(
                          colors: [item.color, item.color.withAlpha(180)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        )
                      : null,
                  color: sel ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: sel
                      ? [BoxShadow(color: item.color.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 16,
                        color: sel ? Colors.white : const Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(item.label,
                        style: AppTextStyles.labelMd.copyWith(
                            color: sel ? Colors.white : const Color(0xFF94A3B8),
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Daily ───
  Widget _buildDaily(ReportProvider provider, String symbol, double stockValue) {
    final r = provider.dailyReport;
    final margin = (r != null && r.totalSales > 0)
        ? '${(r.totalProfit / r.totalSales * 100).toStringAsFixed(1)}%'
        : '0.0%';
    final avg = (r != null && r.totalTransactions > 0)
        ? r.totalSales / r.totalTransactions
        : 0.0;

    return Column(
      children: [
        _HeroCard(
          colors: _heroColors,
          accent: _heroAccent,
          icon: Icons.today_rounded,
          badge: '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
          label: "Today's Revenue",
          amount: AppFormatters.formatCurrency(r?.totalSales ?? 0, symbol: symbol),
          stats: [
            _StatData(label: 'Stock Value', value: AppFormatters.formatCurrency(stockValue, symbol: symbol)),
            _StatData(label: 'Profit', value: AppFormatters.formatCurrency(r?.totalProfit ?? 0, symbol: symbol)),
            _StatData(label: 'Margin', value: margin),
          ],
        ),
        const SizedBox(height: 14),
        _StatsRow(items: [
          _StatItem(icon: Icons.receipt_long_rounded, value: '${r?.totalTransactions ?? 0}', label: 'Transactions', color: const Color(0xFF475569)),
          _StatItem(icon: Icons.inventory_2_rounded, value: '${r?.totalProductsSold ?? 0}', label: 'Items Sold', color: const Color(0xFF3B82F6)),
          _StatItem(icon: Icons.shopping_cart_rounded, value: AppFormatters.formatCurrency(avg, symbol: symbol), label: 'Avg Sale', color: const Color(0xFF0D9488)),
        ]),
      ],
    );
  }

  // ─── Monthly ───
  Widget _buildMonthly(ReportProvider provider, String symbol, double stockValue) {
    final r = provider.monthlyReport;
    final margin = (r != null && r.totalSales > 0)
        ? '${(r.totalProfit / r.totalSales * 100).toStringAsFixed(1)}%'
        : '0.0%';
    final avg = (r != null && r.totalTransactions > 0)
        ? r.totalSales / r.totalTransactions
        : 0.0;

    return Column(
      children: [
        _PickerRow(
          label: '${_months[_month - 1]} $_year',
          onPrev: () {
            setState(() {
              if (_month == 1) { _month = 12; _year--; }
              else { _month--; }
            });
            context.read<ReportProvider>().loadMonthlyReportFor(_year, _month);
          },
          onNext: () {
            setState(() {
              if (_month == 12) { _month = 1; _year++; }
              else { _month++; }
            });
            context.read<ReportProvider>().loadMonthlyReportFor(_year, _month);
          },
        ),
        const SizedBox(height: 16),
        _HeroCard(
          colors: _heroColors,
          accent: _heroAccent,
          icon: Icons.calendar_month_rounded,
          badge: _months[_month - 1],
          label: 'Monthly Revenue',
          amount: AppFormatters.formatCurrency(r?.totalSales ?? 0, symbol: symbol),
          stats: [
            _StatData(label: 'Stock Value', value: AppFormatters.formatCurrency(stockValue, symbol: symbol)),
            _StatData(label: 'Profit', value: AppFormatters.formatCurrency(r?.totalProfit ?? 0, symbol: symbol)),
            _StatData(label: 'Margin', value: margin),
          ],
        ),
        const SizedBox(height: 14),
        _StatsRow(items: [
          _StatItem(icon: Icons.receipt_long_rounded, value: '${r?.totalTransactions ?? 0}', label: 'Transactions', color: const Color(0xFF475569)),
          _StatItem(icon: Icons.inventory_2_rounded, value: '${r?.totalProductsSold ?? 0}', label: 'Items Sold', color: const Color(0xFF3B82F6)),
          _StatItem(icon: Icons.shopping_cart_rounded, value: AppFormatters.formatCurrency(avg, symbol: symbol), label: 'Avg Sale', color: const Color(0xFF0D9488)),
        ]),
      ],
    );
  }

  // ─── Yearly ───
  Widget _buildYearly(ReportProvider provider, String symbol, double stockValue) {
    final reports = provider.yearlyReports;
    final totalSales = reports.fold<double>(0, (s, r) => s + r.totalSales);
    final totalProfit = reports.fold<double>(0, (s, r) => s + r.totalProfit);
    final totalTx = reports.fold<int>(0, (s, r) => s + r.totalTransactions);
    final totalItems = reports.fold<int>(0, (s, r) => s + r.totalProductsSold);
    final margin = totalSales > 0 ? '${(totalProfit / totalSales * 100).toStringAsFixed(1)}%' : '0.0%';
    final avgMo = reports.isNotEmpty ? totalSales / reports.length : 0.0;

    return Column(
      children: [
        _PickerRow(
          label: '${provider.selectedYear}',
          onPrev: () {
            final ny = provider.selectedYear - 1;
            provider.setSelectedYear(ny);
            provider.loadYearlyReport(year: ny);
          },
          onNext: () {
            final ny = provider.selectedYear + 1;
            provider.setSelectedYear(ny);
            provider.loadYearlyReport(year: ny);
          },
        ),
        const SizedBox(height: 16),
        _HeroCard(
          colors: _heroColors,
          accent: _heroAccent,
          icon: Icons.auto_graph_rounded,
          badge: '${provider.selectedYear}',
          label: 'Yearly Revenue',
          amount: AppFormatters.formatCurrency(totalSales, symbol: symbol),
          stats: [
            _StatData(label: 'Stock Value', value: AppFormatters.formatCurrency(stockValue, symbol: symbol)),
            _StatData(label: 'Profit', value: AppFormatters.formatCurrency(totalProfit, symbol: symbol)),
            _StatData(label: 'Margin', value: margin),
          ],
        ),
        const SizedBox(height: 14),
        _StatsRow(items: [
          _StatItem(icon: Icons.receipt_long_rounded, value: '$totalTx', label: 'Transactions', color: const Color(0xFF475569)),
          _StatItem(icon: Icons.inventory_2_rounded, value: '$totalItems', label: 'Items Sold', color: const Color(0xFF3B82F6)),
          _StatItem(icon: Icons.shopping_cart_rounded, value: AppFormatters.formatCurrency(avgMo, symbol: symbol), label: 'Avg Month', color: const Color(0xFF0D9488)),
        ]),
      ],
    );
  }

  // ─── Supplemental Sections ───
  Widget _buildAllTime(ReportProvider provider, String symbol, bool isDark) {
    final a = provider.allTimeSummary;
    if (a == null || a.totalTransactions == 0) return const SizedBox.shrink();
    return _SectionCard(
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.primary,
      title: 'All-Time Summary',
      child: Column(
        children: [
          Row(children: [
            _MiniAnalytic(
              label: 'Total Sales',
              value: AppFormatters.formatCurrency(a.totalSales, symbol: symbol),
              color: AppColors.primary,
              animatedValue: a.totalSales,
            ),
            const SizedBox(width: 10),
            _MiniAnalytic(
              label: 'Total Profit',
              value: AppFormatters.formatCurrency(a.totalProfit, symbol: symbol),
              color: AppColors.green,
              animatedValue: a.totalProfit,
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _MiniAnalytic(
              label: 'Transactions',
              value: '${a.totalTransactions}',
              color: AppColors.blue,
              animatedValue: a.totalTransactions.toDouble(),
            ),
            const SizedBox(width: 10),
            _MiniAnalytic(
              label: 'Items Sold',
              value: '${a.totalProductsSold}',
              color: AppColors.orange,
              animatedValue: a.totalProductsSold.toDouble(),
            ),
          ]),
        ],
      ),
    );
  }

  static const _categoryColors = [
    AppColors.primary, AppColors.purple, AppColors.green,
    AppColors.orange, AppColors.teal, AppColors.pink,
    AppColors.blue, AppColors.red,
  ];

  Widget _buildCategory(ReportProvider provider, String symbol) {
    final max = provider.categorySales.fold<double>(0, (m, c) => c.totalSales > m ? c.totalSales : m);
    return _SectionCard(
      icon: Icons.category_rounded,
      iconColor: AppColors.purple,
      title: 'Sales by Category',
      child: Column(
        children: provider.categorySales.toList().asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          final color = _categoryColors[i % _categoryColors.length];
          final pct = max > 0 ? (c.totalSales / max).clamp(0.0, 1.0) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.categoryName,
                        style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(AppFormatters.formatCurrency(c.totalSales, symbol: symbol),
                        style: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w700, color: color)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(color.withAlpha(200)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static const _medalColors = [
    Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32),
  ];

  Widget _buildTopProducts(ReportProvider provider, String symbol) {
    final top = provider.topSellingProducts.take(5).toList();
    return _SectionCard(
      icon: Icons.trending_up_rounded,
      iconColor: AppColors.orange,
      title: 'Top Selling Products',
      child: Column(
        children: top.asMap().entries.map((e) {
          final rank = e.key;
          final p = e.value;
          final isMedal = rank < 3;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMedal ? _medalColors[rank].withAlpha(8) : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMedal
                    ? _medalColors[rank].withAlpha(40)
                    : const Color(0xFFE2E8F0).withAlpha(80),
                width: 1,
              ),
            ),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isMedal
                      ? _medalColors[rank].withAlpha(30)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${rank + 1}',
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700,
                          color: isMedal ? _medalColors[rank] : const Color(0xFF94A3B8))),
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 40, height: 40,
                  color: const Color(0xFFE2E8F0),
                  child: p.imageUrl.isNotEmpty
                      ? Image.network(p.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.inventory_2_rounded, size: 18, color: Color(0xFF94A3AF)))
                      : const Icon(Icons.inventory_2_rounded, size: 18, color: Color(0xFF94A3AF)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.productName,
                        style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Model: ${p.modelNumber}',
                        style: AppTextStyles.caption.copyWith(color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMedal ? _medalColors[rank].withAlpha(20) : AppColors.primary.withAlpha(12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${p.quantitySold} sold',
                        style: AppTextStyles.labelSm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isMedal ? _medalColors[rank] : AppColors.primary)),
                  ),
                  const SizedBox(height: 4),
                  Text(AppFormatters.formatCurrency(p.totalRevenue, symbol: symbol),
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
                ],
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(ReportProvider provider) {
    return _SectionCard(
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.teal,
      title: 'Monthly Breakdown',
      child: SizedBox(
        height: 200,
        child: SalesBarChart(data: provider.yearlyReports, title: ''),
      ),
    );
  }

  // ─── Error / Skeleton ───
  Widget _buildError(ReportProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          Text(provider.error!,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => provider.loadAllReports(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 100),
      child: Column(children: [
        _ShimmerBlock(height: 42, width: 160, margin: const EdgeInsets.only(bottom: 6)),
        _ShimmerBlock(height: 14, width: 220, margin: const EdgeInsets.only(bottom: 24)),
        _ShimmerBlock(height: 50, margin: const EdgeInsets.only(bottom: 24)),
        _ShimmerBlock(height: 200, margin: const EdgeInsets.only(bottom: 14)),
        _ShimmerBlock(height: 90, margin: const EdgeInsets.only(bottom: 14)),
        _ShimmerBlock(height: 90),
      ]),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  final double height;
  final double? width;
  final EdgeInsets? margin;
  const _ShimmerBlock({required this.height, this.width, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withAlpha(120),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
//  Widgets
// ══════════════════════════════════════════════════

class _HeroCard extends StatefulWidget {
  final List<Color> colors;
  final Color accent;
  final IconData icon;
  final String badge;
  final String label;
  final String amount;
  final List<_StatData> stats;

  const _HeroCard({
    required this.colors,
    required this.accent,
    required this.icon,
    required this.badge,
    required this.label,
    required this.amount,
    required this.stats,
  });

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, child) {
        final pulseVal = _pulseAnimation.value;
        final shiftedColors = [
          Color.lerp(widget.colors[0], widget.colors[0].withAlpha(180), pulseVal)!,
          Color.lerp(widget.colors[1], widget.colors[1].withAlpha(220), pulseVal)!,
        ];
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: shiftedColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withAlpha(80), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withAlpha(80),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(widget.icon, size: 24, color: Colors.white),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withAlpha(30),
                                  Colors.white.withAlpha(15),
                                ],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withAlpha(40), width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white.withAlpha(200)),
                                const SizedBox(width: 5),
                                Text(widget.badge,
                                    style: const TextStyle(
                                        fontFamily: 'Inter', fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(widget.label,
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 14, color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 0.3)),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(widget.amount,
                          style: const TextStyle(
                              fontFamily: 'Hanken Grotesk', fontSize: 38, fontWeight: FontWeight.w700,
                              color: Colors.white, height: 1.1, letterSpacing: -0.03)),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: widget.stats.map((s) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: widget.stats.last == s ? 0 : 14),
                            child: _HeroStat(label: s.label, value: s.value),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 11, color: Colors.white.withAlpha(180))),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: const TextStyle(
                    fontFamily: 'Hanken Grotesk', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  const _StatData({required this.label, required this.value});
}

class _StatsRow extends StatelessWidget {
  final List<_StatItem> items;
  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: items.first == item ? 0 : 8, right: items.last == item ? 0 : 8),
          child: _StatCard(item: item),
        ),
      )).toList(),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatItem({required this.icon, required this.value, required this.label, required this.color});
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0).withAlpha(80), width: 0.5),
        boxShadow: [
          BoxShadow(color: item.color.withAlpha(10), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: item.color.withAlpha(15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(height: 14),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(item.value,
                style: TextStyle(
                    fontFamily: 'Hanken Grotesk', fontSize: 20, fontWeight: FontWeight.w700,
                    height: 1.1, letterSpacing: -0.02, color: item.color))),
          const SizedBox(height: 4),
          Text(item.label,
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B), height: 1.2)),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _PickerRow({required this.label, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ArrowBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
        const SizedBox(width: 14),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        const SizedBox(width: 14),
        _ArrowBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.iconColor, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0).withAlpha(80), width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withAlpha(3), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MiniAnalytic extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double? animatedValue;
  const _MiniAnalytic({required this.label, required this.value, required this.color, this.animatedValue});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3AF))),
              ],
            ),
            const SizedBox(height: 8),
            if (animatedValue != null)
              _AnimatedCounter(
                target: animatedValue!,
                style: TextStyle(
                    fontFamily: 'Hanken Grotesk', fontSize: 17, fontWeight: FontWeight.w700, color: color),
              )
            else
              Text(value,
                  style: TextStyle(
                      fontFamily: 'Hanken Grotesk', fontSize: 17, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
