import 'package:flutter/material.dart';
import 'app_routes.dart';
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
import '../../features/settings/screens/settings_screen.dart';
import '../../features/search/screens/search_screen.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.home:
        return _materialPageRoute(
          const DashboardScreen(),
          settings,
        );
      case AppRoutes.products:
        return _materialPageRoute(
          const ProductListScreen(),
          settings,
        );
      case AppRoutes.productsAdd:
        return _materialPageRoute(
          const AddProductScreen(),
          settings,
        );
      case AppRoutes.productsEdit:
        return _materialPageRoute(
          EditProductScreen(productId: args as String),
          settings,
        );
      case AppRoutes.productsDetails:
        return _materialPageRoute(
          ProductDetailsScreen(productId: args as String),
          settings,
        );
      case AppRoutes.categories:
        return _materialPageRoute(
          const CategoryManagementScreen(),
          settings,
        );
      case AppRoutes.categoriesAdd:
        return _materialPageRoute(
          const AddCategoryScreen(),
          settings,
        );
      case AppRoutes.inventory:
        return _materialPageRoute(
          const InventoryScreen(),
          settings,
        );
      case AppRoutes.inventoryStockDetails:
        return _materialPageRoute(
          StockDetailsScreen(productId: args as String),
          settings,
        );
      case AppRoutes.salesNew:
        return _materialPageRoute(
          const NewSaleScreen(),
          settings,
        );
      case AppRoutes.salesToday:
        return _materialPageRoute(
          const TodaysSalesScreen(),
          settings,
        );
      case AppRoutes.salesHistory:
        return _materialPageRoute(
          const SalesHistoryScreen(),
          settings,
        );
      case AppRoutes.salesDetails:
        return _materialPageRoute(
          SaleDetailsScreen(saleId: args as String),
          settings,
        );
      case AppRoutes.customers:
        return _materialPageRoute(
          const CustomerListScreen(),
          settings,
        );
      case AppRoutes.customersDetails:
        return _materialPageRoute(
          CustomerDetailsScreen(customerId: args as String),
          settings,
        );
      case AppRoutes.warranty:
        return _materialPageRoute(
          const WarrantyCheckScreen(),
          settings,
        );
      case AppRoutes.warrantyDetails:
        return _materialPageRoute(
          WarrantyDetailsScreen(warrantyId: args as String),
          settings,
        );
      case AppRoutes.reports:
        return _materialPageRoute(
          const ReportsScreen(),
          settings,
        );
      case AppRoutes.reportsAnalytics:
        return _materialPageRoute(
          const AnalyticsScreen(),
          settings,
        );
      case AppRoutes.settings:
        return _materialPageRoute(
          const SettingsScreen(),
          settings,
        );
      case AppRoutes.search:
        return _materialPageRoute(
          const SearchScreen(),
          settings,
        );
      default:
        return _materialPageRoute(
          const DashboardScreen(),
          settings,
        );
    }
  }

  static MaterialPageRoute _materialPageRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
