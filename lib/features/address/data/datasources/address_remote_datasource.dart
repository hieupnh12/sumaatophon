import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_endpoints.dart';
import '../models/address_model.dart';

abstract class AddressRemoteDataSource {
  Future<List<AddressModel>> getAddresses(String customerId);
  Future<AddressModel> addAddress(String customerId, AddressModel address);
  Future<AddressModel> updateAddress(String customerId, AddressModel address);
  Future<void> deleteAddress(String id, String customerId);
  Future<void> setDefaultAddress(String id, String customerId);
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final http.Client client;

  AddressRemoteDataSourceImpl({required this.client});

  @override
  Future<List<AddressModel>> getAddresses(String customerId) async {
    final response = await client.get(
      Uri.parse('${ApiEndpoints.baseUrl}/api/addresses?customerId=$customerId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => AddressModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load addresses: HTTP ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Future<AddressModel> addAddress(String customerId, AddressModel address) async {
    final response = await client.post(
      Uri.parse('${ApiEndpoints.baseUrl}/api/addresses'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customerId': customerId,
        'province': address.province,
        'ward': address.ward,
        'street': address.street,
        'type': address.type,
        'isDefault': address.isDefault,
        'receiverName': address.receiverName,
        'receiverPhone': address.receiverPhone,
      }),
    );

    if (response.statusCode == 200) {
      return AddressModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add address');
    }
  }

  @override
  Future<AddressModel> updateAddress(String customerId, AddressModel address) async {
    final response = await client.put(
      Uri.parse('${ApiEndpoints.baseUrl}/api/addresses/${address.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customerId': customerId,
        'province': address.province,
        'ward': address.ward,
        'street': address.street,
        'type': address.type,
        'isDefault': address.isDefault,
        'receiverName': address.receiverName,
        'receiverPhone': address.receiverPhone,
      }),
    );

    if (response.statusCode == 200) {
      return AddressModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update address');
    }
  }

  @override
  Future<void> deleteAddress(String id, String customerId) async {
    final response = await client.delete(
      Uri.parse('${ApiEndpoints.baseUrl}/api/addresses/$id?customerId=$customerId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete address');
    }
  }

  @override
  Future<void> setDefaultAddress(String id, String customerId) async {
    final response = await client.put(
      Uri.parse('${ApiEndpoints.baseUrl}/api/addresses/$id/default'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customerId': customerId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to set default address');
    }
  }
}
