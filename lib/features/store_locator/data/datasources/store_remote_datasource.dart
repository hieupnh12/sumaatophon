import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/store_model.dart';

class StoreRemoteDataSource {
  final ApiClient apiClient;

  StoreRemoteDataSource(this.apiClient);

  Future<List<StoreModel>> getStores({
    double? latitude,
    double? longitude,
  }) async {
    final query = <String, dynamic>{};
    if (latitude != null && longitude != null) {
      query['lat'] = latitude;
      query['lng'] = longitude;
    }

    final data = await apiClient.get(
      ApiEndpoints.stores,
      queryParameters: query.isEmpty ? null : query,
    );

    if (data is! List) {
      throw const FormatException('Expected list from /stores');
    }

    return data
        .whereType<Map>()
        .map((item) => StoreModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
