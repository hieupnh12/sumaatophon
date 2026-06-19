import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/product.dart';
import '../models/product_model.dart';

/// Gọi REST API backend để lấy danh sách sản phẩm từ MySQL (qua backend).
class ProductRemoteDataSource {
  final ApiClient apiClient;

  ProductRemoteDataSource(this.apiClient);

  Future<List<Product>> getProducts() async {
    final data = await apiClient.get(ApiEndpoints.products);

    if (data is! List) {
      throw const FormatException('Expected list from /products');
    }

    return data
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>).toEntity())
        .toList();
  }
}
