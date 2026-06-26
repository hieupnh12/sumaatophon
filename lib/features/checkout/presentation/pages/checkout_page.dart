import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../bloc/checkout_bloc.dart';
import '../widgets/checkout_bottom_bar.dart';
import '../widgets/checkout_info_tab.dart';
import '../widgets/checkout_payment_tab.dart';
import '../widgets/checkout_step_tabs.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
  }

  void _handleBack(BuildContext context, CheckoutState checkoutState) {
    if (checkoutState.step == CheckoutStep.payment) {
      context.read<CheckoutBloc>().add(const SetCheckoutStepEvent(CheckoutStep.information));
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listenWhen: (previous, current) {
        if (!previous.isSuccess && current.isSuccess) return true;
        if (previous.error != current.error && current.error != null) return true;
        return false;
      },
      listener: (context, state) {
        if (state.isSuccess) {
          context.read<CheckoutBloc>().add(ClearCheckoutSuccessEvent());
          context.read<CartBloc>().add(ClearCartEvent());
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
                final subtotal = cartState.selectedFinalPrice;

                return Column(
                  children: [
                    CheckoutStepTabs(
                      activeStep: checkoutState.step,
                      onStepChanged: (step) {
                        if (step == CheckoutStep.payment) {
                          context.read<CheckoutBloc>().add(ContinueToPaymentEvent());
                        } else {
                          context.read<CheckoutBloc>().add(SetCheckoutStepEvent(step));
                        }
                      },
                    ),
                    Expanded(
                      child: checkoutState.step == CheckoutStep.information
                          ? const CheckoutInfoTab()
                          : const CheckoutPaymentTab(),
                    ),
                    CheckoutBottomBar(
                      step: checkoutState.step,
                      subtotal: subtotal,
                      savings: cartState.selectedDiscountAmount,
                      isProcessing: checkoutState.isProcessing,
                      onPrimaryAction: () {
                        if (checkoutState.step == CheckoutStep.information) {
                          context.read<CheckoutBloc>().add(ContinueToPaymentEvent());
                        } else {
                          context.read<CheckoutBloc>().add(
                                SubmitOrderEvent(cartState.selectedFinalPrice.round()),
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
