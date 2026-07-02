import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/features/categories/providers/category_provider.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/sales/widgets/sale_form.dart';

class NewSaleScreen extends StatelessWidget {
  const NewSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: const _NewSaleScreenContent(),
    );
  }
}

class _NewSaleScreenContent extends StatelessWidget {
  const _NewSaleScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SaleForm(
        onSaleComplete: () {
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}
