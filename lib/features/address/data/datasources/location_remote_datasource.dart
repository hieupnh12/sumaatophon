import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_models.dart';

abstract class LocationRemoteDataSource {
  Future<List<Province>> getProvinces();
  Future<List<Ward>> getWards(int provinceCode);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final http.Client client;

  LocationRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Province>> getProvinces() async {
    final response = await client.get(Uri.parse('https://provinces.open-api.vn/api/v2/p/'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => Province.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load provinces');
    }
  }

  @override
  Future<List<Ward>> getWards(int provinceCode) async {
    final response = await client.get(Uri.parse('https://provinces.open-api.vn/api/v2/p/$provinceCode?depth=2'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> wardsList = jsonMap['wards'] ?? [];
      return wardsList.map((json) => Ward.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load wards');
    }
  }
}
