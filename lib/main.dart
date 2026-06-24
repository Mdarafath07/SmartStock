import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/routes/route_generator.dart';
import 'package:smartstock/core/theme/app_theme.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/customers/providers/customer_provider.dart';
import 'package:smartstock/features/dashboard/providers/dashboard_provider.dart';
import 'package:smartstock/features/inventory/providers/inventory_provider.dart';
import 'package:smartstock/features/inventory/repositories/inventory_repository.dart';
import 'package:smartstock/features/inventory/services/inventory_service.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/reports/providers/report_provider.dart';
import 'package:smartstock/features/sales/providers/sale_provider.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:smartstock/features/warranty/providers/warranty_provider.dart';
import 'package:smartstock/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartStockApp());
}

class SmartStockApp extends StatelessWidget {
  const SmartStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DashboardProvider()..loadDashboardStats(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider()..loadCategories(),
        ),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(
            InventoryRepository(InventoryService()),
          ),
        ),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => WarrantyProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'SmartStock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.home,
        onGenerateRoute: RouteGenerator.onGenerateRoute,
      ),
    );
  }
}
