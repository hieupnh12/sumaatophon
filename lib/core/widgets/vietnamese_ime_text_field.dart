import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TextField tối ưu gõ tiếng Việt (Telex/VNI) — tránh autocorrect và IME bị reset.
class VietnameseImeTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final TextStyle? style;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final String fieldKey;

  const VietnameseImeTextField({
    super.key,
    required this.controller,
    required this.decoration,
    this.style,
    this.minLines = 1,
    this.maxLines = 4,
    this.enabled = true,
    this.fieldKey = 'vietnamese_ime_input',
  });

  @override
  State<VietnameseImeTextField> createState() => _VietnameseImeTextFieldState();
}

class _VietnameseImeTextFieldState extends State<VietnameseImeTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey(widget.fieldKey),
      controller: widget.controller,
      enabled: widget.enabled,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style: widget.style,
      decoration: widget.decoration,
      autocorrect: false,
      enableSuggestions: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      enableIMEPersonalizedLearning: true,
    );
  }
}

bool isTextComposing(TextEditingController controller) {
  return controller.value.composing.isValid;
}

String? readComposedText(TextEditingController controller) {
  if (controller.value.composing.isValid) return null;
  final text = controller.text.trim();
  return text.isEmpty ? null : text;
}

void clearComposedText(TextEditingController controller) {
  controller.clear();
}
