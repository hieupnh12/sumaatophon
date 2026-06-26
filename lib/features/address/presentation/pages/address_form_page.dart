import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../main.dart'; // To access `sl`
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../../data/models/location_models.dart';
import '../bloc/address_bloc.dart';
import '../widgets/location_picker_sheet.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AddressFormPage extends StatefulWidget {
  final Address? addressToEdit;

  const AddressFormPage({super.key, this.addressToEdit});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();

  Province? _selectedProvince;
  Ward? _selectedWard;

  String _selectedType = 'home';
  bool _isDefault = false;

  bool _isLoadingLocations = false;

  @override
  void initState() {
    super.initState();
    if (widget.addressToEdit != null) {
      final addr = widget.addressToEdit!;
      _streetController.text = addr.street;
      _receiverNameController.text = addr.receiverName ?? '';
      _receiverPhoneController.text = addr.receiverPhone ?? '';
      _selectedType = addr.type;
      _isDefault = addr.isDefault;
      _selectedProvince = Province(code: -1, name: addr.province);
      _selectedWard = Ward(code: -1, name: addr.ward, provinceCode: -1);
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_receiverNameController.text.trim().isEmpty || _receiverPhoneController.text.trim().isEmpty) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthenticatedState) {
          if (_receiverNameController.text.trim().isEmpty) {
            _receiverNameController.text = authState.user.name;
          }
          if (_receiverPhoneController.text.trim().isEmpty) {
            _receiverPhoneController.text = authState.user.phone ?? '';
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _streetController.text = '';
    _streetController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectProvince() async {
    setState(() => _isLoadingLocations = true);
    try {
      final repo = sl<AddressRepository>();
      final provinces = await repo.getProvinces();
      setState(() => _isLoadingLocations = false);

      if (!mounted) return;

      final Province? result = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => LocationPickerSheet<Province>(
          title: ctx.tr('address_select_province'),
          items: provinces,
          getName: (p) => p.name,
          selectedItem: _selectedProvince?.code != -1 ? _selectedProvince : null,
        ),
      );

      if (result != null && result.code != _selectedProvince?.code) {
        setState(() {
          _selectedProvince = result;
          _selectedWard = null;
        });
      }
    } catch (e) {
      setState(() => _isLoadingLocations = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading provinces: $e')));
    }
  }

  Future<void> _selectWard() async {
    if (_selectedProvince == null || _selectedProvince!.code == -1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.trRead('address_select_province'))));
      return;
    }

    setState(() => _isLoadingLocations = true);
    try {
      final repo = sl<AddressRepository>();
      final wards = await repo.getWards(_selectedProvince!.code);
      setState(() => _isLoadingLocations = false);

      if (!mounted) return;

      final Ward? result = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => LocationPickerSheet<Ward>(
          title: ctx.tr('address_select_ward'),
          items: wards,
          getName: (w) => w.name,
          selectedItem: _selectedWard?.code != -1 ? _selectedWard : null,
        ),
      );

      if (result != null) {
        setState(() {
          _selectedWard = result;
        });
      }
    } catch (e) {
      setState(() => _isLoadingLocations = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading wards: $e')));
    }
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      if (_selectedProvince == null || _selectedWard == null ||
          _selectedProvince!.name.isEmpty || _selectedWard!.name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn đầy đủ địa chỉ giao hàng bằng cách bấm vào các ô Tỉnh, Xã')),
        );
        return;
      }

      final address = Address(
        id: widget.addressToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        province: _selectedProvince!.name,
        ward: _selectedWard!.name,
        street: _streetController.text.trim(),
        type: _selectedType,
        isDefault: _isDefault,
        receiverName: _receiverNameController.text.trim().isNotEmpty ? _receiverNameController.text.trim() : null,
        receiverPhone: _receiverPhoneController.text.trim().isNotEmpty ? _receiverPhoneController.text.trim() : null,
      );

      if (widget.addressToEdit != null) {
        context.read<AddressBloc>().add(UpdateAddressEvent(address));
      } else {
        context.read<AddressBloc>().add(AddAddressEvent(address));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('address_save_success'))),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.addressToEdit != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        title: Text(
          isEditing ? context.tr('address_edit_title') : context.tr('address_add_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context.tr('address_receiver_info'), isDark),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _receiverNameController,
                    label: context.tr('address_name_label'),
                    icon: Icons.person_outline,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _receiverPhoneController,
                    label: context.tr('address_phone_label'),
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isDark: isDark,
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        // Regex cho số điện thoại VN: bắt đầu bằng 0, có 10 chữ số
                        if (!RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$').hasMatch(val.trim())) {
                          return 'Số điện thoại không hợp lệ (VD: 0912345678)';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle(context.tr('address_shipping_info'), isDark),
                  const SizedBox(height: 12),
                  _buildSelectorField(
                    label: context.tr('address_province_label'),
                    value: _selectedProvince?.name ?? context.tr('address_select_province'),
                    isDark: isDark,
                    onTap: _selectProvince,
                    isSelected: _selectedProvince != null,
                  ),
                  const SizedBox(height: 16),
                  _buildSelectorField(
                    label: context.tr('address_ward_label'),
                    value: _selectedWard?.name ?? context.tr('address_select_ward'),
                    isDark: isDark,
                    onTap: _selectWard,
                    isSelected: _selectedWard != null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _streetController,
                    label: context.tr('address_street_label'),
                    hint: context.tr('address_specific_hint'),
                    isDark: isDark,
                    validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập địa chỉ cụ thể' : null,
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle(context.tr('address_type_label'), isDark),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeButton(
                          icon: Icons.home_rounded,
                          label: context.tr('address_type_home'),
                          value: 'home',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTypeButton(
                          icon: Icons.business_rounded,
                          label: context.tr('address_type_office'),
                          value: 'office',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  SwitchListTile(
                    title: Text(context.tr('address_set_default'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    value: _isDefault,
                    onChanged: (val) => setState(() => _isDefault = val),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 100), // Padding for bottom button
                ],
              ),
            ),
          ),
          if (_isLoadingLocations)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _saveAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Text(
              isEditing ? context.tr('address_edit_title') : context.tr('address_add_btn'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorField({
    required String label,
    required String value,
    required bool isDark,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected 
                        ? (isDark ? Colors.white : Colors.black) 
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ),
              ],
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final isSelected = _selectedType == value;
    return InkWell(
      onTap: () => setState(() => _selectedType = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : (isDark ? Colors.white : Colors.black),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
