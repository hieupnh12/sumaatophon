import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../checkout/presentation/pages/checkout_page.dart';
import '../bloc/cart_bloc.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('cart'), style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              context.read<CartBloc>().add(ClearCartEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (state.promoError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.promoError!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_cart_outlined, size: 80, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(context.tr('cart_empty_title'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('cart_empty_desc'), 
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(context.tr('explore_now'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            );
          }

          return Column(
            children: [
              // --- CART ITEMS ---
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final cartItem = state.items[index];
                    final product = cartItem.product;

                    return Dismissible(
                      key: Key(product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        padding: const EdgeInsets.only(right: 24),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
                      ),
                      onDismissed: (direction) {
                        HapticFeedback.heavyImpact();
                        context.read<CartBloc>().add(RemoveFromCartEvent(product));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1,
                          ),
                          boxShadow: [
                            if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Product Image
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(product.imageUrl, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Product Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currencyFormatter.format(product.price),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity Controls
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      context.read<CartBloc>().add(UpdateQuantityEvent(product, cartItem.quantity - 1));
                                    },
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Text(
                                    '${cartItem.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      context.read<CartBloc>().add(UpdateQuantityEvent(product, cartItem.quantity + 1));
                                    },
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- ORDER SUMMARY BOTTOM SHEET ---
              Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Promo Code Input
                    if (state.promoCode == null)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: context.tr('promo_hint'),
                                filled: true,
                                fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (_promoController.text.isNotEmpty) {
                                context.read<CartBloc>().add(ApplyPromoCodeEvent(_promoController.text));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Apply'),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Promo \'${state.promoCode}\' applied',
                                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                _promoController.clear();
                                context.read<CartBloc>().add(RemovePromoCodeEvent());
                              },
                              child: const Icon(Icons.close, color: AppColors.success, size: 20),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr('subtotal'), style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        Text(currencyFormatter.format(state.subtotal), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Discount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr('discount'), style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        Text(
                          state.discountAmount > 0 ? '-${currencyFormatter.format(state.discountAmount)}' : '\$0',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: state.discountAmount > 0 ? AppColors.error : null),
                        ),
                      ],
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(),
                    ),
                    
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.tr('total'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                        Text(
                          currencyFormatter.format(state.finalPrice),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Checkout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CheckoutPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(context.tr('checkout'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
