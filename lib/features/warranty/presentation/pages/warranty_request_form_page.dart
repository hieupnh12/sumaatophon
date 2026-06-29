import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/warranty_item.dart';
import '../bloc/warranty_bloc.dart';
import '../bloc/warranty_event.dart';

class WarrantyRequestFormPage extends StatefulWidget {
  final WarrantyItem item;
  final int customerId;

  const WarrantyRequestFormPage({super.key, required this.item, required this.customerId});

  @override
  State<WarrantyRequestFormPage> createState() => _WarrantyRequestFormPageState();
}

class _WarrantyRequestFormPageState extends State<WarrantyRequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedIssueGroup = '';
  String _selectedReceiptMethod = '';
  final _detailController = TextEditingController();

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedIssueGroup.isEmpty || _selectedReceiptMethod.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('warranty_please_select_all'))),
        );
        return;
      }

      final combinedReason =
          '[${context.tr('warranty_issue_group')}: $_selectedIssueGroup] '
          '[${context.tr('warranty_receipt_method')}: $_selectedReceiptMethod] '
          '- ${_detailController.text.trim()}';

      context.read<WarrantyBloc>().add(
        SubmitWarrantyRequestEvent(
          customerId: widget.customerId,
          orderId: widget.item.orderId,
          productVersionId: widget.item.productVersionId,
          reason: combinedReason,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final issueGroups = [
      context.tr('warranty_issue_power'),
      context.tr('warranty_issue_screen'),
      context.tr('warranty_issue_battery'),
      context.tr('warranty_issue_other'),
    ];

    final receiptMethods = [
      context.tr('warranty_receipt_store'),
      context.tr('warranty_receipt_home'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('warranty_form_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product info summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.item.image.isNotEmpty ? widget.item.image : 'https://via.placeholder.com/150',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, _, __) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${context.tr('warranty_until')}: ${widget.item.warrantyUntil}',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Issue Group
              Text(context.tr('warranty_issue_group'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                hint: Text(context.tr('warranty_select_issue_group')),
                items: issueGroups.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedIssueGroup = val ?? '';
                  });
                },
              ),
              const SizedBox(height: 24),

              // Receipt Method
              Text(context.tr('warranty_receipt_method'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                hint: Text(context.tr('warranty_select_receipt_method')),
                items: receiptMethods.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedReceiptMethod = val ?? '';
                  });
                },
              ),
              const SizedBox(height: 24),

              // Detailed Reason
              Text(context.tr('warranty_reason_detail'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: context.tr('warranty_reason_hint'),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.tr('warranty_error_empty_reason');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    context.tr('warranty_submit'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
