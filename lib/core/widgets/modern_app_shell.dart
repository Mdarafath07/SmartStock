import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
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
    _fabController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
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
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(
          left: 12, right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha(230),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.greyLight.withAlpha(80), width: 0.5),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: GNav(
                    selectedIndex: _currentIndex,
                    onTabChange: switchToTab,
                    duration: const Duration(milliseconds: 300),
                    haptic: true,
                    curve: Curves.easeOutCubic,
                    gap: 4,
                    color: AppColors.grey,
                    activeColor: AppColors.primary,
                    iconSize: 22,
                    tabBackgroundColor: AppColors.primaryBg,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    tabs: const [
                      GButton(
                        icon: Icons.grid_view_rounded,
                        text: 'Dashboard',
                        textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      GButton(
                        icon: Icons.inventory_2_rounded,
                        text: 'Products',
                        textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      GButton(
                        icon: Icons.add_circle_rounded,
                        text: 'Sale',
                        textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      GButton(
                        icon: Icons.analytics_rounded,
                        text: 'Analytics',
                        textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      GButton(
                        icon: Icons.person_rounded,
                        text: 'Profile',
                        textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
