import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumaatophon/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:sumaatophon/features/products/domain/entities/product.dart';

import '../helpers/cart_test_fixtures.dart';
import '../helpers/fake_cart_repository.dart';

/// Nút thêm giỏ giống `ProductDetailPage` (icon + key), gọi thẳng `CartBloc`
/// để test widget không cần Firebase / AuthBloc.
class AddToCartButtonProbe extends StatelessWidget {
  final Product product;
  final bool canPurchase;

  const AddToCartButtonProbe({
    super.key,
    required this.product,
    required this.canPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 56,
            height: 56,
            child: OutlinedButton(
              key: const Key('product_detail_add_to_cart_button'),
              onPressed: canPurchase
                  ? () {
                      final version = product.versions.first;
                      context.read<CartBloc>().add(
                            AddToCartEvent(product, version),
                          );
                    }
                  : null,
              child: const Icon(Icons.add_shopping_cart),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  Future<CartBloc> createReadyCartBloc(FakeCartRepository repository) async {
    final cartBloc = CartBloc(repository: repository)
      ..add(const SyncCartCustomerEvent(testCustomerId));
    await cartBloc.stream.firstWhere(
      (state) => state.customerId == testCustomerId && !state.isLoading,
    );
    return cartBloc;
  }

  group('Add to Cart button', () {
    testWidgets('is visible and tappable when product is in stock', (tester) async {
      final product = testProduct(stockQuantity: 3);
      final repository = FakeCartRepository();
      final cartBloc = await createReadyCartBloc(repository);

      await tester.pumpWidget(
        BlocProvider<CartBloc>.value(
          value: cartBloc,
          child: AddToCartButtonProbe(product: product, canPurchase: true),
        ),
      );

      final addButton = find.byKey(const Key('product_detail_add_to_cart_button'));
      expect(addButton, findsOneWidget);
      expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);

      final button = tester.widget<OutlinedButton>(addButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('is disabled when product is out of stock', (tester) async {
      final product = testProduct(
        stockQuantity: 0,
        versions: [testProductVersion(stockQuantity: 0)],
      );
      final repository = FakeCartRepository();
      final cartBloc = await createReadyCartBloc(repository);

      await tester.pumpWidget(
        BlocProvider<CartBloc>.value(
          value: cartBloc,
          child: AddToCartButtonProbe(product: product, canPurchase: false),
        ),
      );

      final button = tester.widget<OutlinedButton>(
        find.byKey(const Key('product_detail_add_to_cart_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('adds item to cart after tap', (tester) async {
      final product = testProduct(price: 18000000, stockQuantity: 4);
      final repository = FakeCartRepository();
      final cartBloc = await createReadyCartBloc(repository);

      await tester.pumpWidget(
        BlocProvider<CartBloc>.value(
          value: cartBloc,
          child: AddToCartButtonProbe(product: product, canPurchase: true),
        ),
      );

      await tester.tap(find.byKey(const Key('product_detail_add_to_cart_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cartBloc.state.items, hasLength(1));
      expect(cartBloc.state.subtotal, 18000000);
      expect(cartBloc.state.addedProductName, contains('iPhone 16 Pro'));
      expect(repository.itemsFor(testCustomerId), hasLength(1));
    });
  });
}
