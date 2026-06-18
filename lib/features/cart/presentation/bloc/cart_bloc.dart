import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';
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
  const AddToCartEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class RemoveFromCartEvent extends CartEvent {
  final Product product;
  const RemoveFromCartEvent(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateQuantityEvent extends CartEvent {
  final Product product;
  final int quantity;

  const UpdateQuantityEvent(this.product, this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}

class ClearCartEvent extends CartEvent {}

class ApplyPromoCodeEvent extends CartEvent {
  final String code;
  const ApplyPromoCodeEvent(this.code);

  @override
  List<Object?> get props => [code];
}

class RemovePromoCodeEvent extends CartEvent {}

// --- STATE ---
class CartState extends Equatable {
  final List<CartItem> items;
  final String? promoCode;
  final double discountPercent;
  final String? promoError;
  final bool isLoading;

  const CartState({
    this.items = const [],
    this.promoCode,
    this.discountPercent = 0.0,
    this.promoError,
    this.isLoading = false,
  });

  int get totalItems => items.fold(0, (total, item) => total + item.quantity);

  double get subtotal =>
      items.fold(0, (total, item) => total + (item.product.price * item.quantity));

  double get discountAmount => subtotal * discountPercent;

  double get finalPrice => subtotal - discountAmount;

  CartState copyWith({
    List<CartItem>? items,
    String? promoCode,
    double? discountPercent,
    String? promoError,
    bool? isLoading,
    bool clearPromoError = false,
    bool clearPromoCode = false,
  }) {
    return CartState(
      items: items ?? this.items,
      promoCode: clearPromoCode ? null : (promoCode ?? this.promoCode),
      discountPercent: discountPercent ?? this.discountPercent,
      promoError: clearPromoError ? null : (promoError ?? this.promoError),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [items, promoCode, discountPercent, promoError, isLoading];
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
  }

  // Tải giỏ hàng từ SQLite khi app mở lên
  Future<void> _onLoadCart(LoadCartEvent event, Emitter<CartState> emit) async {
    emit(state.copyWith(isLoading: true));
    final items = await repository.getItems();
    emit(state.copyWith(items: items, isLoading: false));
  }

  Future<void> _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) async {
    await repository.addItem(event.product);
    final items = await repository.getItems();
    emit(state.copyWith(items: items));
  }

  Future<void> _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) async {
    await repository.removeItem(event.product);
    final items = await repository.getItems();
    emit(state.copyWith(items: items));
  }

  Future<void> _onUpdateQuantity(UpdateQuantityEvent event, Emitter<CartState> emit) async {
    await repository.updateQuantity(event.product, event.quantity);
    final items = await repository.getItems();
    emit(state.copyWith(items: items));
  }

  Future<void> _onClearCart(ClearCartEvent event, Emitter<CartState> emit) async {
    await repository.clearCart();
    emit(const CartState());
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
      emit(state.copyWith(promoError: 'Invalid or expired promo code.'));
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
