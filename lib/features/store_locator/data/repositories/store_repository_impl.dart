import '../../domain/entities/store_entity.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_remote_datasource.dart';

class StoreRepositoryImpl implements StoreRepository {
  final StoreRemoteDataSource remoteDataSource;

  StoreRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<StoreEntity>> getStores({
    double? latitude,
    double? longitude,
  }) async {
    final models = await remoteDataSource.getStores(
      latitude: latitude,
      longitude: longitude,
    );
    return models.map((model) => model.toEntity()).toList();
  }
}
