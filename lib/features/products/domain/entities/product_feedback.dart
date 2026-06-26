import 'package:equatable/equatable.dart';

class ProductFeedback extends Equatable {
  final String id;
  final String customerName;
  final double rate;
  final String content;
  final DateTime? createdAt;

  const ProductFeedback({
    required this.id,
    required this.customerName,
    required this.rate,
    required this.content,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, customerName, rate, content, createdAt];
}
