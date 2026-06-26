import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/checkout_bloc.dart';
import 'checkout_section_card.dart';

class CheckoutPaymentMethodsSection extends StatefulWidget {
  const CheckoutPaymentMethodsSection({super.key});

  @override
  State<CheckoutPaymentMethodsSection> createState() => _CheckoutPaymentMethodsSectionState();
}

class _CheckoutPaymentMethodsSectionState extends State<CheckoutPaymentMethodsSection> {
  bool _showAll = false;

  List<_PaymentMethodOption> _methodsFor(DeliveryType deliveryType) {
    if (deliveryType == DeliveryType.homeDelivery) {
      return const [
        _PaymentMethodOption(
          id: 'checkout_payment_cod',
          titleKey: 'checkout_payment_cod',
          icon: Icons.delivery_dining_outlined,
        ),
        _PaymentMethodOption(
          id: 'checkout_payment_qr',
          titleKey: 'checkout_payment_qr',
          icon: Icons.qr_code_2_outlined,
        ),
        _PaymentMethodOption(
          id: 'checkout_payment_vnpay',
          titleKey: 'checkout_payment_vnpay',
          icon: Icons.account_balance_wallet_outlined,
        ),
      ];
    }

    return const [
      _PaymentMethodOption(
        id: 'checkout_payment_store',
        titleKey: 'checkout_payment_store',
        descKey: 'checkout_payment_store_desc',
        icon: Icons.storefront_outlined,
      ),
      _PaymentMethodOption(
        id: 'checkout_payment_qr',
        titleKey: 'checkout_payment_qr',
        descKey: 'checkout_payment_qr_desc',
        icon: Icons.qr_code_2_outlined,
      ),
      _PaymentMethodOption(
        id: 'checkout_payment_vnpay',
        titleKey: 'checkout_payment_vnpay',
        icon: Icons.account_balance_wallet_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        final methods = _methodsFor(state.deliveryType);
        final visibleMethods = _showAll ? methods : methods.take(2).toList();

        return CheckoutSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckoutSectionTitle(title: context.tr('checkout_payment_method')),
              ...visibleMethods.map(
                (method) => _PaymentMethodTile(
                  method: method,
                  selectedMethodId: state.selectedPaymentMethod,
                  isDark: isDark,
                  onTap: () {
                    context.read<CheckoutBloc>().add(SelectPaymentMethodEvent(method.id));
                  },
                ),
              ),
              if (!_showAll && methods.length > 2) ...[
                const SizedBox(height: 4),
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showAll = true),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    label: Text(context.tr('checkout_payment_view_all')),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PaymentMethodOption {
  const _PaymentMethodOption({
    required this.id,
    required this.titleKey,
    this.descKey,
    required this.icon,
  });

  final String id;
  final String titleKey;
  final String? descKey;
  final IconData icon;
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selectedMethodId,
    required this.isDark,
    required this.onTap,
  });

  final _PaymentMethodOption method;
  final String selectedMethodId;
  final bool isDark;
  final VoidCallback onTap;

  bool get isSelected => selectedMethodId == method.id;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(method.icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(method.titleKey),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3),
                    ),
                    if (method.descKey != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        context.tr(method.descKey!),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Radio<String>(
                value: method.id,
                groupValue: selectedMethodId,
                onChanged: (_) => onTap(),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
