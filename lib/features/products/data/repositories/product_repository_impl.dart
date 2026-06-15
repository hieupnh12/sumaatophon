import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_mock_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductMockDataSource dataSource;

  ProductRepositoryImpl(this.dataSource);

  @override
  Future<List<Product>> getProducts() {
    return dataSource.getProducts();
  }
}
