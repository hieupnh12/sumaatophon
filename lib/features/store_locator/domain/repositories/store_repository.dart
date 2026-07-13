import '../entities/store_entity.dart';

abstract class StoreRepository {
  Future<List<StoreEntity>> getStores({
    double? latitude,
    double? longitude,
  });
}
