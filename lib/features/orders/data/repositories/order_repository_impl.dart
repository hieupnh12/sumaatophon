import '../../domain/entities/order.dart';
import '../../domain/entities/order_detail.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Order>> getOrders(int customerId) async {
    return await remoteDataSource.getOrders(customerId);
  }

  @override
  Future<OrderDetail> getOrderDetail(int orderId, int customerId) async {
    return await remoteDataSource.getOrderDetail(orderId, customerId);
  }
}
