import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import 'checkout_section_card.dart';

class CheckoutLabeledField extends StatelessWidget {
  const CheckoutLabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class CheckoutTextField extends StatefulWidget {
  const CheckoutTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.keyboardType,
    this.showClear = false,
  });

  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool showClear;

  @override
  State<CheckoutTextField> createState() => _CheckoutTextFieldState();
}

class _CheckoutTextFieldState extends State<CheckoutTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  InputDecoration _inputDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
    );

    return InputDecoration(
      hintText: widget.hintText,
      isDense: true,
      suffixIcon: widget.showClear && widget.controller.text.isNotEmpty
          ? IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              onPressed: () {
                widget.controller.clear();
                widget.onChanged?.call('');
              },
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CheckoutSpacing.inputHeight,
      child: TextField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 14, height: 1.2),
        decoration: _inputDecoration(context),
      ),
    );
  }
}

class CheckoutDropdownField extends StatelessWidget {
  const CheckoutDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: CheckoutSpacing.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          isDense: true,
          value: value != null && items.contains(value) ? value : null,
          hint: Text(
            hint ?? '',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 14,
              height: 1.2,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14, height: 1.2),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
