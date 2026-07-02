import 'package:flutter/material.dart';
import 'package:smartstock/core/widgets/modern_app_shell.dart';
import 'app_routes.dart';
import '../../features/daily_additions/screens/daily_additions_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/products/screens/product_list_screen.dart';
import '../../features/products/screens/add_product_screen.dart';
import '../../features/products/screens/edit_product_screen.dart';
import '../../features/products/screens/product_details_screen.dart';
import '../../features/categories/screens/category_management_screen.dart';
import '../../features/categories/screens/add_category_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/inventory/screens/stock_details_screen.dart';
import '../../features/sales/screens/new_sale_screen.dart';
import '../../features/sales/screens/todays_sales_screen.dart';
import '../../features/sales/screens/sales_history_screen.dart';
import '../../features/sales/screens/sale_details_screen.dart';
import '../../features/customers/screens/customer_list_screen.dart';
import '../../features/customers/screens/customer_details_screen.dart';
import '../../features/warranty/screens/warranty_check_screen.dart';
import '../../features/warranty/screens/warranty_details_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/reports/screens/analytics_screen.dart';
import '../../features/product_issues/screens/product_issue_list_screen.dart';
import '../../features/product_issues/screens/product_issue_details_screen.dart';
import '../../features/replacements/screens/replacement_list_screen.dart';
import '../../features/replacements/screens/replacement_details_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/search/screens/search_screen.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.home:
        return _page(ModernAppShell(
          currentIndex: 0,
          child: const DashboardScreen(),
        ), settings);
      case AppRoutes.products:
        return _page(ModernAppShell(
          currentIndex: 1,
          child: const ProductListScreen(),
        ), settings);
      case AppRoutes.productsAdd:
        return _page(const AddProductScreen(), settings);
      case AppRoutes.productsEdit:
        return _page(EditProductScreen(productId: args as String), settings);
      case AppRoutes.productsDetails:
        return _page(ProductDetailsScreen(productId: args as String), settings);
      case AppRoutes.categories:
        return _page(const CategoryManagementScreen(), settings);
      case AppRoutes.categoriesAdd:
        return _page(const AddCategoryScreen(), settings);
      case AppRoutes.inventory:
        return _page(ModernAppShell(
          currentIndex: 1,
          child: const InventoryScreen(),
        ), settings);
      case AppRoutes.inventoryStockDetails:
        return _page(StockDetailsScreen(productId: args as String), settings);
      case AppRoutes.salesNew:
        return _page(ModernAppShell(
          currentIndex: 2,
          child: const NewSaleScreen(),
        ), settings);
      case AppRoutes.salesToday:
        return _page(const TodaysSalesScreen(), settings);
      case AppRoutes.salesHistory:
        return _page(const SalesHistoryScreen(), settings);
      case AppRoutes.salesDetails:
        return _page(SaleDetailsScreen(saleId: args as String), settings);
      case AppRoutes.customers:
        return _page(const CustomerListScreen(), settings);
      case AppRoutes.customersDetails:
        return _page(CustomerDetailsScreen(customerId: args as String), settings);
      case AppRoutes.dailyAdditions:
        return _page(const DailyAdditionsScreen(), settings);
      case AppRoutes.warranty:
        return _page(const WarrantyCheckScreen(), settings);
      case AppRoutes.warrantyDetails:
        return _page(WarrantyDetailsScreen(warrantyId: args as String), settings);
      case AppRoutes.reports:
        return _page(const ReportsScreen(), settings);
      case AppRoutes.reportsAnalytics:
        return _page(ModernAppShell(
          currentIndex: 3,
          child: const AnalyticsScreen(),
        ), settings);
      case AppRoutes.productIssues:
        return _page(const ProductIssueListScreen(), settings);
      case AppRoutes.productIssuesDetails:
        return _page(ProductIssueDetailsScreen(issueId: args as String), settings);
      case AppRoutes.replacements:
        return _page(const ReplacementListScreen(), settings);
      case AppRoutes.replacementsDetails:
        return _page(ReplacementDetailsScreen(replacementId: args as String), settings);
      case AppRoutes.settings:
        return _page(ModernAppShell(
          currentIndex: 4,
          child: const SettingsScreen(),
        ), settings);
      case AppRoutes.search:
        return _page(const SearchScreen(), settings);
      default:
        return _page(ModernAppShell(
          currentIndex: 0,
          child: const DashboardScreen(),
        ), settings);
    }
  }

  static MaterialPageRoute _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => child, settings: settings);
  }
}
