import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';

class PayOsPaymentResult {
  final String checkoutUrl;
  final String? qrCode;
  final String? paymentLinkId;

  const PayOsPaymentResult({
    required this.checkoutUrl,
    this.qrCode,
    this.paymentLinkId,
  });

  factory PayOsPaymentResult.fromJson(Map<String, dynamic> json) {
    return PayOsPaymentResult(
      checkoutUrl: json['checkoutUrl'] as String? ?? '',
      qrCode: json['qrCode'] as String?,
      paymentLinkId: json['paymentLinkId'] as String?,
    );
  }
}

abstract class PaymentRemoteDataSource {
  Future<PayOsPaymentResult> createPayOsCheckout({
    required String orderId,
    required int amount,
    required String description,
  });
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

    throw Exception('PayOS create payment failed');
  }
}
