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
  bool _isEditing = false;

  String _initialName = '';
  String _initialEmail = '';
  String _initialDob = '';
  String _initialGender = 'Other';

  bool get _hasChanges {
    return _nameController.text.trim() != _initialName ||
           _emailController.text.trim() != _initialEmail ||
           _dobController.text.trim() != _initialDob ||
           _gender != _initialGender;
  }

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

    _initialName = name.trim();
    _initialEmail = email.trim();
    _initialDob = dob.trim();

    if (genderVal == 1) _gender = 'Male';
    else if (genderVal == 2) _gender = 'Female';
    else _gender = 'Other';

    _initialGender = _gender;
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
    if (!_isEditing) return;
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

  Future<bool> _onWillPop() async {
    if (!_isEditing) return true;
    
    if (!_hasChanges) {
      setState(() {
        _isEditing = false;
      });
      return false;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('account_info_unsaved_title')),
        content: Text(context.tr('account_info_unsaved_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('account_info_discard'), style: const TextStyle(color: AppColors.error)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('account_info_keep_editing')),
          ),
        ],
      ),
    );
    if (shouldPop == true) {
      setState(() {
        _isEditing = false;
        _nameController.text = _initialName;
        _emailController.text = _initialEmail;
        _dobController.text = _initialDob;
        _gender = _initialGender;
      });
      return false; // Prevent popping, just exit edit mode
    }
    return false;
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(UpdateProfileRequested(
        name: _nameController.text.trim(),
        gender: _gender,
        dob: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          } else if (state is AuthenticatedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lưu thông tin thành công'), backgroundColor: AppColors.success),
            );
            setState(() {
              _isEditing = false;
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          String name = _nameController.text;
          if (state is AuthenticatedState) name = state.user.name;

          return Scaffold(
            backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF5F6F8),
            appBar: AppBar(
              title: Text(context.tr('profile_account_info'), style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.black87),
              actions: [
                if (!_isEditing)
                  TextButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: const Text(
                      'Sửa',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )
                else
                  TextButton(
                    onPressed: (isLoading || !_hasChanges) ? null : _onSave,
                    child: isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                            'Lưu',
                            style: TextStyle(
                              color: _hasChanges ? AppColors.primary : Colors.grey, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 16,
                            ),
                          ),
                  ),
              ],
            ),
            extendBodyBehindAppBar: true,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(name, isDark),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin tài khoản',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: _isEditing ? _buildEditForm(isDark) : _buildViewMode(isDark),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String name, bool isDark) {
    String avatarUrl;
    final seed = Uri.encodeComponent(name.isEmpty ? 'User' : name);
    if (_gender == 'Male') {
      avatarUrl = 'https://api.dicebear.com/9.x/croodles/png?seed=$seed-boy&backgroundColor=b6e3f4';
    } else if (_gender == 'Female') {
      avatarUrl = 'https://api.dicebear.com/9.x/croodles/png?seed=$seed-girl&backgroundColor=ffdfbf';
    } else {
      avatarUrl = 'https://api.dicebear.com/9.x/croodles/png?seed=$seed&backgroundColor=e2e2e2';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 100, bottom: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE6F3E6), // Light greenish top
            Color(0xFFFFF0F0), // Light pinkish bottom
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                avatarUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    _gender == 'Male' ? Icons.face : (_gender == 'Female' ? Icons.face_3 : Icons.person),
                    size: 60,
                    color: Colors.grey.shade400,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewMode(bool isDark) {
    return Column(
      children: [
        _buildViewRow('Họ và tên', _nameController.text, isDark),
        _buildDivider(),
        _buildViewRow('Email', _emailController.text.isNotEmpty ? _emailController.text : '-', isDark),
        _buildDivider(),
        _buildViewRow('Số điện thoại', _phoneController.text, isDark),
        _buildDivider(),
        _buildViewRow('Ngày sinh', _dobController.text.isNotEmpty ? _dobController.text : '-', isDark),
        _buildDivider(),
        _buildViewRow('Giới tính', _gender == 'Male' ? 'Nam' : (_gender == 'Female' ? 'Nữ' : 'Khác'), isDark, isLast: true),
      ],
    );
  }

  Widget _buildEditForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Họ và tên'),
        const SizedBox(height: 8),
        _buildTextField(_nameController, isDark, hint: 'Nhập họ và tên'),
        const SizedBox(height: 16),
        _buildFieldLabel('Email'),
        const SizedBox(height: 8),
        _buildTextField(_emailController, isDark, hint: 'Nhập Email', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildFieldLabel('Số điện thoại'),
        const SizedBox(height: 8),
        _buildTextField(_phoneController, isDark, readOnly: true, prefixIcon: Icons.phone_outlined, fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF5F6F8)),
        const SizedBox(height: 16),
        _buildFieldLabel('Ngày sinh'),
        const SizedBox(height: 8),
        _buildTextField(_dobController, isDark, readOnly: true, suffixIcon: Icons.calendar_today_outlined, onTap: () => _selectDate(context)),
        const SizedBox(height: 16),
        _buildFieldLabel('Giới tính'),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRadio('Male', 'Nam'),
            const SizedBox(width: 24),
            _buildRadio('Female', 'Nữ'),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildRadio(String value, String label) {
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _gender == value ? Colors.red : Colors.grey,
                width: _gender == value ? 6 : 1.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildViewRow(String label, String value, bool isDark, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.blueGrey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0));
  }

  Widget _buildTextField(
    TextEditingController controller, 
    bool isDark, 
    {
      String? hint, 
      TextInputType? keyboardType, 
      bool readOnly = false, 
      VoidCallback? onTap, 
      IconData? prefixIcon,
      IconData? suffixIcon,
      Color? fillColor,
    }
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        fontSize: 15,
        color: readOnly && fillColor != null ? Colors.black54 : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: fillColor ?? Colors.white,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.black38, size: 20) : null,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.black38, size: 20) : null,
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
