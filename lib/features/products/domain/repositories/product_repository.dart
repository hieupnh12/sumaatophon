import '../entities/product.dart';
import '../entities/product_feedback.dart';
import '../entities/product_feedback_eligibility.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();

  Future<Product> getProductById(String id);

  Future<ProductFeedbackEligibility> getFeedbackStatus(
    String productId,
    int customerId,
  );

  Future<ProductFeedback> submitFeedback({
    required String productId,
    required int customerId,
    required int rate,
    required String content,
  });
}
