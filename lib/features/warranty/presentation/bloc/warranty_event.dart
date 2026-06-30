import 'package:equatable/equatable.dart';

abstract class WarrantyEvent extends Equatable {
  const WarrantyEvent();

  @override
  List<Object?> get props => [];
}

class LoadWarrantyData extends WarrantyEvent {
  final int customerId;
  const LoadWarrantyData(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class SubmitWarrantyRequestEvent extends WarrantyEvent {
  final int customerId;
  final int orderId;
  final String productVersionId;
  final String reason;

  const SubmitWarrantyRequestEvent({
    required this.customerId,
    required this.orderId,
    required this.productVersionId,
    required this.reason,
  });

  @override
  List<Object?> get props => [customerId, orderId, productVersionId, reason];
}
