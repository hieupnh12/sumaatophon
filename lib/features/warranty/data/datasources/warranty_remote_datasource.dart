import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/warranty_item_model.dart';
import '../models/warranty_request_model.dart';

abstract class WarrantyRemoteDataSource {
  Future<List<WarrantyItemModel>> getEligibleItems(int customerId);
  Future<List<WarrantyRequestModel>> getWarrantyRequests(int customerId);
  Future<void> submitWarrantyRequest({
    required int customerId,
    required int orderId,
    required String productVersionId,
    required String reason,
  });
}

class WarrantyRemoteDataSourceImpl implements WarrantyRemoteDataSource {
  final ApiClient apiClient;

  WarrantyRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<WarrantyItemModel>> getEligibleItems(int customerId) async {
    final response = await apiClient.get(
      ApiEndpoints.warrantiesEligible,
      queryParameters: {'customerId': customerId},
    );
    return (response as List)
        .map((e) => WarrantyItemModel.fromJson(e))
        .toList();
  }

  @override
  Future<List<WarrantyRequestModel>> getWarrantyRequests(int customerId) async {
    final response = await apiClient.get(
      ApiEndpoints.warranties,
      queryParameters: {'customerId': customerId},
    );
    return (response as List)
        .map((e) => WarrantyRequestModel.fromJson(e))
        .toList();
  }

  @override
  Future<void> submitWarrantyRequest({
    required int customerId,
    required int orderId,
    required String productVersionId,
    required String reason,
  }) async {
    await apiClient.post(ApiEndpoints.warranties, body: {
      'customerId': customerId,
      'orderId': orderId,
      'productVersionId': productVersionId,
      'reason': reason,
      'type': 'warranty',
    });
  }
}
