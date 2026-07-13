import 'package:equatable/equatable.dart';

class ProductFeedbackEligibility extends Equatable {
  final bool canReview;
  final bool hasReviewed;

  const ProductFeedbackEligibility({
    required this.canReview,
    required this.hasReviewed,
  });

  factory ProductFeedbackEligibility.fromJson(Map<String, dynamic> json) {
    return ProductFeedbackEligibility(
      canReview: json['canReview'] == true,
      hasReviewed: json['hasReviewed'] == true,
    );
  }

  @override
  List<Object?> get props => [canReview, hasReviewed];
}
