class CheckoutLocationData {
  static const defaultProvince = 'Đà Nẵng';
  static const defaultDistrict = 'Quận Ngũ Hành Sơn';
  static const defaultStoreName = 'FShop';
  static const defaultStoreAddress =
      'X6WQ+R5M, Khu đô thị FPT City, Ngũ Hành Sơn, Đà Nẵng 550000, Việt Nam';
  static const defaultStoreLabel = '$defaultStoreName — $defaultStoreAddress';

  static const provinces = [defaultProvince];

  static const districts = <String, List<String>>{
    defaultProvince: [defaultDistrict],
  };

  static const stores = <String, List<String>>{
    defaultDistrict: [defaultStoreLabel],
  };
}
