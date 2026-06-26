class CheckoutLocationData {
  static const defaultProvince = 'Đà Nẵng';

  static const provinces = [
    'Đà Nẵng',
    'TP. Hồ Chí Minh',
    'Hà Nội',
  ];

  static const districts = <String, List<String>>{
    'Đà Nẵng': [
      'Quận Cẩm Lệ',
      'Quận Hải Châu',
      'Quận Thanh Khê',
      'Quận Liên Chiểu',
    ],
    'TP. Hồ Chí Minh': [
      'Quận 1',
      'Quận 3',
      'Quận 7',
    ],
    'Hà Nội': [
      'Quận Ba Đình',
      'Quận Cầu Giấy',
      'Quận Đống Đa',
    ],
  };

  static const wards = <String, List<String>>{
    'Quận Cẩm Lệ': [
      'Phường Hòa Thọ Tây',
      'Phường Hòa Thọ Đông',
      'Phường Hòa Xuân',
    ],
    'Quận Hải Châu': [
      'Phường Hải Châu I',
      'Phường Hải Châu II',
    ],
    'Quận Thanh Khê': [
      'Phường Thanh Khê Đông',
      'Phường Thanh Khê Tây',
    ],
    'Quận Liên Chiểu': [
      'Phường Hòa Minh',
      'Phường Hòa Khánh Bắc',
    ],
    'Quận 1': ['Phường Bến Nghé', 'Phường Bến Thành'],
    'Quận 3': ['Phường 1', 'Phường 2'],
    'Quận 7': ['Phường Tân Phú', 'Phường Tân Hưng'],
    'Quận Ba Đình': ['Phường Điện Biên', 'Phường Kim Mã'],
    'Quận Cầu Giấy': ['Phường Dịch Vọng', 'Phường Nghĩa Đô'],
    'Quận Đống Đa': ['Phường Láng Hạ', 'Phường Ô Chợ Dừa'],
  };

  static const stores = <String, List<String>>{
    'Quận Cẩm Lệ': [
      'CellphoneS 123 Nguyễn Văn Linh, Quận Cẩm Lệ',
      'CellphoneS 456 Lê Duẩn, Quận Cẩm Lệ',
    ],
    'Quận Hải Châu': [
      'CellphoneS 78 Trần Phú, Quận Hải Châu',
    ],
    'Quận Thanh Khê': [
      'CellphoneS 90 Nguyễn Hữu Thọ, Quận Thanh Khê',
    ],
    'Quận Liên Chiểu': [
      'CellphoneS 12 Hoàng Văn Thái, Quận Liên Chiểu',
    ],
    'Quận 1': ['CellphoneS 1 Nguyễn Huệ, Quận 1'],
    'Quận 3': ['CellphoneS 55 Võ Văn Tần, Quận 3'],
    'Quận 7': ['CellphoneS 99 Nguyễn Lương Bằng, Quận 7'],
    'Quận Ba Đình': ['CellphoneS 10 Kim Mã, Quận Ba Đình'],
    'Quận Cầu Giấy': ['CellphoneS 20 Xuân Thủy, Quận Cầu Giấy'],
    'Quận Đống Đa': ['CellphoneS 30 Tây Sơn, Quận Đống Đa'],
  };
}
