import '../entities/warranty_item.dart';
import '../entities/warranty_request.dart';

abstract class WarrantyRepository {
  Future<List<WarrantyItem>> getEligibleItems(int customerId);
  Future<List<WarrantyRequest>> getWarrantyRequests(int customerId);
  Future<void> submitWarrantyRequest({
    required int customerId,
    required int orderId,
    required String productVersionId,
    required String reason,
  });
}
