import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/dashboard/screens/dashboard_screen.dart';
import 'package:smartstock/features/products/screens/product_list_screen.dart';
import 'package:smartstock/features/sales/screens/new_sale_screen.dart';
import 'package:smartstock/features/reports/screens/analytics_screen.dart';
import 'package:smartstock/features/settings/screens/settings_screen.dart';

class ModernAppShell extends StatefulWidget {
  final int initialIndex;

  const ModernAppShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<ModernAppShell> createState() => ModernAppShellState();
}

class ModernAppShellState extends State<ModernAppShell>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late NotchBottomBarController _barController;

  late AnimationController _fabController;
  bool _isFabOpen = false;

  final List<Widget> _pages = const [
    DashboardScreen(),
    ProductListScreen(),
    NewSaleScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _barController = NotchBottomBarController(index: _currentIndex);
    _fabController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _barController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void switchToTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _isFabOpen = false;
    _fabController.reset();
  }

  void _toggleFab() {
    setState(() => _isFabOpen = !_isFabOpen);
    if (_isFabOpen) { _fabController.forward(); } else { _fabController.reverse(); }
  }

  void _quickAction(String action) {
    _toggleFab();
    final routes = {
      'add_product': AppRoutes.productsAdd,
      'warranty': AppRoutes.warranty,
      'issue': AppRoutes.productIssues,
    };
    if (routes.containsKey(action)) {
      Navigator.pushNamed(context, routes[action]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _barController,
        bottomBarItems: [
          BottomBarItem(
            inActiveItem: Icon(Icons.dashboard_rounded, color: AppColors.grey, size: 22),
            activeItem: Icon(Icons.dashboard_rounded, color: AppColors.primary, size: 22),
            itemLabel: 'Dashboard',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.inventory_rounded, color: AppColors.grey, size: 22),
            activeItem: Icon(Icons.inventory_rounded, color: AppColors.primary, size: 22),
            itemLabel: 'Products',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.add_circle_rounded, color: AppColors.grey, size: 22),
            activeItem: Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 22),
            itemLabel: 'Sale',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.analytics_rounded, color: AppColors.grey, size: 22),
            activeItem: Icon(Icons.analytics_rounded, color: AppColors.primary, size: 22),
            itemLabel: 'Analytics',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.person_rounded, color: AppColors.grey, size: 22),
            activeItem: Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
            itemLabel: 'Profile',
          ),
        ],
        onTap: (i) => switchToTab(i),
        kIconSize: 22,
        kBottomRadius: 28,
        notchColor: AppColors.surface,
        color: AppColors.surface,
        showLabel: true,
        showShadow: true,
        shadowElevation: 8,
        durationInMilliSeconds: 350,
        elevation: 0,
        notchGradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(15), AppColors.primary.withAlpha(5)],
        ),
        itemLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: AppColors.primary,
        ),
        bottomBarHeight: 64,
        circleMargin: 6,
        topMargin: 8,
        removeMargins: false,
        showBlurBottomBar: true,
        blurOpacity: 0.85,
        blurFilterX: 20,
        blurFilterY: 20,
      ),
      floatingActionButton: _currentIndex == 1 ? _fabButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _fabButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isFabOpen) ...[
          _fabItem(Icons.add_box_rounded, 'Add Product', AppColors.primary, () => _quickAction('add_product')),
          const SizedBox(height: 10),
          _fabItem(Icons.verified_rounded, 'Warranty', AppColors.blue, () => _quickAction('warranty')),
          const SizedBox(height: 10),
          _fabItem(Icons.bug_report_rounded, 'Issue', AppColors.orange, () => _quickAction('issue')),
          const SizedBox(height: 10),
        ],
        FloatingActionButton(
          onPressed: _toggleFab,
          backgroundColor: AppColors.primary,
          child: AnimatedRotation(
            turns: _isFabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _fabItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: color.withAlpha(80), blurRadius: 12),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
