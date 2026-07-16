import 'package:flutter/material.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/dashboard/screens/dashboard_screen.dart';
import 'package:smartstock/features/products/screens/product_list_screen.dart';
import 'package:smartstock/features/sales/screens/new_sale_screen.dart';
import 'package:smartstock/features/reports/screens/analytics_screen.dart';
import 'package:smartstock/features/settings/screens/settings_screen.dart';

class _TabItem {
  final String asset;
  final String label;
  const _TabItem(this.asset, this.label);
}

const _tabs = [
  _TabItem('assets/icons/dashboard.png', 'Dashboard'),
  _TabItem('assets/icons/product.png', 'Products'),
  _TabItem('assets/icons/sell.png', 'Sale'),
  _TabItem('assets/icons/analyics.png', 'Analytics'),
  _TabItem('assets/icons/store.png', 'Settings'),
];

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
      'add_category': AppRoutes.categoriesAdd,
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
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(
          left: 12, right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.greyLight, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(16),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: SizedBox(
              height: 46,
              child: Row(
              children: List.generate(_tabs.length, (i) {
                final active = _currentIndex == i;
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => switchToTab(i),
                      borderRadius: BorderRadius.circular(16),
                      splashColor: AppColors.primary.withAlpha(20),
                      highlightColor: AppColors.primary.withAlpha(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                active ? AppColors.white : AppColors.iconNavigationInactive,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(_tabs[i].asset, width: 20, height: 20),
                            ),
                            ClipRect(
                              child: AnimatedAlign(
                                alignment: Alignment.topCenter,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                heightFactor: active ? 1 : 0,
                                child: Padding(
                                  padding: EdgeInsets.only(top: active ? 1 : 0),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 250),
                                    opacity: active ? 1 : 0,
                                    child: Text(
                                      _tabs[i].label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: active ? AppColors.white : AppColors.iconNavigationInactive,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
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
          _fabItem(Icons.category_rounded, 'Add Category', AppColors.primary, () => _quickAction('add_category')),
          const SizedBox(height: 10),
          _fabItem(Icons.verified_rounded, 'Warranty', AppColors.primary, () => _quickAction('warranty')),
          const SizedBox(height: 10),
          _fabItem(Icons.bug_report_rounded, 'Issue', AppColors.primary, () => _quickAction('issue')),
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
