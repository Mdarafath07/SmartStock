import 'package:flutter/material.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/features/sales/widgets/sale_form.dart';

class NewSaleScreen extends StatelessWidget {
  const NewSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _NewSaleScreenContent();
  }
}

class _NewSaleScreenContent extends StatelessWidget {
  const _NewSaleScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SaleForm(
        onSaleComplete: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home, (route) => false,
          );
        },
      ),
    );
  }
}
