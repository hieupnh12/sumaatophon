import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  String _gender = 'Other';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    String name = '';
    String phone = '';
    String email = '';
    String dob = '';
    String address = '';
    int? genderVal;

    if (authState is AuthenticatedState) {
      name = authState.user.name;
      phone = authState.user.phoneNumber ?? '';
      email = authState.user.email;
      dob = authState.user.dob ?? '';
      address = authState.user.address ?? '';
      genderVal = authState.user.gender;
    }

    _nameController = TextEditingController(text: name);
    _phoneController = TextEditingController(text: phone);
    _emailController = TextEditingController(text: email);
    _dobController = TextEditingController(text: dob);
    _addressController = TextEditingController(text: address);

    if (genderVal == 1) _gender = 'Male';
    else if (genderVal == 2) _gender = 'Female';
    else _gender = 'Other';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
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
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          } else if (state is AuthenticatedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lưu thông tin thành công'), backgroundColor: AppColors.success),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
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
                  _buildTextField('Họ và tên', _nameController, isDark),
                  const SizedBox(height: 16),
                  _buildTextField('Số điện thoại', _phoneController, isDark, keyboardType: TextInputType.phone, readOnly: true, helpText: 'Không thể sửa SĐT'),
                  const SizedBox(height: 16),
                  _buildTextField('Email', _emailController, isDark, keyboardType: TextInputType.emailAddress, readOnly: true, helpText: 'Không thể sửa Email'),
                  const SizedBox(height: 16),
                  _buildTextField('Ngày sinh (YYYY-MM-DD)', _dobController, isDark, readOnly: true, onTap: () => _selectDate(context)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: InputDecoration(
                      labelText: 'Giới tính',
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
                  const SizedBox(height: 16),
                  _buildTextField('Địa chỉ', _addressController, isDark, maxLines: 2),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading ? null : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        context.read<AuthBloc>().add(UpdateProfileRequested(
                          name: _nameController.text.trim(),
                          gender: _gender,
                          dob: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
                          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(context.tr('account_info_save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark, {TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap, int maxLines = 1, String? helpText}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? (readOnly ? Colors.white54 : Colors.white) : (readOnly ? Colors.black54 : Colors.black)),
      decoration: InputDecoration(
        labelText: label,
        helperText: helpText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      ),
      validator: (value) {
        if (!readOnly && (value == null || value.isEmpty)) {
          return 'Không được để trống';
        }
        return null;
      },
    );
  }
}
