import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Khách hàng');
  final _phoneController = TextEditingController(text: '0123456789');
  final _emailController = TextEditingController(text: 'user@phoneshop.com');
  final _dobController = TextEditingController(text: '01/01/2000');
  String _gender = 'Male';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.tr('profile_account_info')),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.person, size: 60, color: theme.colorScheme.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.darkBackground : AppColors.lightBackground, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(context.tr('account_info_name'), _nameController, isDark),
              const SizedBox(height: 16),
              _buildTextField(context.tr('account_info_phone'), _phoneController, isDark, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(context.tr('account_info_email'), _emailController, isDark, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(context.tr('account_info_dob'), _dobController, isDark, readOnly: true, onTap: () {
                // Show date picker
              }),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: context.tr('account_info_gender'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                ),
                dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Nam')),
                  DropdownMenuItem(value: 'Female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'Other', child: Text('Khác')),
                ],
                onChanged: (val) {
                  setState(() {
                    if (val != null) _gender = val;
                  });
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lưu thành công')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.tr('account_info_save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, {TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Không được để trống';
        }
        return null;
      },
    );
  }
}
