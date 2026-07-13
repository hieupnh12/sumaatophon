import '../../domain/entities/product.dart';
import '../../domain/entities/product_feedback.dart';
import '../../domain/entities/product_feedback_eligibility.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<List<Product>> getProducts() async {
    try {
      final products = await remoteDataSource.getProducts();
      await localDataSource.cacheProducts(products);
      return products;
    } catch (e) {
      final cached = await localDataSource.getCachedProducts();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      final product = await remoteDataSource.getProductById(id);
      await localDataSource.cacheProduct(product);
      return product;
    } catch (e) {
      final cached = await localDataSource.getCachedProductById(id);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<ProductFeedbackEligibility> getFeedbackStatus(
    String productId,
    int customerId,
  ) {
    return remoteDataSource.getFeedbackStatus(productId, customerId);
  }

  @override
  Future<ProductFeedback> submitFeedback({
    required String productId,
    required int customerId,
    required int rate,
    required String content,
  }) {
    return remoteDataSource.submitFeedback(
      productId: productId,
      customerId: customerId,
      rate: rate,
      content: content,
    );
  }
}
