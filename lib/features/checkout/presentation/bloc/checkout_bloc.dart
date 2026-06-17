import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// --- EVENTS ---
abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class SelectAddressEvent extends CheckoutEvent {
  final String address;
  const SelectAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class SelectShippingMethodEvent extends CheckoutEvent {
  final String method;
  final double cost;
  const SelectShippingMethodEvent(this.method, this.cost);

  @override
  List<Object?> get props => [method, cost];
}

class SelectPaymentMethodEvent extends CheckoutEvent {
  final String method;
  const SelectPaymentMethodEvent(this.method);

  @override
  List<Object?> get props => [method];
}

class SubmitOrderEvent extends CheckoutEvent {}

// --- STATE ---
class CheckoutState extends Equatable {
  final String selectedAddress;
  final String selectedShippingMethod;
  final double shippingCost;
  final String selectedPaymentMethod;
  final bool isProcessing;
  final bool isSuccess;
  final String? error;

  const CheckoutState({
    this.selectedAddress = '123 Nguyen Van Linh, Quan 7, TP. Ho Chi Minh',
    this.selectedShippingMethod = 'checkout_shipping_standard',
    this.shippingCost = 5.0, // Scale matching the $999 phones
    this.selectedPaymentMethod = 'checkout_payment_cod',
    this.isProcessing = false,
    this.isSuccess = false,
    this.error,
  });

  CheckoutState copyWith({
    String? selectedAddress,
    String? selectedShippingMethod,
    double? shippingCost,
    String? selectedPaymentMethod,
    bool? isProcessing,
    bool? isSuccess,
    String? error,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedShippingMethod: selectedShippingMethod ?? this.selectedShippingMethod,
      shippingCost: shippingCost ?? this.shippingCost,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error, // Can be null
    );
  }

  @override
  List<Object?> get props => [
        selectedAddress,
        selectedShippingMethod,
        shippingCost,
        selectedPaymentMethod,
        isProcessing,
        isSuccess,
        error,
      ];
}

// --- BLOC ---
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc() : super(const CheckoutState()) {
    on<SelectAddressEvent>((event, emit) {
      emit(state.copyWith(selectedAddress: event.address));
    });

    on<SelectShippingMethodEvent>((event, emit) {
      emit(state.copyWith(
        selectedShippingMethod: event.method,
        shippingCost: event.cost,
      ));
    });

    on<SelectPaymentMethodEvent>((event, emit) {
      emit(state.copyWith(selectedPaymentMethod: event.method));
    });

    on<SubmitOrderEvent>((event, emit) async {
      emit(state.copyWith(isProcessing: true, error: null));
      try {
        // Simulate API call for checkout
        await Future.delayed(const Duration(seconds: 2));
        emit(state.copyWith(isProcessing: false, isSuccess: true));
      } catch (e) {
        emit(state.copyWith(isProcessing: false, error: 'checkout_submit_error'));
      }
    });
  }
}
