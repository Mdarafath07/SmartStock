import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/dashboard/providers/dashboard_provider.dart';
import 'package:smartstock/features/dashboard/widgets/quick_search.dart';
import 'package:smartstock/features/dashboard/widgets/recent_products_section.dart';
import 'package:smartstock/features/dashboard/widgets/stats_grid.dart';
import 'package:smartstock/features/dashboard/widgets/top_selling_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showQuickSearch(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.stats == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(provider.error!,
                      style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatsGrid(stats: provider.stats!),
                  const SizedBox(height: 24),
                  TopSellingSection(
                      topSelling: provider.stats!.topSellingProducts),
                  const SizedBox(height: 24),
                  RecentProductsSection(
                      title: 'Recently Added',
                      products: provider.stats!.recentlyAddedProducts),
                  const SizedBox(height: 24),
                  RecentProductsSection(
                      title: 'Recently Sold',
                      showQuantity: false,
                      products: provider.stats!.recentlySoldProducts),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.inventory_2,
                    color: AppColors.onPrimary, size: 40),
                const SizedBox(height: 8),
                Text(
                  'SmartStock',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: AppColors.onPrimary),
                ),
                const Text(
                  'Electronics Shop Management',
                  style: TextStyle(color: AppColors.onPrimary, fontSize: 12),
                ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          _DrawerItem(
            icon: Icons.category,
            title: 'Categories',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.categories);
            },
          ),
          _DrawerItem(
            icon: Icons.inventory,
            title: 'Products',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.products);
            },
          ),
          _DrawerItem(
            icon: Icons.warehouse,
            title: 'Inventory',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.inventory);
            },
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.add_shopping_cart,
            title: 'New Sale',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.salesNew);
            },
          ),
          _DrawerItem(
            icon: Icons.today,
            title: "Today's Sales",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.salesToday);
            },
          ),
          _DrawerItem(
            icon: Icons.history,
            title: 'Sales History',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.salesHistory);
            },
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.people,
            title: 'Customers',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.customers);
            },
          ),
          _DrawerItem(
            icon: Icons.verified,
            title: 'Warranty',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.warranty);
            },
          ),
          _DrawerItem(
            icon: Icons.bar_chart,
            title: 'Reports',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.reports);
            },
          ),
          _DrawerItem(
            icon: Icons.analytics,
            title: 'Analytics',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.reportsAnalytics);
            },
          ),
          const Divider(),
          _DrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
    );
  }

  void _showQuickSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const QuickSearch(),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      selectedTileColor: AppColors.primaryContainer.withAlpha(80),
      onTap: onTap,
    );
  }
}

