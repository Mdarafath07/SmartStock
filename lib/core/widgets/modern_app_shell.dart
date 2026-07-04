import 'package:flutter/material.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';

class ModernAppShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const ModernAppShell({
    super.key,
    required this.child,
    this.currentIndex = 0,
  });

  @override
  State<ModernAppShell> createState() => ModernAppShellState();
}

class ModernAppShellState extends State<ModernAppShell>
    with TickerProviderStateMixin {
  late int _currentIndex;

  late AnimationController _fabController;
  bool _isFabOpen = false;

  final List<_NavItem> _navItems = [
    _NavItem(0, Icons.grid_view_rounded, 'Dashboard'),
    _NavItem(1, Icons.inventory_2_rounded, 'Products'),
    _NavItem(2, Icons.add_circle_rounded, 'Sale'),
    _NavItem(3, Icons.analytics_rounded, 'Analytics'),
    _NavItem(4, Icons.person_rounded, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _fabController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    String? route;
    switch (index) {
      case 0: route = AppRoutes.home; break;
      case 1: route = AppRoutes.products; break;
      case 2: route = AppRoutes.salesNew; break;
      case 3: route = AppRoutes.reportsAnalytics; break;
      case 4: route = AppRoutes.settings; break;
    }
    if (route != null) {
      Navigator.pushNamedAndRemoveUntil(
        context, route, (r) => r.settings.name == AppRoutes.home,
      );
    }
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
      body: widget.child,
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(
          left: 12, right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 4,
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _navItems.map((item) {
                final sel = _currentIndex == item.index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabSelected(item.index),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon, size: 22,
                        color: sel ? AppColors.primary : AppColors.grey,
                      ),
                    ),
                  ),
                );
              }).toList(),
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

class _NavItem {
  final int index;
  final IconData icon;
  final String label;
  const _NavItem(this.index, this.icon, this.label);
}
