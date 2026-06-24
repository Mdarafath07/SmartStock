import 'package:smartstock/features/warranty/models/warranty_model.dart';
import 'package:smartstock/features/warranty/services/warranty_service.dart';

class WarrantyRepository {
  final WarrantyService _service;

  WarrantyRepository(this._service);

  Future<List<Warranty>> getAllWarranties() {
    return _service.getAllWarranties();
  }

  Future<List<Warranty>> searchWarranty({
    String? category,
    String? modelNumber,
    String? serialNumber,
  }) {
    return _service.searchWarranty(
      category: category,
      modelNumber: modelNumber,
      serialNumber: serialNumber,
    );
  }

  Future<Warranty?> getWarrantyBySerialNumber(String serial) {
    return _service.getWarrantyBySerialNumber(serial);
  }

  Future<List<Warranty>> getExpiredWarranties() {
    return _service.getExpiredWarranties();
  }

  Future<List<Warranty>> getActiveWarranties() {
    return _service.getActiveWarranties();
  }

  Future<Warranty?> getWarrantyBySaleId(String saleId) {
    return _service.getWarrantyBySaleId(saleId);
  }
}
