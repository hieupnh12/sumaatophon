import '../../domain/entities/warranty_item.dart';
import '../../domain/entities/warranty_request.dart';
import '../../domain/repositories/warranty_repository.dart';
import '../datasources/warranty_remote_datasource.dart';

class WarrantyRepositoryImpl implements WarrantyRepository {
  final WarrantyRemoteDataSource remoteDataSource;

  WarrantyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<WarrantyItem>> getEligibleItems(int customerId) async {
    return await remoteDataSource.getEligibleItems(customerId);
  }

  @override
  Future<List<WarrantyRequest>> getWarrantyRequests(int customerId) async {
    return await remoteDataSource.getWarrantyRequests(customerId);
  }

  @override
  Future<void> submitWarrantyRequest({
    required int customerId,
    required int orderId,
    required String productVersionId,
    required String reason,
  }) async {
    await remoteDataSource.submitWarrantyRequest(
      customerId: customerId,
      orderId: orderId,
      productVersionId: productVersionId,
      reason: reason,
    );
  }
}
