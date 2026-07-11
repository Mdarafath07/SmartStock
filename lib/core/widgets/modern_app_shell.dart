import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/features/dashboard/screens/dashboard_screen.dart';
import 'package:smartstock/features/products/screens/product_list_screen.dart';
import 'package:smartstock/features/sales/screens/new_sale_screen.dart';
import 'package:smartstock/features/reports/screens/analytics_screen.dart';
import 'package:smartstock/features/settings/screens/settings_screen.dart';

class _Tab {
  final IconData icon;
  final String label;
  const _Tab(this.icon, this.label);
}

const _tabs = [
  _Tab(Icons.dashboard_rounded, 'Dashboard'),
  _Tab(Icons.inventory_rounded, 'Products'),
  _Tab(Icons.add_circle_rounded, 'Sale'),
  _Tab(Icons.analytics_rounded, 'Analytics'),
  _Tab(Icons.person_rounded, 'Profile'),
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
  late List<AnimationController> _slideControllers;
  late List<CurvedAnimation> _slideCurves;
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
    _slideControllers = List.generate(5, (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    ));
    _slideCurves = _slideControllers.map((c) => CurvedAnimation(
      parent: c,
      curve: Curves.easeOutQuint,
    )).toList();
    _slideControllers[_currentIndex].value = 1;
  }

  @override
  void dispose() {
    for (final c in _slideCurves) { c.dispose(); }
    for (final c in _slideControllers) { c.dispose(); }
    _fabController.dispose();
    super.dispose();
  }

  void switchToTab(int index) {
    if (_currentIndex == index) return;
    _slideControllers[_currentIndex].reverse();
    _currentIndex = index;
    _slideControllers[_currentIndex].forward();
    setState(() {});
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
          left: 16, right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 10,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha(235),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.greyLight.withAlpha(60), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final active = _currentIndex == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => switchToTab(i),
                          child: AnimatedBuilder(
                            animation: _slideCurves[i],
                            builder: (context, _) {
                              final anim = _slideCurves[i].value;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                decoration: BoxDecoration(
                                  color: active ? AppColors.primaryBg : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_tabs[i].icon, size: 22,
                                      color: active ? AppColors.primary : AppColors.grey),
                                    if (anim > 0)
                                      ClipRect(
                                        child: Align(
                                          widthFactor: anim,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 6),
                                            child: Text(
                                              _tabs[i].label,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                                color: active ? AppColors.primary : AppColors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }),
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
