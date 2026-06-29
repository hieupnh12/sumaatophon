import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumaatophon/features/cart/presentation/bloc/cart_bloc.dart';

import 'helpers/cart_test_fixtures.dart';
import 'helpers/fake_cart_repository.dart';

void main() {
  late FakeCartRepository repository;

  setUp(() {
    repository = FakeCartRepository();
  });

  group('CartBloc promo logic', () {
    blocTest<CartBloc, CartState>(
      'ApplyPromoCodeEvent APPLE10 sets 10% discount',
      build: () => CartBloc(repository: repository),
      act: (bloc) => bloc.add(const ApplyPromoCodeEvent('apple10')),
      expect: () => [
        const CartState(
          promoCode: 'APPLE10',
          discountPercent: 0.10,
        ),
      ],
    );

    blocTest<CartBloc, CartState>(
      'invalid promo emits promo_invalid error',
      build: () => CartBloc(repository: repository),
      act: (bloc) => bloc.add(const ApplyPromoCodeEvent('INVALID')),
      expect: () => [
        const CartState(promoError: 'promo_invalid'),
      ],
    );
  });

  group('CartBloc AddToCartEvent', () {
    blocTest<CartBloc, CartState>(
      'adds item and updates subtotal when customer is synced',
      build: () => CartBloc(repository: repository),
      seed: () => const CartState(customerId: testCustomerId),
      act: (bloc) {
        final product = testProduct(price: 15000000);
        bloc.add(AddToCartEvent(product, product.versions.first));
      },
      expect: () => [
        predicate<CartState>((state) {
          return state.items.length == 1 &&
              state.subtotal == 15000000 &&
              state.addedProductName != null;
        }),
      ],
    );

    blocTest<CartBloc, CartState>(
      'without customer emits cart_login_required',
      build: () => CartBloc(repository: repository),
      act: (bloc) {
        final product = testProduct();
        bloc.add(AddToCartEvent(product, product.versions.first));
      },
      expect: () => [
        const CartState(cartMessage: 'cart_login_required'),
      ],
    );
  });
}
