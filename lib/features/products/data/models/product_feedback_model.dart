import '../../domain/entities/product_feedback.dart';

class ProductFeedbackModel {
  final String id;
  final String customerName;
  final double rate;
  final String content;
  final DateTime? createdAt;

  const ProductFeedbackModel({
    required this.id,
    required this.customerName,
    required this.rate,
    required this.content,
    this.createdAt,
  });

  factory ProductFeedbackModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final rawDate = json['createdAt'];
    if (rawDate != null) {
      createdAt = DateTime.tryParse(rawDate.toString());
    }

    return ProductFeedbackModel(
      id: json['id'].toString(),
      customerName: json['customerName'] as String? ?? '',
      rate: _toDouble(json['rate']),
      content: json['content'] as String? ?? '',
      createdAt: createdAt,
    );
  }

  ProductFeedback toEntity() {
    return ProductFeedback(
      id: id,
      customerName: customerName,
      rate: rate,
      content: content,
      createdAt: createdAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
