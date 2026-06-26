import '../entities/address.dart';
import '../../data/models/location_models.dart';

abstract class AddressRepository {
  Future<List<Address>> getAddresses(String customerId);
  Future<void> addAddress(String customerId, Address address);
  Future<void> updateAddress(String customerId, Address address);
  Future<void> deleteAddress(String customerId, String id);
  Future<void> setDefaultAddress(String customerId, String id);
  
  Future<List<Province>> getProvinces();
  Future<List<Ward>> getWards(int provinceCode);
}
