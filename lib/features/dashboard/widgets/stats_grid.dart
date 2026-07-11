import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
              gradientColors: [const Color(0xFF7C4DFF), const Color(0xFFB388FF)],
              iconBgColor: Colors.white.withValues(alpha: 0.2),
              route: AppRoutes.products,
            ),
            _StatCard(
              icon: Icons.check_circle,
              label: 'Available Stock',
              value: NumberFormat('#,###').format(stats.totalAvailableStock),
              gradientColors: [const Color(0xFF00C853), const Color(0xFF69F0AE)],
              iconBgColor: Colors.white.withValues(alpha: 0.2),
              route: AppRoutes.inventory,
            ),
            _StatCard(
              icon: Icons.payments,
              label: "Today's Sales",
              value: '$symbol${NumberFormat('#,###').format(stats.todaySalesAmount)}',
              subtitle: '${stats.todaySoldProducts} items',
              gradientColors: [const Color(0xFF2979FF), const Color(0xFF82B1FF)],
              iconBgColor: Colors.white.withValues(alpha: 0.2),
              route: AppRoutes.salesToday,
            ),
            _StatCard(
              icon: Icons.warning,
              label: 'Low Stock Items',
              value: '${stats.lowStockProducts}',
              subtitle: '${stats.outOfStockProducts} out of stock',
              gradientColors: [const Color(0xFFFF6D00), const Color(0xFFFFAB40)],
              iconBgColor: Colors.white.withValues(alpha: 0.2),
              route: AppRoutes.inventory,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final List<Color> gradientColors;
  final Color iconBgColor;
  final String route;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.gradientColors,
    required this.iconBgColor,
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
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
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
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
