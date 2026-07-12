import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';

class PayOsPaymentResult {
  final String checkoutUrl;
  final String? qrCode;
  final String? paymentLinkId;
  final String orderId;

  const PayOsPaymentResult({
    required this.checkoutUrl,
    this.qrCode,
    this.paymentLinkId,
    required this.orderId,
  });

  factory PayOsPaymentResult.fromJson(Map<String, dynamic> json) {
    return PayOsPaymentResult(
      checkoutUrl: json['checkoutUrl'] as String? ?? '',
      qrCode: json['qrCode'] as String?,
      paymentLinkId: json['paymentLinkId'] as String?,
      orderId: '${json['orderId'] ?? ''}',
    );
  }
}

class PayOsPaymentStatus {
  final String orderId;
  final String orderStatus;
  final bool isPaid;
  final String paymentStatus;

  const PayOsPaymentStatus({
    required this.orderId,
    required this.orderStatus,
    required this.isPaid,
    required this.paymentStatus,
  });

  factory PayOsPaymentStatus.fromJson(Map<String, dynamic> json) {
    return PayOsPaymentStatus(
      orderId: '${json['orderId'] ?? ''}',
      orderStatus: json['orderStatus'] as String? ?? 'PENDING',
      isPaid: json['isPaid'] == true,
      paymentStatus: json['paymentStatus'] as String? ?? 'PENDING',
    );
  }
}

abstract class PaymentRemoteDataSource {
  Future<PayOsPaymentResult> createPayOsCheckout({
    required String orderId,
    required int amount,
    required String description,
  });

  Future<PayOsPaymentStatus> getPayOsStatus(String orderId);

  Future<PayOsPaymentStatus> confirmPayOsPayment(String orderId);

  Future<void> cancelPayOsPayment(String orderId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final http.Client client;

  PaymentRemoteDataSourceImpl({required this.client});

  @override
  Future<PayOsPaymentResult> createPayOsCheckout({
    required String orderId,
    required int amount,
    required String description,
  }) async {
    final response = await client.post(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.payOsCreate}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'orderId': orderId,
        'amount': amount,
        'description': description,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return PayOsPaymentResult.fromJson(json.decode(response.body) as Map<String, dynamic>);
    }

    final body = response.body.isNotEmpty ? json.decode(response.body) : null;
    if (body is Map<String, dynamic>) {
      final code = body['code'] as String?;
      final message = body['message'] as String?;
      throw Exception('${code ?? 'PAYOS_CREATE_ERROR'}: ${message ?? 'PayOS create payment failed'}');
    }
    throw Exception('PAYOS_CREATE_ERROR: PayOS create payment failed');
  }

  @override
  Future<PayOsPaymentStatus> getPayOsStatus(String orderId) async {
    final response = await client
        .get(
          Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.payOsStatus(orderId)}'),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return PayOsPaymentStatus.fromJson(json.decode(response.body) as Map<String, dynamic>);
    }

    throw Exception('PayOS status check failed');
  }

  @override
  Future<PayOsPaymentStatus> confirmPayOsPayment(String orderId) async {
    final response = await client
        .post(
          Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.payOsConfirm}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'orderId': orderId}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return PayOsPaymentStatus.fromJson(json.decode(response.body) as Map<String, dynamic>);
    }

    throw Exception('PayOS confirm failed');
  }

  @override
  Future<void> cancelPayOsPayment(String orderId) async {
    final response = await client.post(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.payOsCancel}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'orderId': orderId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('PayOS cancel failed');
    }
  }
}
