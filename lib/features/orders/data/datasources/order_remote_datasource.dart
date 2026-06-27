import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/order_detail_model.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getOrders(int customerId);
  Future<OrderDetailModel> getOrderDetail(int orderId, int customerId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient apiClient;

  OrderRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<OrderModel>> getOrders(int customerId) async {
    final response = await apiClient.get(
      ApiEndpoints.orders,
      queryParameters: {'customerId': customerId},
    );

    if (response is List) {
      return response.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<OrderDetailModel> getOrderDetail(int orderId, int customerId) async {
    final response = await apiClient.get(
      ApiEndpoints.orderById(orderId.toString()),
      queryParameters: {'customerId': customerId},
    );

    return OrderDetailModel.fromJson(response as Map<String, dynamic>);
  }
}
