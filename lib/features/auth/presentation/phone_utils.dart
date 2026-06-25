/// Chuẩn hóa SĐT VN: chỉ giữ chữ số (bỏ khoảng trắng, dấu).
String normalizePhone(String input) => input.replaceAll(RegExp(r'\D'), '');
