import 'package:equatable/equatable.dart';

class WarrantyRequest extends Equatable {
  final int requestId;
  final String type;
  final String reason;
  final String status;
  final String? adminNote;
  final String? appointmentDate;
  final String createdAt;
  final String productName;
  final String image;

  const WarrantyRequest({
    required this.requestId,
    required this.type,
    required this.reason,
    required this.status,
    this.adminNote,
    this.appointmentDate,
    required this.createdAt,
    required this.productName,
    required this.image,
  });

  @override
  List<Object?> get props => [
        requestId,
        type,
        reason,
        status,
        adminNote,
        appointmentDate,
        createdAt,
        productName,
        image,
      ];
}
