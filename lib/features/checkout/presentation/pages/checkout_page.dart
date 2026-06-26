import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../data/datasources/checkout_remote_datasource.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../bloc/checkout_bloc.dart';
import '../widgets/checkout_bottom_bar.dart';
import '../widgets/checkout_info_tab.dart';
import '../widgets/checkout_payment_tab.dart';
import '../widgets/checkout_step_tabs.dart';
import 'payos_qr_payment_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      context.read<CheckoutBloc>().add(
            InitializeCheckoutEvent(
              customerName: authState.user.name,
              customerPhone: authState.user.phone ?? '',
              customerEmail: authState.user.email,
              memberCode: authState.user.id.isNotEmpty ? authState.user.id : 'NULL',
            ),
          );
    }
    context.read<CheckoutBloc>().add(const ApplyDefaultPickupStoreEvent());
  }

  void _handleBack(BuildContext context, CheckoutState checkoutState) {
    if (checkoutState.step == CheckoutStep.payment) {
      context.read<CheckoutBloc>().add(const SetCheckoutStepEvent(CheckoutStep.information));
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _openPayOsPayment(BuildContext context, CheckoutState state) async {
    final checkoutUrl = state.payOsCheckoutUrl;
    final orderId = state.pendingOrderId;
    final amount = state.payOsAmount;
    if (checkoutUrl == null || orderId == null || amount == null) return;

    final paymentDataSource = GetIt.I<PaymentRemoteDataSource>();

    context.read<CheckoutBloc>().add(const ClearPayOsCheckoutEvent());

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PayOsQrPaymentPage(
          orderId: orderId,
          amount: amount,
          checkoutUrl: checkoutUrl,
          qrCode: state.payOsQrCode,
          onPollPaymentStatus: () => paymentDataSource.getPayOsStatus(orderId),
        ),
      ),
    );

    if (!context.mounted) return;

    context.read<CheckoutBloc>().add(
          CompletePayOsPaymentEvent(
            success: success == true,
            orderId: orderId,
          ),
        );
  }

  List<CheckoutOrderItemPayload> _selectedOrderItems(CartState cartState) {
    return cartState.selectedItems
        .map(
          (item) => CheckoutOrderItemPayload(
            productVersionId: item.version.id,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          ),
        )
        .toList();
  }

  String? _resolveCustomerId(BuildContext context, CartState cartState) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState && authState.user.id.isNotEmpty) {
      return authState.user.id;
    }
    return cartState.customerId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listenWhen: (previous, current) {
        if (!previous.isSuccess && current.isSuccess) return true;
        if (previous.error != current.error && current.error != null) return true;
        if (previous.payOsCheckoutUrl != current.payOsCheckoutUrl && current.payOsCheckoutUrl != null) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state.payOsCheckoutUrl != null && state.pendingOrderId != null) {
          _openPayOsPayment(context, state);
          return;
        }

        if (state.isSuccess) {
          context.read<CheckoutBloc>().add(ClearCheckoutSuccessEvent());
          context.read<CartBloc>().add(LoadCartEvent());
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
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
                  Text(
                    context.tr('checkout_order_success_title'),
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(context.tr('checkout_order_success_desc'), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).popUntil((route) => route.isFirst);
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.trRead(state.error!)),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<CheckoutBloc>().add(ClearCheckoutErrorEvent());
        }
      },
      builder: (context, checkoutState) {
        return PopScope(
          canPop: checkoutState.step == CheckoutStep.information,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && checkoutState.step == CheckoutStep.payment) {
              context.read<CheckoutBloc>().add(const SetCheckoutStepEvent(CheckoutStep.information));
            }
          },
          child: Scaffold(
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBack(context, checkoutState),
              ),
              title: Text(
                context.tr('checkout_payment_info_title'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              centerTitle: true,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightCard,
              elevation: 0,
            ),
            body: BlocBuilder<CartBloc, CartState>(
              builder: (context, cartState) {
                final shippingFee = CheckoutBloc.shippingFeeFor(checkoutState);
                final subtotal = cartState.selectedFinalPrice + shippingFee;
                final customerId = _resolveCustomerId(context, cartState);

                return Column(
                  children: [
                    CheckoutStepTabs(
                      activeStep: checkoutState.step,
                      onStepChanged: (step) {
                        if (step == CheckoutStep.payment) {
                          context.read<CheckoutBloc>().add(
                                ContinueToPaymentEvent(
                                  hasSelectedCartItems: cartState.hasSelection,
                                ),
                              );
                        } else {
                          context.read<CheckoutBloc>().add(SetCheckoutStepEvent(step));
                        }
                      },
                    ),
                    Expanded(
                      child: checkoutState.step == CheckoutStep.information
                          ? const CheckoutInfoTab()
                          : CheckoutPaymentTab(key: ValueKey(checkoutState.deliveryType)),
                    ),
                    CheckoutBottomBar(
                      step: checkoutState.step,
                      subtotal: subtotal,
                      savings: cartState.selectedDiscountAmount,
                      isProcessing: checkoutState.isProcessing,
                      onPrimaryAction: () {
                        if (checkoutState.step == CheckoutStep.information) {
                          context.read<CheckoutBloc>().add(
                                ContinueToPaymentEvent(
                                  hasSelectedCartItems: cartState.hasSelection,
                                ),
                              );
                        } else if (customerId == null || customerId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('cart_login_required')),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        } else {
                          context.read<CheckoutBloc>().add(
                                SubmitOrderEvent(
                                  customerId: customerId,
                                  items: _selectedOrderItems(cartState),
                                  subtotal: cartState.selectedSubtotal,
                                  discount: cartState.selectedDiscountAmount,
                                ),
                              );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
