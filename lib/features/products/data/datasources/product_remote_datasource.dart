import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_feedback.dart';
import '../../domain/entities/product_feedback_eligibility.dart';
import '../models/product_feedback_model.dart';
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

  Future<List<ProductFeedback>> getProductFeedbacks(String id) async {
    final data = await apiClient.get(ApiEndpoints.productFeedbacks(id));

    if (data is! List) {
      throw FormatException('Expected list from /products/$id/feedbacks');
    }

    return data
        .whereType<Map>()
        .map((item) => ProductFeedbackModel.fromJson(Map<String, dynamic>.from(item)).toEntity())
        .toList();
  }

  Future<Product> getProductById(String id) async {
    final data = await apiClient.get(ApiEndpoints.productById(id));

    if (data is! Map<String, dynamic>) {
      throw FormatException('Expected map from /products/$id');
    }

    var product = ProductModel.fromJson(data).toEntity();

    if (product.feedbacks.isEmpty) {
      try {
        final feedbacks = await getProductFeedbacks(id);
        if (feedbacks.isNotEmpty) {
          product = product.copyWith(feedbacks: feedbacks);
        }
      } catch (_) {
        // Giữ product không có feedback nếu endpoint chưa sẵn sàng.
      }
    }

    return product;
  }

  Future<ProductFeedbackEligibility> getFeedbackStatus(
    String productId,
    int customerId,
  ) async {
    final data = await apiClient.get(
      ApiEndpoints.productFeedbackStatus(productId),
      queryParameters: {'customerId': customerId},
    );

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected map from feedback-status');
    }

    return ProductFeedbackEligibility.fromJson(data);
  }

  Future<ProductFeedback> submitFeedback({
    required String productId,
    required int customerId,
    required int rate,
    required String content,
  }) async {
    final data = await apiClient.post(
      ApiEndpoints.productFeedbacks(productId),
      body: {
        'customerId': customerId,
        'rate': rate,
        'content': content,
      },
    );

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected map from POST feedback');
    }

    return ProductFeedbackModel.fromJson(data).toEntity();
  }
}
