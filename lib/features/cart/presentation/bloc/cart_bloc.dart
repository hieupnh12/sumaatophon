import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_version.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../data/datasources/cart_remote_datasource.dart';

// --- EVENTS ---
abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class SyncCartCustomerEvent extends CartEvent {
  final String? customerId;

  const SyncCartCustomerEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class LoadCartEvent extends CartEvent {}

class AddToCartEvent extends CartEvent {
  final Product product;
  final ProductVersion version;

  const AddToCartEvent(this.product, this.version);

  @override
  List<Object?> get props => [product, version];
}

class RemoveFromCartEvent extends CartEvent {
  final String productVersionId;

  const RemoveFromCartEvent(this.productVersionId);

  @override
  List<Object?> get props => [productVersionId];
}

class UpdateQuantityEvent extends CartEvent {
  final String productVersionId;
  final int quantity;

  const UpdateQuantityEvent(this.productVersionId, this.quantity);

  @override
  List<Object?> get props => [productVersionId, quantity];
}

class ClearCartEvent extends CartEvent {}

class ApplyPromoCodeEvent extends CartEvent {
  final String code;
  const ApplyPromoCodeEvent(this.code);

  @override
  List<Object?> get props => [code];
}

class RemovePromoCodeEvent extends CartEvent {}

class ClearCartMessageEvent extends CartEvent {}

class ClearCartAddedEvent extends CartEvent {}

class ToggleCartItemSelectionEvent extends CartEvent {
  final String productVersionId;

  const ToggleCartItemSelectionEvent(this.productVersionId);

  @override
  List<Object?> get props => [productVersionId];
}

class ToggleSelectAllCartItemsEvent extends CartEvent {}

// --- STATE ---
class CartState extends Equatable {
  final List<CartItem> items;
  final Set<String> selectedVersionIds;
  final String? promoCode;
  final double discountPercent;
  final String? promoError;
  final String? cartMessage;
  final String? addedProductName;
  final bool isLoading;
  final String? customerId;

  const CartState({
    this.items = const [],
    this.selectedVersionIds = const {},
    this.promoCode,
    this.discountPercent = 0.0,
    this.promoError,
    this.cartMessage,
    this.addedProductName,
    this.isLoading = false,
    this.customerId,
  });

  int get totalItems => items.fold(0, (total, item) => total + item.quantity);

  List<CartItem> get selectedItems =>
      items.where((item) => selectedVersionIds.contains(item.version.id)).toList();

  int get selectedTotalItems =>
      selectedItems.fold(0, (total, item) => total + item.quantity);

  double get subtotal =>
      items.fold(0, (total, item) => total + (item.unitPrice * item.quantity));

  double get selectedSubtotal =>
      selectedItems.fold(0, (total, item) => total + (item.unitPrice * item.quantity));

  double get discountAmount => subtotal * discountPercent;

  double get selectedDiscountAmount => selectedSubtotal * discountPercent;

  double get finalPrice => subtotal - discountAmount;

  double get selectedFinalPrice => selectedSubtotal - selectedDiscountAmount;

  bool get isAllSelected =>
      items.isNotEmpty && items.every((item) => selectedVersionIds.contains(item.version.id));

  bool get hasSelection => selectedVersionIds.isNotEmpty;

  CartState copyWith({
    List<CartItem>? items,
    Set<String>? selectedVersionIds,
    String? promoCode,
    double? discountPercent,
    String? promoError,
    String? cartMessage,
    String? addedProductName,
    bool? isLoading,
    String? customerId,
    bool clearPromoError = false,
    bool clearPromoCode = false,
    bool clearCartMessage = false,
    bool clearAddedProductName = false,
    bool clearCustomerId = false,
  }) {
    return CartState(
      items: items ?? this.items,
      selectedVersionIds: selectedVersionIds ?? this.selectedVersionIds,
      promoCode: clearPromoCode ? null : (promoCode ?? this.promoCode),
      discountPercent: discountPercent ?? this.discountPercent,
      promoError: clearPromoError ? null : (promoError ?? this.promoError),
      cartMessage: clearCartMessage ? null : (cartMessage ?? this.cartMessage),
      addedProductName: clearAddedProductName ? null : (addedProductName ?? this.addedProductName),
      isLoading: isLoading ?? this.isLoading,
      customerId: clearCustomerId ? null : (customerId ?? this.customerId),
    );
  }

  @override
  List<Object?> get props => [
        items,
        selectedVersionIds,
        promoCode,
        discountPercent,
        promoError,
        cartMessage,
        addedProductName,
        isLoading,
        customerId,
      ];
}

Set<String> _allVersionIds(List<CartItem> items) =>
    items.map((item) => item.version.id).toSet();

Set<String> _pruneSelection(Set<String> selected, List<CartItem> items) {
  final validIds = _allVersionIds(items);
  return selected.where(validIds.contains).toSet();
}

// --- BLOC ---
class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository repository;

  CartBloc({required this.repository}) : super(const CartState()) {
    on<SyncCartCustomerEvent>(_onSyncCustomer);
    on<LoadCartEvent>(_onLoadCart);
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<ApplyPromoCodeEvent>(_onApplyPromoCode);
    on<RemovePromoCodeEvent>(_onRemovePromoCode);
    on<ClearCartMessageEvent>((event, emit) => emit(state.copyWith(clearCartMessage: true)));
    on<ClearCartAddedEvent>((event, emit) => emit(state.copyWith(clearAddedProductName: true)));
    on<ToggleCartItemSelectionEvent>(_onToggleItemSelection);
    on<ToggleSelectAllCartItemsEvent>(_onToggleSelectAll);
  }

  void _onToggleItemSelection(ToggleCartItemSelectionEvent event, Emitter<CartState> emit) {
    final next = Set<String>.from(state.selectedVersionIds);
    if (next.contains(event.productVersionId)) {
      next.remove(event.productVersionId);
    } else {
      next.add(event.productVersionId);
    }
    emit(state.copyWith(selectedVersionIds: next));
  }

  void _onToggleSelectAll(ToggleSelectAllCartItemsEvent event, Emitter<CartState> emit) {
    if (state.isAllSelected) {
      emit(state.copyWith(selectedVersionIds: {}));
    } else {
      emit(state.copyWith(selectedVersionIds: _allVersionIds(state.items)));
    }
  }

  Future<void> _onSyncCustomer(SyncCartCustomerEvent event, Emitter<CartState> emit) async {
    if (event.customerId == null) {
      emit(const CartState());
      return;
    }

    emit(state.copyWith(customerId: event.customerId, isLoading: true, items: const []));

    try {
      final items = await repository.getItems(event.customerId!);
      emit(state.copyWith(
        items: items,
        isLoading: false,
        customerId: event.customerId,
        selectedVersionIds: _allVersionIds(items),
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, customerId: event.customerId, cartMessage: _cartErrorKey(e)));
    }
  }

  String? get _customerId => state.customerId;

  Future<void> _onLoadCart(LoadCartEvent event, Emitter<CartState> emit) async {
    final customerId = _customerId;
    if (customerId == null) {
      emit(state.copyWith(items: const [], isLoading: false));
      return;
    }

    try {
      emit(state.copyWith(isLoading: true));
      final items = await repository.getItems(customerId);
      emit(state.copyWith(
        items: items,
        isLoading: false,
        selectedVersionIds: _allVersionIds(items),
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, cartMessage: _cartErrorKey(e)));
    }
  }

  String _cartErrorKey(Object error) {
    if (error is CartApiException && error.code == 'cart_api_not_found') {
      return 'cart_api_unavailable';
    }
    return 'cart_save_error';
  }

  Future<void> _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) async {
    final customerId = _customerId;
    if (customerId == null) {
      emit(state.copyWith(cartMessage: 'cart_login_required', clearAddedProductName: true));
      return;
    }

    try {
      final existing =
          state.items.where((i) => i.version.id == event.version.id).firstOrNull;
      final maxStock = event.version.stockQuantity;

      if (maxStock <= 0 || (existing != null && existing.quantity >= maxStock)) {
        emit(state.copyWith(cartMessage: 'cart_max_stock_reached', clearAddedProductName: true));
        return;
      }

      final added = await repository.addItem(customerId, event.product, event.version);
      if (!added) {
        emit(state.copyWith(cartMessage: 'cart_max_stock_reached', clearAddedProductName: true));
        return;
      }

      final items = await repository.getItems(customerId);
      final selected = Set<String>.from(state.selectedVersionIds)..add(event.version.id);
      emit(state.copyWith(
        items: items,
        selectedVersionIds: _pruneSelection(selected, items),
        addedProductName: '${event.product.name} (${event.version.displayLabel})',
        clearCartMessage: true,
      ));
    } on CartStockException {
      emit(state.copyWith(cartMessage: 'cart_max_stock_reached', clearAddedProductName: true));
    } catch (e) {
      emit(state.copyWith(cartMessage: _cartErrorKey(e), clearAddedProductName: true));
    }
  }

  Future<void> _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) async {
    final customerId = _customerId;
    if (customerId == null) return;

    try {
      await repository.removeItem(customerId, event.productVersionId);
      final items = await repository.getItems(customerId);
      emit(state.copyWith(
        items: items,
        selectedVersionIds: _pruneSelection(state.selectedVersionIds, items),
      ));
    } catch (e) {
      emit(state.copyWith(cartMessage: _cartErrorKey(e)));
    }
  }

  Future<void> _onUpdateQuantity(UpdateQuantityEvent event, Emitter<CartState> emit) async {
    final customerId = _customerId;
    if (customerId == null) return;

    try {
      final existing =
          state.items.where((i) => i.version.id == event.productVersionId).firstOrNull;
      if (existing == null) return;

      final maxStock = existing.maxQuantity;
      if (event.quantity < 1) return;
      if (event.quantity > maxStock) {
        emit(state.copyWith(cartMessage: 'cart_max_stock_reached'));
        return;
      }

      await repository.updateQuantity(customerId, event.productVersionId, event.quantity);
      final items = await repository.getItems(customerId);
      emit(state.copyWith(
        items: items,
        selectedVersionIds: _pruneSelection(state.selectedVersionIds, items),
        clearCartMessage: true,
      ));
    } on CartStockException {
      emit(state.copyWith(cartMessage: 'cart_max_stock_reached'));
    } catch (e) {
      emit(state.copyWith(cartMessage: _cartErrorKey(e)));
    }
  }

  Future<void> _onClearCart(ClearCartEvent event, Emitter<CartState> emit) async {
    final customerId = _customerId;
    if (customerId == null) {
      emit(const CartState());
      return;
    }

    try {
      await repository.clearCart(customerId);
      emit(state.copyWith(
        items: const [],
        selectedVersionIds: const {},
        clearPromoCode: true,
        discountPercent: 0,
        clearPromoError: true,
      ));
    } catch (e) {
      emit(state.copyWith(cartMessage: _cartErrorKey(e)));
    }
  }

  void _onApplyPromoCode(ApplyPromoCodeEvent event, Emitter<CartState> emit) {
    final code = event.code.trim().toUpperCase();
    if (code == 'APPLE10') {
      emit(state.copyWith(
        promoCode: code,
        discountPercent: 0.10,
        clearPromoError: true,
      ));
    } else if (code == 'SAMSUNG20') {
      emit(state.copyWith(
        promoCode: code,
        discountPercent: 0.20,
        clearPromoError: true,
      ));
    } else {
      emit(state.copyWith(promoError: 'promo_invalid'));
    }
  }

  void _onRemovePromoCode(RemovePromoCodeEvent event, Emitter<CartState> emit) {
    emit(state.copyWith(
      clearPromoCode: true,
      discountPercent: 0.0,
      clearPromoError: true,
    ));
  }
}
