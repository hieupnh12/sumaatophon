import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource dataSource;

  ProductRepositoryImpl(this.dataSource);

  @override
  Future<List<Product>> getProducts() {
    return dataSource.getProducts();
  }
   

  //lấy từ bên product_repository và product_remote_datasource và trả về Product entity
  @override
  Future<Product> getProductById(String id) {
    return dataSource.getProductById(id);
  }
}
