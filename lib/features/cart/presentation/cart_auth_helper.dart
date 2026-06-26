import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../../core/auth/auth_guard.dart';
import '../../products/domain/entities/product.dart';
import '../../products/domain/entities/product_version.dart';
import 'bloc/cart_bloc.dart';
import 'pages/cart_page.dart';

Future<void> ensureCartReady(BuildContext context) async {
  final authState = context.read<AuthBloc>().state;
  if (authState is! AuthenticatedState) return;

  final userId = authState.user.id;
  final cartBloc = context.read<CartBloc>();

  if (cartBloc.state.customerId != userId) {
    cartBloc.add(SyncCartCustomerEvent(userId));
    await cartBloc.stream.firstWhere(
      (state) => state.customerId == userId && !state.isLoading,
    );
  }
}

Future<void> openCartWithAuth(BuildContext context) async {
  if (!await requireAuthForCart(context, confirmBeforeLogin: true)) return;
  await ensureCartReady(context);
  if (!context.mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CartPage()),
  );
}

Future<void> addToCartWithAuth(
  BuildContext context,
  Product product,
  ProductVersion version,
) async {
  if (!await requireAuthForCart(context, confirmBeforeLogin: true)) return;
  await ensureCartReady(context);
  if (!context.mounted) return;

  context.read<CartBloc>().add(AddToCartEvent(product, version));
}
