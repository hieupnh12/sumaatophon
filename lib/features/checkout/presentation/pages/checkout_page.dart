import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../bloc/checkout_bloc.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('checkout_title'), style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: BlocConsumer<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          if (state.isSuccess) {
            // Show success dialog and clear cart
            context.read<CartBloc>().add(ClearCartEvent());
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: AppColors.success, size: 60),
                    ),
                    const SizedBox(height: 24),
                    Text(context.tr('checkout_order_success_title'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(context.tr('checkout_order_success_desc'), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Pop dialog and pop to home
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(context.tr('checkout_back_home'), style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(state.error!)), backgroundColor: AppColors.error));
          }
        },
        builder: (context, checkoutState) {
          return BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              final totalOrder = cartState.finalPrice + checkoutState.shippingCost;

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- DELIVERY ADDRESS ---
                        Text(context.tr('checkout_delivery_address'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildCard(
                          context: context,
                          isDark: isDark,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Icon(Icons.location_on, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.tr('checkout_home'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(
                                      checkoutState.selectedAddress,
                                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ],
                          ),
                          onTap: () {
                            _showAddressSelectionSheet(context, checkoutState);
                          },
                        ),
                        const SizedBox(height: 24),

                        // --- SHIPPING METHOD ---
                        Text(context.tr('checkout_shipping_method'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildCard(
                          context: context,
                          isDark: isDark,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: theme.colorScheme.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Icon(Icons.local_shipping, color: theme.colorScheme.secondary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.tr(checkoutState.selectedShippingMethod), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${context.tr('checkout_estimated_delivery')}: ${context.tr('checkout_delivery_2_3_days')}',
                                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormatter.format(checkoutState.shippingCost),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ],
                          ),
                          onTap: () {
                            _showShippingMethodSelectionSheet(context, checkoutState);
                          },
                        ),
                        const SizedBox(height: 24),

                        // --- PAYMENT METHOD ---
                        Text(context.tr('checkout_payment_method'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildCard(
                          context: context,
                          isDark: isDark,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.credit_card, color: Colors.orange),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.tr(checkoutState.selectedPaymentMethod), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '**** **** **** 1234',
                                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ],
                          ),
                          onTap: () {
                            _showPaymentMethodSelectionSheet(context, checkoutState);
                          },
                        ),
                        const SizedBox(height: 32),

                        // --- ORDER SUMMARY ---
                        Text(context.tr('checkout_order_summary'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow('${context.tr('checkout_items')} (${cartState.totalItems})', currencyFormatter.format(cartState.subtotal), isDark),
                              const SizedBox(height: 12),
                              if (cartState.discountAmount > 0) ...[
                                _buildSummaryRow(context.tr('discount'), '-${currencyFormatter.format(cartState.discountAmount)}', isDark, isDiscount: true),
                                const SizedBox(height: 12),
                              ],
                              _buildSummaryRow(context.tr('checkout_shipping'), currencyFormatter.format(checkoutState.shippingCost), isDark),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Divider(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(context.tr('total'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                                  Text(
                                    currencyFormatter.format(totalOrder),
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- CONFIRM BUTTON ---
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 20,
                        bottom: MediaQuery.of(context).padding.bottom + 20,
                      ),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                      ),
                      child: ElevatedButton(
                        onPressed: checkoutState.isProcessing
                            ? null
                            : () {
                                context.read<CheckoutBloc>().add(SubmitOrderEvent());
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: checkoutState.isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(context.tr('checkout_confirm_order'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCard({required BuildContext context, required bool isDark, required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, bool isDark, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDiscount ? AppColors.error : null,
          ),
        ),
      ],
    );
  }

  void _showAddressSelectionSheet(BuildContext context, CheckoutState state) {
    final addresses = [
      '123 Nguyen Van Linh, Quan 7, TP. Ho Chi Minh',
      '456 Le Loi, Quan 1, TP. Ho Chi Minh',
      '789 Dien Bien Phu, Quan Binh Thanh, TP. Ho Chi Minh',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(context.tr('checkout_select_address'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              ...addresses.map((address) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(address),
                    trailing: state.selectedAddress == address ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                    onTap: () {
                      context.read<CheckoutBloc>().add(SelectAddressEvent(address));
                      Navigator.pop(ctx);
                    },
                  )),
              const Divider(),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: const Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
                title: Text(context.tr('checkout_add_new_address'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  // Push to Add Address Screen
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showShippingMethodSelectionSheet(BuildContext context, CheckoutState state) {
    final methods = [
      {'name': 'checkout_shipping_standard', 'cost': 5.0, 'time': 'checkout_delivery_2_3_days'},
      {'name': 'checkout_shipping_fast', 'cost': 10.0, 'time': 'checkout_delivery_1_2_days'},
      {'name': 'checkout_shipping_express', 'cost': 15.0, 'time': 'checkout_delivery_same_day'},
    ];

    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(context.tr('checkout_select_shipping'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              ...methods.map((method) {
                final name = method['name'] as String;
                final cost = method['cost'] as double;
                final time = method['time'] as String;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text(context.tr(name)),
                  subtitle: Text('${context.tr('checkout_estimated_delivery')}: ${context.tr(time)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currencyFormatter.format(cost), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 12),
                      if (state.selectedShippingMethod == name) const Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                  onTap: () {
                    context.read<CheckoutBloc>().add(SelectShippingMethodEvent(name, cost));
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentMethodSelectionSheet(BuildContext context, CheckoutState state) {
    final methods = [
      {'name': 'checkout_payment_cod', 'icon': Icons.money},
      {'name': 'checkout_payment_momo', 'icon': Icons.account_balance_wallet},
      {'name': 'checkout_payment_zalopay', 'icon': Icons.account_balance_wallet_outlined},
      {'name': 'checkout_payment_card', 'icon': Icons.credit_card},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(context.tr('checkout_select_payment'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              ...methods.map((method) {
                final name = method['name'] as String;
                final icon = method['icon'] as IconData;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: Icon(icon),
                  title: Text(context.tr(name)),
                  trailing: state.selectedPaymentMethod == name ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                  onTap: () {
                    context.read<CheckoutBloc>().add(SelectPaymentMethodEvent(name));
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
