import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/product.dart';
import '../models/product_model.dart';

/// Gọi REST API backend để lấy danh sách sản phẩm từ MySQL (qua backend).
class ProductRemoteDataSource {
  final ApiClient apiClient;

  ProductRemoteDataSource(this.apiClient);
   
  // lấy danh sách sản phẩm từ MySQL (qua backend) → ProductModel → Product entity , trả về List<Product>  và tránh lỗi bất đồng bộ 
  Future<List<Product>> getProducts() async {
    final data = await apiClient.get(ApiEndpoints.products);

    if (data is! List) {
      throw const FormatException('Expected list from /products');
    }

    return data
        .map((item) => ProductModel.fromJson(item as Map<String, dynamic>).toEntity())
        .toList();
  }

   
  // lấy sản phẩm theo id từ MySQL (qua backend) → ProductModel → Product entity , trả về Product và tránh lỗi bất đồng bộ
  Future<Product> getProductById(String id) async {
    final data = await apiClient.get(ApiEndpoints.productById(id));
    
    //dòng này là để kiểm tra dữ liệu nhận từ backend có phải là map không
    if (data is! Map<String, dynamic>) {
      throw FormatException('Expected map from /products/$id');
    }

    return ProductModel.fromJson(data).toEntity();
  }

}
