import '../../domain/entities/warranty_request.dart';

class WarrantyRequestModel extends WarrantyRequest {
  const WarrantyRequestModel({
    required super.requestId,
    required super.type,
    required super.reason,
    required super.status,
    super.adminNote,
    super.appointmentDate,
    required super.createdAt,
    required super.productName,
    required super.image,
  });

  factory WarrantyRequestModel.fromJson(Map<String, dynamic> json) {
    return WarrantyRequestModel(
      requestId: json['requestId'] ?? 0,
      type: json['type'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      adminNote: json['adminNote'],
      appointmentDate: json['appointmentDate'],
      createdAt: json['createdAt'] ?? '',
      productName: json['productName'] ?? '',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'type': type,
      'reason': reason,
      'status': status,
      'adminNote': adminNote,
      'appointmentDate': appointmentDate,
      'createdAt': createdAt,
      'productName': productName,
      'image': image,
    };
  }
}
