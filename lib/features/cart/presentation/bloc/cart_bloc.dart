import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';

// --- ENTITIES ---
class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

// --- EVENTS ---
abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

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

// --- STATES ---
class CartState extends Equatable {
  final List<CartItem> items;
  final String? promoCode;
  final double discountPercent; // 0.0 to 1.0
  final String? promoError;
  
  const CartState({
    this.items = const [],
    this.promoCode,
    this.discountPercent = 0.0,
    this.promoError,
  });

  int get totalItems => items.fold(0, (total, current) => total + current.quantity);
  
  double get subtotal => items.fold(0, (total, current) => total + (current.product.price * current.quantity));

  double get discountAmount => subtotal * discountPercent;

  double get finalPrice => subtotal - discountAmount;

  CartState copyWith({
    List<CartItem>? items,
    String? promoCode,
    double? discountPercent,
    String? promoError,
    bool clearPromoError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      promoCode: promoCode ?? this.promoCode,
      discountPercent: discountPercent ?? this.discountPercent,
      promoError: clearPromoError ? null : (promoError ?? this.promoError),
    );
  }

  @override
  List<Object?> get props => [items, promoCode, discountPercent, promoError];
}

// --- BLOC ---
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<ApplyPromoCodeEvent>(_onApplyPromoCode);
    on<RemovePromoCodeEvent>(_onRemovePromoCode);
  }

  void _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final existingIndex = updatedItems.indexWhere((item) => item.product.id == event.product.id);

    if (existingIndex >= 0) {
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + 1);
    } else {
      updatedItems.add(CartItem(product: event.product));
    }

    emit(state.copyWith(items: updatedItems));
  }

  void _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items)
      ..removeWhere((item) => item.product.id == event.product.id);
    emit(state.copyWith(items: updatedItems));
  }

  void _onUpdateQuantity(UpdateQuantityEvent event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final existingIndex = updatedItems.indexWhere((item) => item.product.id == event.product.id);

    if (existingIndex >= 0) {
      if (event.quantity <= 0) {
        updatedItems.removeAt(existingIndex);
      } else {
        final existingItem = updatedItems[existingIndex];
        updatedItems[existingIndex] = existingItem.copyWith(quantity: event.quantity);
      }
      emit(state.copyWith(items: updatedItems));
    }
  }

  void _onClearCart(ClearCartEvent event, Emitter<CartState> emit) {
    emit(const CartState(items: []));
  }

  void _onApplyPromoCode(ApplyPromoCodeEvent event, Emitter<CartState> emit) {
    // Mock promo code logic
    final code = event.code.trim().toUpperCase();
    if (code == 'APPLE10') {
      emit(state.copyWith(
        promoCode: code,
        discountPercent: 0.10, // 10% discount
        clearPromoError: true,
      ));
    } else if (code == 'SAMSUNG20') {
      emit(state.copyWith(
        promoCode: code,
        discountPercent: 0.20, // 20% discount
        clearPromoError: true,
      ));
    } else {
      emit(state.copyWith(
        promoError: 'Invalid or expired promo code.',
        clearPromoError: false,
      ));
    }
  }

  void _onRemovePromoCode(RemovePromoCodeEvent event, Emitter<CartState> emit) {
    emit(CartState(
      items: state.items,
      promoCode: null,
      discountPercent: 0.0,
      promoError: null,
    ));
  }
}
