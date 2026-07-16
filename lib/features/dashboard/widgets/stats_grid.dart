import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/dashboard/models/dashboard_stats_model.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';

class StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const StatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            _StatCard(
              icon: Icons.inventory_2,
              label: 'Total Products',
              value: NumberFormat('#,###').format(stats.totalProducts),
              route: AppRoutes.products,
            ),
            _StatCard(
              icon: Icons.check_circle,
              label: 'Available Stock',
              value: NumberFormat('#,###').format(stats.totalAvailableStock),
              route: AppRoutes.inventory,
            ),
            _StatCard(
              icon: Icons.payments,
              label: "Today's Sales",
              value: '$symbol${NumberFormat('#,###').format(stats.todaySalesAmount)}',
              subtitle: '${stats.todaySoldProducts} items',
              route: AppRoutes.salesToday,
            ),
            _StatCard(
              icon: Icons.warning,
              label: 'Low Stock Items',
              value: '${stats.lowStockProducts}',
              subtitle: '${stats.outOfStockProducts} out of stock',
              route: AppRoutes.inventory,
            ),
          ],
        );
      },
    );
  }
}

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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final String route;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Debounced(
        onPressed: () => Navigator.pushNamed(context, route),
        builder: (context, isDisabled) => InkWell(
          onTap: isDisabled ? null : () => Navigator.pushNamed(context, route),
          child: Container(
          color: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _iconFromAsset(icon, color: Colors.white, size: 18),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        size: 12, color: Colors.white.withValues(alpha: 0.5)),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 10,
                      color: Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
