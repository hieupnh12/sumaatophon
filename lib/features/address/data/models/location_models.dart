class Province {
  final int code;
  final String name;

  Province({required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'] as int,
      name: json['name'] as String,
    );
  }
}

class Ward {
  final int code;
  final String name;
  final int provinceCode;

  Ward({required this.code, required this.name, required this.provinceCode});

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: json['code'] as int,
      name: json['name'] as String,
      provinceCode: json['province_code'] as int,
    );
  }
}
