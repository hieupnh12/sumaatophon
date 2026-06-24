import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_version.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';

// --- EVENTS ---
abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

// Tải giỏ hàng từ SQLite khi app khởi động
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

// --- STATE ---
class CartState extends Equatable {
  final List<CartItem> items;
  final String? promoCode;
  final double discountPercent;
  final String? promoError;
  final String? cartMessage;
  final String? addedProductName;
  final bool isLoading;

  const CartState({
    this.items = const [],
    this.promoCode,
    this.discountPercent = 0.0,
    this.promoError,
    this.cartMessage,
    this.addedProductName,
    this.isLoading = false,
  });

  int get totalItems => items.fold(0, (total, item) => total + item.quantity);

  double get subtotal =>
      items.fold(0, (total, item) => total + (item.unitPrice * item.quantity));

  double get discountAmount => subtotal * discountPercent;

  double get finalPrice => subtotal - discountAmount;

  CartState copyWith({
    List<CartItem>? items,
    String? promoCode,
    double? discountPercent,
    String? promoError,
    String? cartMessage,
    String? addedProductName,
    bool? isLoading,
    bool clearPromoError = false,
    bool clearPromoCode = false,
    bool clearCartMessage = false,
    bool clearAddedProductName = false,
  }) {
    return CartState(
      items: items ?? this.items,
      promoCode: clearPromoCode ? null : (promoCode ?? this.promoCode),
      discountPercent: discountPercent ?? this.discountPercent,
      promoError: clearPromoError ? null : (promoError ?? this.promoError),
      cartMessage: clearCartMessage ? null : (cartMessage ?? this.cartMessage),
      addedProductName: clearAddedProductName ? null : (addedProductName ?? this.addedProductName),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props =>
      [items, promoCode, discountPercent, promoError, cartMessage, addedProductName, isLoading];
}

// --- BLOC ---
class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository repository;

  CartBloc({required this.repository}) : super(const CartState()) {
    on<LoadCartEvent>(_onLoadCart);
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<ApplyPromoCodeEvent>(_onApplyPromoCode);
    on<RemovePromoCodeEvent>(_onRemovePromoCode);
    on<ClearCartMessageEvent>((event, emit) => emit(state.copyWith(clearCartMessage: true)));
    on<ClearCartAddedEvent>((event, emit) => emit(state.copyWith(clearAddedProductName: true)));
  }

  Future<void> _onLoadCart(LoadCartEvent event, Emitter<CartState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      final items = await repository.getItems();
      emit(state.copyWith(items: items, isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false, cartMessage: 'cart_save_error'));
    }
  }

  Future<void> _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) async {
    try {
      final existing =
          state.items.where((i) => i.version.id == event.version.id).firstOrNull;
      final maxStock = event.version.stockQuantity;

      if (maxStock <= 0 || (existing != null && existing.quantity >= maxStock)) {
        emit(state.copyWith(cartMessage: 'cart_max_stock_reached', clearAddedProductName: true));
        return;
      }

      final added = await repository.addItem(event.product, event.version);
      if (!added) {
        emit(state.copyWith(cartMessage: 'cart_max_stock_reached', clearAddedProductName: true));
        return;
      }

      final items = await repository.getItems();
      emit(state.copyWith(
        items: items,
        addedProductName: '${event.product.name} (${event.version.displayLabel})',
        clearCartMessage: true,
      ));
    } catch (_) {
      emit(state.copyWith(cartMessage: 'cart_save_error', clearAddedProductName: true));
    }
  }

  Future<void> _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) async {
    try {
      await repository.removeItem(event.productVersionId);
      final items = await repository.getItems();
      emit(state.copyWith(items: items));
    } catch (_) {
      emit(state.copyWith(cartMessage: 'cart_save_error'));
    }
  }

  Future<void> _onUpdateQuantity(UpdateQuantityEvent event, Emitter<CartState> emit) async {
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

      await repository.updateQuantity(event.productVersionId, event.quantity);
      final items = await repository.getItems();
      emit(state.copyWith(items: items, clearCartMessage: true));
    } catch (_) {
      emit(state.copyWith(cartMessage: 'cart_save_error'));
    }
  }

  Future<void> _onClearCart(ClearCartEvent event, Emitter<CartState> emit) async {
    try {
      await repository.clearCart();
      emit(const CartState());
    } catch (_) {
      emit(state.copyWith(cartMessage: 'cart_save_error'));
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
