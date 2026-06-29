import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/warranty_repository.dart';
import 'warranty_event.dart';
import 'warranty_state.dart';

class WarrantyBloc extends Bloc<WarrantyEvent, WarrantyState> {
  final WarrantyRepository repository;

  WarrantyBloc({required this.repository}) : super(WarrantyInitial()) {
    on<LoadWarrantyData>(_onLoadWarrantyData);
    on<SubmitWarrantyRequestEvent>(_onSubmitWarrantyRequest);
  }

  Future<void> _onLoadWarrantyData(
    LoadWarrantyData event,
    Emitter<WarrantyState> emit,
  ) async {
    emit(WarrantyLoading());
    try {
      final eligibleItems = await repository.getEligibleItems(event.customerId);
      final warrantyRequests = await repository.getWarrantyRequests(event.customerId);

      emit(WarrantyLoaded(
        eligibleItems: eligibleItems,
        warrantyRequests: warrantyRequests,
      ));
    } catch (e) {
      emit(WarrantyError(message: e.toString()));
    }
  }

  Future<void> _onSubmitWarrantyRequest(
    SubmitWarrantyRequestEvent event,
    Emitter<WarrantyState> emit,
  ) async {
    emit(WarrantyLoading());
    try {
      await repository.submitWarrantyRequest(
        customerId: event.customerId,
        orderId: event.orderId,
        productVersionId: event.productVersionId,
        reason: event.reason,
      );
      emit(WarrantySubmitSuccess());
      // Tải lại dữ liệu sau khi gửi thành công
      add(LoadWarrantyData(event.customerId));
    } catch (e) {
      emit(WarrantyError(message: e.toString()));
      add(LoadWarrantyData(event.customerId));
    }
  }
}
