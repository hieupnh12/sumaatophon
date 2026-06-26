import 'package:intl/intl.dart';

String formatCheckoutPrice(double amount) {
  final formatted = NumberFormat('#,##0', 'vi_VN').format(amount);
  return '${formatted.replaceAll(',', '.')}đ';
}

String formatDeliveryDeadline(DateTime dateTime) {
  return DateFormat('HH \'giờ\' dd/MM/yyyy').format(dateTime);
}
