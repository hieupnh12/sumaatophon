import '../entities/order.dart';
import '../entities/order_detail.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrders(int customerId);
  Future<OrderDetail> getOrderDetail(int orderId, int customerId);
}
