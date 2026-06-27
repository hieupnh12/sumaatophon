import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/create_order_result.dart';

class CheckoutOrderItemPayload {
  final String productVersionId;
  final int quantity;
  final double unitPrice;

  const CheckoutOrderItemPayload({
    required this.productVersionId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
        'productVersionId': productVersionId,
        'quantity': quantity,
        'unitPrice': unitPrice.round(),
      };
}

class CreateOrderPayload {
  final String customerId;
  final List<CheckoutOrderItemPayload> items;
  final String paymentMethod;
  final String deliveryType;
  final String address;
  final String shippingMethod;
  final double shippingCost;
  final double subtotal;
  final double discount;
  final double total;
  final String note;
  final bool wantsEmailReceipt;
  final String? receiptEmail;

  const CreateOrderPayload({
    required this.customerId,
    required this.items,
    required this.paymentMethod,
    required this.deliveryType,
    required this.address,
    required this.shippingMethod,
    required this.shippingCost,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.note,
    this.wantsEmailReceipt = false,
    this.receiptEmail,
  });

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'items': items.map((item) => item.toJson()).toList(),
        'paymentMethod': paymentMethod,
        'deliveryType': deliveryType,
        'address': address,
        'shippingMethod': shippingMethod,
        'shippingCost': shippingCost.round(),
        'subtotal': subtotal.round(),
        'discount': discount.round(),
        'total': total.round(),
        'note': note,
        'wantsEmailReceipt': wantsEmailReceipt,
        if (receiptEmail != null && receiptEmail!.isNotEmpty) 'receiptEmail': receiptEmail,
      };
}

abstract class CheckoutRemoteDataSource {
  Future<CreateOrderResult> createOrder(CreateOrderPayload payload);
}

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  final ApiClient apiClient;

  CheckoutRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<CreateOrderResult> createOrder(CreateOrderPayload payload) async {
    final body = await apiClient.post(
      ApiEndpoints.orders,
      body: payload.toJson(),
    );
    return CreateOrderResult.fromJson(body as Map<String, dynamic>);
  }
}
