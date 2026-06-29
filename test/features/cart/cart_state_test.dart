import 'package:flutter_test/flutter_test.dart';
import 'package:sumaatophon/features/cart/presentation/bloc/cart_bloc.dart';

import 'helpers/cart_test_fixtures.dart';

void main() {
  group('CartState total price calculation', () {
    test('subtotal sums unitPrice * quantity for all items', () {
      final state = CartState(
        items: [
          testCartItem(versionId: 'v1', unitPrice: 10000000, quantity: 2),
          testCartItem(versionId: 'v2', unitPrice: 5000000, quantity: 1),
        ],
        selectedVersionIds: const {'v1', 'v2'},
      );

      expect(state.subtotal, 25000000);
      expect(state.totalItems, 3);
    });

    test('selectedSubtotal only includes checked items', () {
      final state = CartState(
        items: [
          testCartItem(versionId: 'v1', unitPrice: 10000000, quantity: 2),
          testCartItem(versionId: 'v2', unitPrice: 5000000, quantity: 1),
        ],
        selectedVersionIds: const {'v1'},
      );

      expect(state.selectedSubtotal, 20000000);
      expect(state.selectedTotalItems, 2);
      expect(state.subtotal, 25000000);
    });

    test('discountAmount and finalPrice apply promo to full cart', () {
      final state = CartState(
        items: [
          testCartItem(versionId: 'v1', unitPrice: 20000000, quantity: 1),
        ],
        selectedVersionIds: const {'v1'},
        promoCode: 'APPLE10',
        discountPercent: 0.10,
      );

      expect(state.discountAmount, 2000000);
      expect(state.finalPrice, 18000000);
    });

    test('selectedFinalPrice applies promo only to selected items', () {
      final state = CartState(
        items: [
          testCartItem(versionId: 'v1', unitPrice: 20000000, quantity: 1),
          testCartItem(versionId: 'v2', unitPrice: 10000000, quantity: 1),
        ],
        selectedVersionIds: const {'v1'},
        promoCode: 'SAMSUNG20',
        discountPercent: 0.20,
      );

      expect(state.selectedSubtotal, 20000000);
      expect(state.selectedDiscountAmount, 4000000);
      expect(state.selectedFinalPrice, 16000000);
      expect(state.finalPrice, 24000000);
    });

    test('empty cart totals are zero', () {
      const state = CartState();

      expect(state.subtotal, 0);
      expect(state.selectedSubtotal, 0);
      expect(state.discountAmount, 0);
      expect(state.finalPrice, 0);
      expect(state.selectedFinalPrice, 0);
      expect(state.totalItems, 0);
    });
  });
}
