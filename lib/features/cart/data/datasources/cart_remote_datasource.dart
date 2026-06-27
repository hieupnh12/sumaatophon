import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../models/cart_item_model.dart';

class CartRemoteDatasource {
  final http.Client client;

  CartRemoteDatasource(this.client);

  Future<List<CartItemModel>> getItems(String customerId) async {
    final response = await client.get(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.cart}?customerId=$customerId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => CartItemModel.fromJson(json)).toList();
    }

    throw _parseError(response);
  }

  Future<List<CartItemModel>> addItem(String customerId, String productVersionId) async {
    final response = await client.post(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.cartItems}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customerId': customerId,
        'productVersionId': productVersionId,
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => CartItemModel.fromJson(json)).toList();
    }

    throw _parseError(response);
  }

  Future<List<CartItemModel>> updateQuantity(
    String customerId,
    String productVersionId,
    int quantity,
  ) async {
    final response = await client.put(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.cartItemByVersionId(productVersionId)}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customerId': customerId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => CartItemModel.fromJson(json)).toList();
    }

    throw _parseError(response);
  }

  Future<List<CartItemModel>> removeItem(String customerId, String productVersionId) async {
    final response = await client.delete(
      Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.cartItemByVersionId(productVersionId)}?customerId=$customerId',
      ),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => CartItemModel.fromJson(json)).toList();
    }

    throw _parseError(response);
  }

  Future<void> clearCart(String customerId) async {
    final response = await client.delete(
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.cart}?customerId=$customerId'),
    );

    if (response.statusCode != 200) {
      throw _parseError(response);
    }
  }

  Exception _parseError(http.Response response) {
    if (response.statusCode == 404) {
      return CartApiException(
        'cart_api_not_found',
        'Cart API not found (${response.statusCode}). Restart backend (`cd backend && npm start`) or deploy image co `backend/src/`.',
      );
    }

    try {
      final body = json.decode(response.body);
      final code = body['code'] as String?;
      if (code == 'MAX_STOCK' || code == 'OUT_OF_STOCK') {
        return CartStockException(code!);
      }
      return CartApiException(
        code ?? 'CART_ERROR',
        body['message']?.toString() ?? 'Cart request failed',
      );
    } catch (_) {
      return CartApiException(
        'CART_HTTP_${response.statusCode}',
        'Cart request failed (${response.statusCode})',
      );
    }
  }
}

class CartApiException implements Exception {
  final String code;
  final String message;

  CartApiException(this.code, this.message);

  @override
  String toString() => message;
}

class CartStockException implements Exception {
  final String code;

  CartStockException(this.code);

  @override
  String toString() => code;
}
