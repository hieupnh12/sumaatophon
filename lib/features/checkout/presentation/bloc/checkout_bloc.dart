import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../address/domain/entities/address.dart';
import '../../data/datasources/checkout_remote_datasource.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../widgets/checkout_location_data.dart';

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

class SetReceiptEmailConfirmedEvent extends CheckoutEvent {
  final bool confirmed;

  const SetReceiptEmailConfirmedEvent(this.confirmed);

  @override
  List<Object?> get props => [confirmed];
}

class SelectPaymentMethodEvent extends CheckoutEvent {
  final String method;

  const SelectPaymentMethodEvent(this.method);

  @override
  List<Object?> get props => [method];
}

class ApplyAddressesFromBookEvent extends CheckoutEvent {
  final List<Address> addresses;

  const ApplyAddressesFromBookEvent(this.addresses);

  @override
  List<Object?> get props => [addresses];
}

class SelectSavedAddressEvent extends CheckoutEvent {
  final Address address;

  const SelectSavedAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class EnableManualAddressEvent extends CheckoutEvent {}

class ApplyDefaultPickupStoreEvent extends CheckoutEvent {
  const ApplyDefaultPickupStoreEvent();
}

class ContinueToPaymentEvent extends CheckoutEvent {
  final bool hasSelectedCartItems;

  const ContinueToPaymentEvent({this.hasSelectedCartItems = true});

  @override
  List<Object?> get props => [hasSelectedCartItems];
}

class ClearCheckoutErrorEvent extends CheckoutEvent {}

class ClearCheckoutSuccessEvent extends CheckoutEvent {}

class SubmitOrderEvent extends CheckoutEvent {
  final String customerId;
  final List<CheckoutOrderItemPayload> items;
  final double subtotal;
  final double discount;

  const SubmitOrderEvent({
    required this.customerId,
    required this.items,
    required this.subtotal,
    required this.discount,
  });

  @override
  List<Object?> get props => [customerId, items, subtotal, discount];
}

class ClearPayOsCheckoutEvent extends CheckoutEvent {
  const ClearPayOsCheckoutEvent();
}

class CompletePayOsPaymentEvent extends CheckoutEvent {
  final bool success;
  final String orderId;

  const CompletePayOsPaymentEvent({required this.success, required this.orderId});

  @override
  List<Object?> get props => [success, orderId];
}

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
  final bool receiptEmailConfirmed;
  final String? selectedAddressId;
  final bool isManualAddressEntry;
  final String selectedPaymentMethod;
  final bool isProcessing;
  final bool isSuccess;
  final String? error;
  final String? payOsCheckoutUrl;
  final String? payOsQrCode;
  final int? payOsAmount;
  final String? pendingOrderId;

  const CheckoutState({
    this.step = CheckoutStep.information,
    this.deliveryType = DeliveryType.storePickup,
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.memberCode = 'NULL',
    this.recipientName = '',
    this.recipientPhone = '',
    this.province = CheckoutLocationData.defaultProvince,
    this.district = CheckoutLocationData.defaultDistrict,
    this.ward,
    this.homeAddress = '',
    this.selectedStore = CheckoutLocationData.defaultStoreLabel,
    this.notes = '',
    this.saveToAddressBook = false,
    this.deliverySpeed = DeliverySpeed.standard,
    this.wantsCompanyInvoice,
    this.receiptEmailConfirmed = false,
    this.selectedAddressId,
    this.isManualAddressEntry = false,
    this.selectedPaymentMethod = 'checkout_payment_store',
    this.isProcessing = false,
    this.isSuccess = false,
    this.error,
    this.payOsCheckoutUrl,
    this.payOsQrCode,
    this.payOsAmount,
    this.pendingOrderId,
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
    bool? receiptEmailConfirmed,
    bool clearReceiptConfirm = false,
    String? selectedAddressId,
    bool clearSelectedAddress = false,
    bool? isManualAddressEntry,
    String? selectedPaymentMethod,
    bool? isProcessing,
    bool? isSuccess,
    String? error,
    String? payOsCheckoutUrl,
    String? payOsQrCode,
    int? payOsAmount,
    String? pendingOrderId,
    bool clearPayOsCheckout = false,
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
      receiptEmailConfirmed:
          clearReceiptConfirm ? false : (receiptEmailConfirmed ?? this.receiptEmailConfirmed),
      selectedAddressId: clearSelectedAddress ? null : (selectedAddressId ?? this.selectedAddressId),
      isManualAddressEntry: isManualAddressEntry ?? this.isManualAddressEntry,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      isProcessing: isProcessing ?? this.isProcessing,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      payOsCheckoutUrl: clearPayOsCheckout ? null : (payOsCheckoutUrl ?? this.payOsCheckoutUrl),
      payOsQrCode: clearPayOsCheckout ? null : (payOsQrCode ?? this.payOsQrCode),
      payOsAmount: clearPayOsCheckout ? null : (payOsAmount ?? this.payOsAmount),
      pendingOrderId: clearPayOsCheckout ? null : (pendingOrderId ?? this.pendingOrderId),
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
        receiptEmailConfirmed,
        selectedAddressId,
        isManualAddressEntry,
        selectedPaymentMethod,
        isProcessing,
        isSuccess,
        error,
        payOsCheckoutUrl,
        payOsQrCode,
        payOsAmount,
        pendingOrderId,
      ];
}

// --- BLOC ---
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final CheckoutRemoteDataSource checkoutDataSource;
  final PaymentRemoteDataSource? paymentDataSource;

  CheckoutBloc({
    required this.checkoutDataSource,
    this.paymentDataSource,
  }) : super(const CheckoutState()) {
    on<InitializeCheckoutEvent>(_onInitialize);
    on<SetCheckoutStepEvent>(_onSetCheckoutStep);
    on<SetDeliveryTypeEvent>((event, emit) {
      final paymentMethod = _defaultPaymentMethod(event.type);
      final resetToInfo = state.step == CheckoutStep.payment;
      if (event.type == DeliveryType.storePickup) {
        emit(state.copyWith(
          step: resetToInfo ? CheckoutStep.information : state.step,
          deliveryType: event.type,
          selectedPaymentMethod: paymentMethod,
          province: CheckoutLocationData.defaultProvince,
          district: CheckoutLocationData.defaultDistrict,
          selectedStore: CheckoutLocationData.defaultStoreLabel,
          clearWard: true,
          clearCompanyInvoice: true,
          clearReceiptConfirm: true,
        ));
      } else {
        emit(state.copyWith(
          step: resetToInfo ? CheckoutStep.information : state.step,
          deliveryType: event.type,
          selectedPaymentMethod: paymentMethod,
          clearStore: true,
          isManualAddressEntry: false,
          clearCompanyInvoice: true,
          clearReceiptConfirm: true,
        ));
      }
    });
    on<UpdateCustomerEmailEvent>((event, emit) => emit(state.copyWith(
          customerEmail: event.email,
          receiptEmailConfirmed: false,
        )));
    on<UpdateRecipientNameEvent>((event, emit) => _emitManualFieldUpdate(emit, recipientName: event.name));
    on<UpdateRecipientPhoneEvent>((event, emit) => _emitManualFieldUpdate(emit, recipientPhone: event.phone));
    on<UpdateProvinceEvent>((event, emit) {
      if (state.deliveryType == DeliveryType.storePickup) {
        emit(state.copyWith(
          province: event.province,
          clearDistrict: true,
          clearWard: true,
          clearStore: true,
        ));
        return;
      }
      _emitManualFieldUpdate(
        emit,
        province: event.province,
        clearWard: true,
      );
    });
    on<UpdateDistrictEvent>((event, emit) {
      emit(state.copyWith(district: event.district, clearWard: true, clearStore: true));
    });
    on<UpdateWardEvent>((event, emit) => _emitManualFieldUpdate(emit, ward: event.ward));
    on<UpdateHomeAddressEvent>((event, emit) => _emitManualFieldUpdate(emit, homeAddress: event.address));
    on<UpdateStoreEvent>((event, emit) => emit(state.copyWith(selectedStore: event.store)));
    on<UpdateNotesEvent>((event, emit) => emit(state.copyWith(notes: event.notes)));
    on<ToggleSaveAddressEvent>((event, emit) => emit(state.copyWith(saveToAddressBook: event.save)));
    on<SelectDeliverySpeedEvent>((event, emit) => emit(state.copyWith(deliverySpeed: event.speed)));
    on<SetCompanyInvoiceEvent>((event, emit) {
      if (event.wantsInvoice) {
        emit(state.copyWith(
          wantsCompanyInvoice: true,
          receiptEmailConfirmed: false,
        ));
      } else {
        emit(state.copyWith(
          wantsCompanyInvoice: false,
          clearReceiptConfirm: true,
        ));
      }
    });
    on<SetReceiptEmailConfirmedEvent>(
      (event, emit) => emit(state.copyWith(receiptEmailConfirmed: event.confirmed)),
    );
    on<SelectPaymentMethodEvent>(
      (event, emit) => emit(state.copyWith(selectedPaymentMethod: event.method)),
    );
    on<ApplyDefaultPickupStoreEvent>((event, emit) => _applyDefaultPickupStore(emit));
    on<ApplyAddressesFromBookEvent>(_onApplyAddressesFromBook);
    on<SelectSavedAddressEvent>(_onSelectSavedAddress);
    on<EnableManualAddressEvent>((event, emit) {
      emit(state.copyWith(clearSelectedAddress: true, isManualAddressEntry: true));
    });
    on<ContinueToPaymentEvent>(_onContinueToPayment);
    on<ClearCheckoutErrorEvent>((event, emit) => emit(state.copyWith(error: null)));
    on<ClearCheckoutSuccessEvent>((event, emit) => emit(state.copyWith(isSuccess: false)));
    on<ClearPayOsCheckoutEvent>((event, emit) => emit(state.copyWith(clearPayOsCheckout: true)));
    on<CompletePayOsPaymentEvent>(_onCompletePayOsPayment);
    on<SubmitOrderEvent>(_onSubmitOrder);
  }

  static double shippingFeeFor(CheckoutState state) {
    if (state.deliveryType != DeliveryType.homeDelivery) return 0;
    return state.deliverySpeed == DeliverySpeed.superFast ? 50000 : 0;
  }

  String _buildAddressSummary() {
    if (state.deliveryType == DeliveryType.storePickup) {
      return [
        state.selectedStore,
        state.district,
        state.province,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
    }

    return [
      state.homeAddress,
      state.ward,
      state.province,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
  }

  String _shippingMethodKey() {
    return state.deliverySpeed == DeliverySpeed.superFast
        ? 'checkout_delivery_super_fast'
        : 'checkout_delivery_standard';
  }

  static const _storePickupPaymentMethods = [
    'checkout_payment_store',
    'checkout_payment_qr',
    'checkout_payment_vnpay',
  ];

  static const _homeDeliveryPaymentMethods = [
    'checkout_payment_cod',
    'checkout_payment_qr',
    'checkout_payment_vnpay',
  ];

  static String _defaultPaymentMethod(DeliveryType type) {
    return type == DeliveryType.storePickup
        ? 'checkout_payment_store'
        : 'checkout_payment_cod';
  }

  static List<String> _validPaymentMethods(DeliveryType type) {
    return type == DeliveryType.storePickup
        ? _storePickupPaymentMethods
        : _homeDeliveryPaymentMethods;
  }

  bool _isPaymentMethodValidForDeliveryType() {
    return _validPaymentMethods(state.deliveryType).contains(state.selectedPaymentMethod);
  }

  String? _validateInformationStep() {
    if (state.deliveryType == DeliveryType.storePickup) {
      if (state.district == null || state.district!.trim().isEmpty) {
        return 'checkout_error_district';
      }
      if (state.selectedStore == null || state.selectedStore!.trim().isEmpty) {
        return 'checkout_error_store';
      }
      return null;
    }

    // Giao tận nơi: bắt buộc có địa chỉ đã lưu hoặc nhập tay đầy đủ.
    if (state.selectedAddressId == null || state.selectedAddressId!.isEmpty) {
      if (!state.isManualAddressEntry) {
        return 'checkout_error_address';
      }
      if (state.province.trim().isEmpty) {
        return 'checkout_error_address';
      }
      if (state.ward == null || state.ward!.trim().isEmpty) {
        return 'checkout_error_address';
      }
      if (state.homeAddress.trim().isEmpty) {
        return 'checkout_error_address';
      }
    }

    final name =
        state.recipientName.trim().isNotEmpty ? state.recipientName : state.customerName;
    final phone =
        state.recipientPhone.trim().isNotEmpty ? state.recipientPhone : state.customerPhone;
    if (name.trim().isEmpty) return 'checkout_error_recipient_name';
    if (phone.trim().isEmpty) return 'checkout_error_recipient_phone';

    if (state.wantsCompanyInvoice == null) {
      return 'checkout_error_receipt_choice';
    }
    if (state.wantsCompanyInvoice == true) {
      if (!_isValidEmail(state.customerEmail)) {
        return 'checkout_error_receipt_email';
      }
      if (!state.receiptEmailConfirmed) {
        return 'checkout_error_receipt_confirm';
      }
    }

    return null;
  }

  void _onSetCheckoutStep(SetCheckoutStepEvent event, Emitter<CheckoutState> emit) {
    if (event.step == CheckoutStep.payment) {
      _advanceToPaymentStep(emit, hasSelectedCartItems: true);
      return;
    }
    emit(state.copyWith(step: event.step, error: null));
  }

  void _applyDefaultPickupStore(Emitter<CheckoutState> emit) {
    if (state.deliveryType != DeliveryType.storePickup) return;
    emit(state.copyWith(
      province: CheckoutLocationData.defaultProvince,
      district: CheckoutLocationData.defaultDistrict,
      selectedStore: CheckoutLocationData.defaultStoreLabel,
    ));
  }

  void _onContinueToPayment(ContinueToPaymentEvent event, Emitter<CheckoutState> emit) {
    _advanceToPaymentStep(emit, hasSelectedCartItems: event.hasSelectedCartItems);
  }

  void _advanceToPaymentStep(
    Emitter<CheckoutState> emit, {
    required bool hasSelectedCartItems,
  }) {
    if (!hasSelectedCartItems) {
      emit(state.copyWith(error: 'cart_select_items_to_checkout'));
      return;
    }

    final validationError = _validateInformationStep();
    if (validationError != null) {
      emit(state.copyWith(error: validationError, step: CheckoutStep.information));
      return;
    }

    final paymentMethod = _isPaymentMethodValidForDeliveryType()
        ? state.selectedPaymentMethod
        : _defaultPaymentMethod(state.deliveryType);

    emit(state.copyWith(
      step: CheckoutStep.payment,
      selectedPaymentMethod: paymentMethod,
      error: null,
    ));
  }

  void _emitManualFieldUpdate(
    Emitter<CheckoutState> emit, {
    String? recipientName,
    String? recipientPhone,
    String? province,
    String? ward,
    bool clearWard = false,
    String? homeAddress,
  }) {
    if (state.deliveryType != DeliveryType.homeDelivery) {
      emit(state.copyWith(
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        province: province,
        ward: ward,
        clearWard: clearWard,
        homeAddress: homeAddress,
      ));
      return;
    }

    final fromSavedAddress = state.selectedAddressId != null;
    emit(state.copyWith(
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      province: province,
      ward: ward,
      clearWard: clearWard,
      homeAddress: homeAddress,
      clearSelectedAddress: fromSavedAddress,
      isManualAddressEntry: fromSavedAddress ? true : state.isManualAddressEntry,
    ));
  }

  CheckoutState _stateFromAddress(Address address) {
    return state.copyWith(
      selectedAddressId: address.id,
      isManualAddressEntry: false,
      recipientName: address.receiverName?.isNotEmpty == true ? address.receiverName! : state.recipientName,
      recipientPhone: address.receiverPhone?.isNotEmpty == true ? address.receiverPhone! : state.recipientPhone,
      province: address.province,
      ward: address.ward,
      homeAddress: address.street,
    );
  }

  void _onApplyAddressesFromBook(ApplyAddressesFromBookEvent event, Emitter<CheckoutState> emit) {
    if (state.deliveryType != DeliveryType.homeDelivery) return;

    if (event.addresses.isEmpty) {
      emit(state.copyWith(clearSelectedAddress: true, isManualAddressEntry: false));
      return;
    }

    Address? selected;
    if (state.selectedAddressId != null) {
      for (final address in event.addresses) {
        if (address.id == state.selectedAddressId) {
          selected = address;
          break;
        }
      }
    }

    selected ??= () {
      final defaults = event.addresses.where((a) => a.isDefault).toList();
      return defaults.isNotEmpty ? defaults.first : event.addresses.first;
    }();

    emit(_stateFromAddress(selected));
  }

  void _onSelectSavedAddress(SelectSavedAddressEvent event, Emitter<CheckoutState> emit) {
    emit(_stateFromAddress(event.address));
  }

  void _onInitialize(InitializeCheckoutEvent event, Emitter<CheckoutState> emit) {
    emit(state.copyWith(
      customerName: event.customerName ?? state.customerName,
      customerPhone: event.customerPhone ?? state.customerPhone,
      customerEmail: event.customerEmail ?? state.customerEmail,
      memberCode: event.memberCode ?? state.memberCode,
      recipientName: event.customerName ?? state.recipientName,
      recipientPhone: event.customerPhone ?? state.recipientPhone,
      isSuccess: false,
      isProcessing: false,
      error: null,
    ));
  }

  String _buildOrderNote() {
    final parts = <String>[];
    if (state.notes.trim().isNotEmpty) {
      parts.add(state.notes.trim());
    }
    return parts.join(' | ');
  }

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  String _mapCheckoutError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('PAYOS_NOT_CONFIGURED') ||
        message.contains('PayOS chưa được cấu hình')) {
      return 'checkout_payos_not_configured';
    }
    if (message.contains('PayOS') || message.contains('payos')) {
      return 'checkout_payos_error';
    }
    if (message.contains('stock') || message.contains('Insufficient')) {
      return 'checkout_submit_stock_error';
    }
    return 'checkout_submit_error';
  }

  Future<void> _onSubmitOrder(SubmitOrderEvent event, Emitter<CheckoutState> emit) async {
    if (state.selectedPaymentMethod.isEmpty) {
      emit(state.copyWith(error: 'checkout_error_payment_method'));
      return;
    }

    if (state.selectedPaymentMethod == 'checkout_payment_vnpay') {
      emit(state.copyWith(error: 'checkout_payment_vnpay_unavailable'));
      return;
    }

    if (event.items.isEmpty) {
      emit(state.copyWith(error: 'cart_select_items_to_checkout'));
      return;
    }

    emit(state.copyWith(isProcessing: true, error: null, clearPayOsCheckout: true));

    try {
      final shippingCost = shippingFeeFor(state);
      final total = event.subtotal - event.discount + shippingCost;

      final orderResult = await checkoutDataSource.createOrder(
        CreateOrderPayload(
          customerId: event.customerId,
          items: event.items,
          paymentMethod: state.selectedPaymentMethod,
          deliveryType: state.deliveryType == DeliveryType.storePickup
              ? 'storePickup'
              : 'homeDelivery',
          address: _buildAddressSummary(),
          shippingMethod: _shippingMethodKey(),
          shippingCost: shippingCost,
          subtotal: event.subtotal,
          discount: event.discount,
          total: total,
          note: _buildOrderNote(),
          wantsEmailReceipt: state.wantsCompanyInvoice == true,
          receiptEmail: state.wantsCompanyInvoice == true ? state.customerEmail.trim() : null,
        ),
      );

      if (orderResult.requiresPayOs) {
        if (paymentDataSource == null) {
          throw Exception('PAYOS_NOT_CONFIGURED');
        }

        final payOsResult = await paymentDataSource!.createPayOsCheckout(
          orderId: orderResult.orderId,
          amount: total.round(),
          description: 'DH ${orderResult.orderId}',
        );

        if (payOsResult.checkoutUrl.isEmpty) {
          throw Exception('PayOS checkout URL empty');
        }

        emit(state.copyWith(
          isProcessing: false,
          payOsCheckoutUrl: payOsResult.checkoutUrl,
          payOsQrCode: payOsResult.qrCode,
          payOsAmount: total.round(),
          pendingOrderId: orderResult.orderId,
        ));
        return;
      }

      emit(state.copyWith(isProcessing: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isProcessing: false, error: _mapCheckoutError(e)));
    }
  }

  Future<void> _onCompletePayOsPayment(
    CompletePayOsPaymentEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(clearPayOsCheckout: true, isProcessing: true, error: null));

    try {
      if (!event.success) {
        await paymentDataSource?.cancelPayOsPayment(event.orderId);
        emit(state.copyWith(isProcessing: false, error: 'checkout_payment_cancelled'));
        return;
      }

      PayOsPaymentStatus? status;
      for (var attempt = 0; attempt < 5; attempt++) {
        status = attempt == 0
            ? await paymentDataSource?.confirmPayOsPayment(event.orderId)
            : await paymentDataSource?.getPayOsStatus(event.orderId);
        if (status?.isPaid == true) break;
        await Future.delayed(const Duration(milliseconds: 800));
      }

      if (status?.isPaid == true) {
        emit(state.copyWith(isProcessing: false, isSuccess: true));
        return;
      }

      emit(state.copyWith(isProcessing: false, error: 'checkout_payos_pending'));
    } catch (_) {
      emit(state.copyWith(isProcessing: false, error: 'checkout_submit_error'));
    }
  }
}
