import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/routes/route_generator.dart';
import 'package:smartstock/core/services/connectivity_service.dart';
import 'package:smartstock/core/theme/app_theme.dart';
import 'package:smartstock/core/widgets/offline_banner.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/customers/providers/customer_provider.dart';
import 'package:smartstock/features/dashboard/providers/dashboard_provider.dart';
import 'package:smartstock/features/integrations/providers/sync_provider.dart';
import 'package:smartstock/features/inventory/providers/inventory_provider.dart';
import 'package:smartstock/features/inventory/repositories/inventory_repository.dart';
import 'package:smartstock/features/inventory/services/inventory_service.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/product_issues/providers/product_issue_provider.dart';
import 'package:smartstock/features/replacements/providers/replacement_provider.dart';
import 'package:smartstock/features/reports/providers/report_provider.dart';
import 'package:smartstock/features/sales/providers/sale_provider.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:smartstock/features/daily_additions/providers/daily_addition_provider.dart';
import 'package:smartstock/features/warranty/providers/warranty_provider.dart';
import 'package:smartstock/firebase_options_dev.dart' as dev;
import 'package:smartstock/firebase_options_prod.dart' as prod;

const String appFlavor = String.fromEnvironment('FLUTTER_APP_FLAVOR', defaultValue: 'prod');
const bool isDev = appFlavor == 'dev';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  try {
    await Firebase.initializeApp(
      options: isDev
          ? dev.DefaultFirebaseOptions.currentPlatform
          : prod.DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Already initialized via native google-services.json
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final connectivity = ConnectivityService();
  await connectivity.init();

  runApp(SmartStockApp(connectivity: connectivity));
}

class SmartStockApp extends StatelessWidget {
  final ConnectivityService connectivity;
  const SmartStockApp({super.key, required this.connectivity});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: connectivity),
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
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => DailyAdditionProvider()),
        ChangeNotifierProvider(create: (_) => WarrantyProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ProductIssueProvider()),
        ChangeNotifierProvider(create: (_) => ReplacementProvider()),
      ],
      child: MaterialApp(
        title: 'SmartStock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: RouteGenerator.onGenerateRoute,
        builder: (context, child) => OfflineBanner(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}


