import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/cart_bloc.dart';

class CartSelectAllBar extends StatelessWidget {
  final bool inSummary;

  const CartSelectAllBar({super.key, this.inSummary = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.items.isEmpty) return const SizedBox.shrink();

        final content = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: inSummary ? 0 : 12,
            vertical: inSummary ? 0 : 10,
          ),
          child: Row(
            children: [
              Checkbox(
                value: state.isAllSelected
                    ? true
                    : (state.hasSelection ? null : false),
                tristate: true,
                onChanged: (_) =>
                    context.read<CartBloc>().add(ToggleSelectAllCartItemsEvent()),
                activeColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  context.tr('cart_select_all'),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (state.hasSelection)
                Text(
                  context.tr('cart_selected_count').replaceAll(
                    '{count}',
                    '${state.selectedTotalItems}',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
            ],
          ),
        );

        if (inSummary) {
          return InkWell(
            onTap: () => context.read<CartBloc>().add(ToggleSelectAllCartItemsEvent()),
            child: content,
          );
        }

        return Material(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.read<CartBloc>().add(ToggleSelectAllCartItemsEvent()),
            child: content,
          ),
        );
      },
    );
  }
}
