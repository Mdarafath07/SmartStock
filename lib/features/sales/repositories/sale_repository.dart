import 'package:smartstock/features/sales/models/sale_model.dart';
import 'package:smartstock/features/sales/models/serial_number_model.dart';
import 'package:smartstock/features/sales/services/sale_service.dart';

class SaleRepository {
  final SaleService _saleService = SaleService();

  Future<String> createSale({
    required String productId,
    required String productName,
    required String modelNumber,
    required String categoryId,
    required String categoryName,
    required String serialNumber,
    required String serialNumberId,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required double salePrice,
    required double purchasePrice,
    required DateTime warrantyExpiryDate,
  }) {
    return _saleService.createSale(
      productId: productId,
      productName: productName,
      modelNumber: modelNumber,
      categoryId: categoryId,
      categoryName: categoryName,
      serialNumber: serialNumber,
      serialNumberId: serialNumberId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      warrantyExpiryDate: warrantyExpiryDate,
    );
  }

  Future<List<String>> bulkCreateSales({
    required List<Map<String, dynamic>> items,
    required String customerId,
    required String customerName,
    required String customerPhone,
  }) {
    return _saleService.bulkCreateSales(
      items: items,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
    );
  }

  Future<List<Sale>> getTodaysSales() => _saleService.getTodaysSales();

  Future<List<Sale>> getSalesHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
    String? categoryId,
    String? customerId,
  }) {
    return _saleService.getSalesHistory(
      startDate: startDate,
      endDate: endDate,
      productId: productId,
      categoryId: categoryId,
      customerId: customerId,
    );
  }

  Future<Sale?> getSaleById(String id) => _saleService.getSaleById(id);

  Future<List<Sale>> searchSaleBySerialNumber(String serial) =>
      _saleService.searchSaleBySerialNumber(serial);

  Future<Map<String, dynamic>> getDailySalesSummary() =>
      _saleService.getDailySalesSummary();

  Future<List<SerialNumber>> getAvailableSerialNumbers(String productId) =>
      _saleService.getAvailableSerialNumbers(productId);

  Future<void> voidSale(String saleId) => _saleService.voidSale(saleId);
}
