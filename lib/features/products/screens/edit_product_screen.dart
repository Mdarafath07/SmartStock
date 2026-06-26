import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/widgets/debounced.dart';
import 'package:smartstock/features/products/models/product_model.dart';
import 'package:smartstock/features/products/providers/product_provider.dart';
import 'package:smartstock/features/products/screens/product_details_screen.dart';
import 'package:smartstock/features/products/widgets/product_form.dart';
import 'package:smartstock/features/sales/screens/sale_details_screen.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductById(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Edit Product',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedProduct == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.selectedProduct == null) {
            return const Center(
              child: Text(
                'Product not found',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.error,
                ),
              ),
            );
          }

          return ProductForm(
            product: provider.selectedProduct,
            isEdit: true,
            onSave: (Product product, List<String> serialNumbers) {
              return _handleSave(context, product, serialNumbers);
            },
          );
        },
      ),
    );
  }

  Future<void> _handleSave(
      BuildContext context, Product product, List<String> serialNumbers) async {
    try {
      final provider = context.read<ProductProvider>();
      await provider.updateProduct(product);
      if (serialNumbers.isNotEmpty) {
        await provider.addSerialNumbers(product.id, serialNumbers);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context);
      }
    } on DuplicateSerialException catch (e) {
      if (context.mounted) {
        _showDuplicateDialog(context, e.duplicates);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product: $e')),
        );
      }
    }
  }

  void _showDuplicateDialog(
      BuildContext context, List<DuplicateSerialInfo> duplicates) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('Serial Already Exists')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: duplicates.map((dup) {
              final isSold = dup.status == 'sold';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Debounced(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (isSold && dup.saleId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SaleDetailsScreen(saleId: dup.saleId!),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(
                              productId: dup.existingProductId),
                        ),
                      );
                    }
                  },
                  builder: (context, isDisabled) => InkWell(
                    onTap: isDisabled ? null : () {
                      Navigator.pop(ctx);
                      if (isSold && dup.saleId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SaleDetailsScreen(saleId: dup.saleId!),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailsScreen(
                                productId: dup.existingProductId),
                          ),
                        );
                      }
                    },
                    child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(dup.existingProductName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            Icon(Icons.open_in_new,
                                size: 14, color: Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('S/N: ${dup.serialNumber}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('Model: ${dup.existingProductModel}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('Added: ${dateFormat.format(dup.createdAt)}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSold
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSold ? 'SOLD' : 'Available',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSold ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                        if (isSold) ...[
                          const SizedBox(height: 6),
                          if (dup.saleDate != null)
                            _detailRow(Icons.calendar_today,
                                'Sold: ${dateFormat.format(dup.saleDate!)}'),
                          if (dup.customerName != null &&
                              dup.customerName!.isNotEmpty)
                            _detailRow(Icons.person, 'Customer: ${dup.customerName}'),
                          if (dup.salePrice != null)
                            _detailRow(Icons.payments,
                                'Price: ${currencyFormat.format(dup.salePrice)}'),
                          if (dup.saleId != null)
                            Text('Tap to view sale details',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ),
                  ),
              );
            }).toList(),
          ),
        ),
        actions: [
          Debounced(
            onPressed: () => Navigator.pop(ctx),
            builder: (_, isDisabled) => TextButton(
              onPressed: isDisabled ? null : () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
