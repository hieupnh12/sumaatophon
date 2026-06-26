import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_remote_datasource.dart';
import '../datasources/location_remote_datasource.dart';
import '../models/address_model.dart';
import '../models/location_models.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource remoteDataSource;
  final LocationRemoteDataSource locationDataSource;

  AddressRepositoryImpl({
    required this.remoteDataSource,
    required this.locationDataSource,
  });

  @override
  Future<List<Address>> getAddresses(String customerId) async {
    try {
      return await remoteDataSource.getAddresses(customerId);
    } catch (e) {
      throw Exception('Failed to load addresses: $e');
    }
  }

  @override
  Future<Address> addAddress(String customerId, Address address) async {
    try {
      final addressModel = AddressModel.fromEntity(address);
      return await remoteDataSource.addAddress(customerId, addressModel);
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  @override
  Future<Address> updateAddress(String customerId, Address address) async {
    try {
      final addressModel = AddressModel.fromEntity(address);
      return await remoteDataSource.updateAddress(customerId, addressModel);
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  @override
  Future<void> deleteAddress(String customerId, String id) async {
    try {
      await remoteDataSource.deleteAddress(id, customerId);
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  @override
  Future<void> setDefaultAddress(String customerId, String id) async {
    try {
      await remoteDataSource.setDefaultAddress(id, customerId);
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  @override
  Future<List<Province>> getProvinces() async {
    return await locationDataSource.getProvinces();
  }

  @override
  Future<List<Ward>> getWards(int provinceCode) async {
    return await locationDataSource.getWards(provinceCode);
  }
}
