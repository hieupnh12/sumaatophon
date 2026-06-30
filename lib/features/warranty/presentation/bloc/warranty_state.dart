import 'package:equatable/equatable.dart';
import '../../domain/entities/warranty_item.dart';
import '../../domain/entities/warranty_request.dart';

abstract class WarrantyState extends Equatable {
  const WarrantyState();

  @override
  List<Object?> get props => [];
}

class WarrantyInitial extends WarrantyState {}

class WarrantyLoading extends WarrantyState {}

class WarrantyLoaded extends WarrantyState {
  final List<WarrantyItem> eligibleItems;
  final List<WarrantyRequest> warrantyRequests;

  const WarrantyLoaded({
    required this.eligibleItems,
    required this.warrantyRequests,
  });

  @override
  List<Object?> get props => [eligibleItems, warrantyRequests];
}

class WarrantyError extends WarrantyState {
  final String message;

  const WarrantyError({required this.message});

  @override
  List<Object?> get props => [message];
}

class WarrantySubmitSuccess extends WarrantyState {}
