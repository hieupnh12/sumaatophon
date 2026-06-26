import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CheckoutStep { information, payment }

enum DeliveryType { storePickup, homeDelivery }

enum DeliverySpeed { superFast, standard }

// --- EVENTS ---
abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCheckoutEvent extends CheckoutEvent {
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? memberCode;

  const InitializeCheckoutEvent({
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.memberCode,
  });

  @override
  List<Object?> get props => [customerName, customerPhone, customerEmail, memberCode];
}

class SetCheckoutStepEvent extends CheckoutEvent {
  final CheckoutStep step;

  const SetCheckoutStepEvent(this.step);

  @override
  List<Object?> get props => [step];
}

class SetDeliveryTypeEvent extends CheckoutEvent {
  final DeliveryType type;

  const SetDeliveryTypeEvent(this.type);

  @override
  List<Object?> get props => [type];
}

class UpdateCustomerEmailEvent extends CheckoutEvent {
  final String email;

  const UpdateCustomerEmailEvent(this.email);

  @override
  List<Object?> get props => [email];
}

class UpdateRecipientNameEvent extends CheckoutEvent {
  final String name;

  const UpdateRecipientNameEvent(this.name);

  @override
  List<Object?> get props => [name];
}

class UpdateRecipientPhoneEvent extends CheckoutEvent {
  final String phone;

  const UpdateRecipientPhoneEvent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class UpdateProvinceEvent extends CheckoutEvent {
  final String province;

  const UpdateProvinceEvent(this.province);

  @override
  List<Object?> get props => [province];
}

class UpdateDistrictEvent extends CheckoutEvent {
  final String? district;

  const UpdateDistrictEvent(this.district);

  @override
  List<Object?> get props => [district];
}

class UpdateWardEvent extends CheckoutEvent {
  final String? ward;

  const UpdateWardEvent(this.ward);

  @override
  List<Object?> get props => [ward];
}

class UpdateHomeAddressEvent extends CheckoutEvent {
  final String address;

  const UpdateHomeAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class UpdateStoreEvent extends CheckoutEvent {
  final String? store;

  const UpdateStoreEvent(this.store);

  @override
  List<Object?> get props => [store];
}

class UpdateNotesEvent extends CheckoutEvent {
  final String notes;

  const UpdateNotesEvent(this.notes);

  @override
  List<Object?> get props => [notes];
}

class ToggleSaveAddressEvent extends CheckoutEvent {
  final bool save;

  const ToggleSaveAddressEvent(this.save);

  @override
  List<Object?> get props => [save];
}

class SelectDeliverySpeedEvent extends CheckoutEvent {
  final DeliverySpeed speed;

  const SelectDeliverySpeedEvent(this.speed);

  @override
  List<Object?> get props => [speed];
}

class SetCompanyInvoiceEvent extends CheckoutEvent {
  final bool wantsInvoice;

  const SetCompanyInvoiceEvent(this.wantsInvoice);

  @override
  List<Object?> get props => [wantsInvoice];
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
  final CheckoutStep step;
  final DeliveryType deliveryType;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String memberCode;
  final String recipientName;
  final String recipientPhone;
  final String province;
  final String? district;
  final String? ward;
  final String homeAddress;
  final String? selectedStore;
  final String notes;
  final bool saveToAddressBook;
  final DeliverySpeed deliverySpeed;
  final bool? wantsCompanyInvoice;
  final String selectedPaymentMethod;
  final bool isProcessing;
  final bool isSuccess;
  final String? error;

  const CheckoutState({
    this.step = CheckoutStep.information,
    this.deliveryType = DeliveryType.storePickup,
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.memberCode = 'NULL',
    this.recipientName = '',
    this.recipientPhone = '',
    this.province = 'Đà Nẵng',
    this.district,
    this.ward,
    this.homeAddress = '',
    this.selectedStore,
    this.notes = '',
    this.saveToAddressBook = false,
    this.deliverySpeed = DeliverySpeed.standard,
    this.wantsCompanyInvoice,
    this.selectedPaymentMethod = 'checkout_payment_cod',
    this.isProcessing = false,
    this.isSuccess = false,
    this.error,
  });

  CheckoutState copyWith({
    CheckoutStep? step,
    DeliveryType? deliveryType,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? memberCode,
    String? recipientName,
    String? recipientPhone,
    String? province,
    String? district,
    bool clearDistrict = false,
    String? ward,
    bool clearWard = false,
    String? homeAddress,
    String? selectedStore,
    bool clearStore = false,
    String? notes,
    bool? saveToAddressBook,
    DeliverySpeed? deliverySpeed,
    bool? wantsCompanyInvoice,
    bool clearCompanyInvoice = false,
    String? selectedPaymentMethod,
    bool? isProcessing,
    bool? isSuccess,
    String? error,
  }) {
    return CheckoutState(
      step: step ?? this.step,
      deliveryType: deliveryType ?? this.deliveryType,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      memberCode: memberCode ?? this.memberCode,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      province: province ?? this.province,
      district: clearDistrict ? null : (district ?? this.district),
      ward: clearWard ? null : (ward ?? this.ward),
      homeAddress: homeAddress ?? this.homeAddress,
      selectedStore: clearStore ? null : (selectedStore ?? this.selectedStore),
      notes: notes ?? this.notes,
      saveToAddressBook: saveToAddressBook ?? this.saveToAddressBook,
      deliverySpeed: deliverySpeed ?? this.deliverySpeed,
      wantsCompanyInvoice:
          clearCompanyInvoice ? null : (wantsCompanyInvoice ?? this.wantsCompanyInvoice),
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        step,
        deliveryType,
        customerName,
        customerPhone,
        customerEmail,
        memberCode,
        recipientName,
        recipientPhone,
        province,
        district,
        ward,
        homeAddress,
        selectedStore,
        notes,
        saveToAddressBook,
        deliverySpeed,
        wantsCompanyInvoice,
        selectedPaymentMethod,
        isProcessing,
        isSuccess,
        error,
      ];
}

// --- BLOC ---
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc() : super(const CheckoutState()) {
    on<InitializeCheckoutEvent>(_onInitialize);
    on<SetCheckoutStepEvent>((event, emit) => emit(state.copyWith(step: event.step)));
    on<SetDeliveryTypeEvent>((event, emit) {
      emit(state.copyWith(
        deliveryType: event.type,
        clearDistrict: true,
        clearWard: true,
        clearStore: true,
      ));
    });
    on<UpdateCustomerEmailEvent>((event, emit) => emit(state.copyWith(customerEmail: event.email)));
    on<UpdateRecipientNameEvent>((event, emit) => emit(state.copyWith(recipientName: event.name)));
    on<UpdateRecipientPhoneEvent>((event, emit) => emit(state.copyWith(recipientPhone: event.phone)));
    on<UpdateProvinceEvent>((event, emit) {
      emit(state.copyWith(
        province: event.province,
        clearDistrict: true,
        clearWard: true,
        clearStore: true,
      ));
    });
    on<UpdateDistrictEvent>((event, emit) {
      emit(state.copyWith(district: event.district, clearWard: true, clearStore: true));
    });
    on<UpdateWardEvent>((event, emit) => emit(state.copyWith(ward: event.ward)));
    on<UpdateHomeAddressEvent>((event, emit) => emit(state.copyWith(homeAddress: event.address)));
    on<UpdateStoreEvent>((event, emit) => emit(state.copyWith(selectedStore: event.store)));
    on<UpdateNotesEvent>((event, emit) => emit(state.copyWith(notes: event.notes)));
    on<ToggleSaveAddressEvent>((event, emit) => emit(state.copyWith(saveToAddressBook: event.save)));
    on<SelectDeliverySpeedEvent>((event, emit) => emit(state.copyWith(deliverySpeed: event.speed)));
    on<SetCompanyInvoiceEvent>((event, emit) => emit(state.copyWith(wantsCompanyInvoice: event.wantsInvoice)));
    on<SelectPaymentMethodEvent>((event, emit) => emit(state.copyWith(selectedPaymentMethod: event.method)));
    on<SubmitOrderEvent>(_onSubmitOrder);
  }

  void _onInitialize(InitializeCheckoutEvent event, Emitter<CheckoutState> emit) {
    emit(state.copyWith(
      customerName: event.customerName ?? state.customerName,
      customerPhone: event.customerPhone ?? state.customerPhone,
      customerEmail: event.customerEmail ?? state.customerEmail,
      memberCode: event.memberCode ?? state.memberCode,
      recipientName: event.customerName ?? state.recipientName,
      recipientPhone: event.customerPhone ?? state.recipientPhone,
    ));
  }

  Future<void> _onSubmitOrder(SubmitOrderEvent event, Emitter<CheckoutState> emit) async {
    emit(state.copyWith(isProcessing: true, error: null));
    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(isProcessing: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isProcessing: false, error: 'checkout_submit_error'));
    }
  }
}
