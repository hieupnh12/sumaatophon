import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/address.dart';
import '../bloc/address_bloc.dart';
import '../widgets/address_card.dart';
import 'address_form_page.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  @override
  void initState() {
    super.initState();
    context.read<AddressBloc>().add(LoadAddressesEvent());
  }

  void _showDeleteConfirmDialog(BuildContext context, String id, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(context.tr('address_delete_confirm_title')),
          content: Text(context.tr('address_delete_confirm_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AddressBloc>().add(DeleteAddressEvent(id));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.trRead('address_delete_success'))),
                );
              },
              child: Text(context.tr('address_btn_delete'), style: const TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        title: Text(context.tr('address_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BlocConsumer<AddressBloc, AddressState>(
        listener: (context, state) {
          if (state is AddressActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.message}'), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is AddressLoading) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          List<Address>? displayAddresses;
          bool isRefreshing = false;
          
          if (state is AddressLoaded) {
            displayAddresses = state.addresses;
            isRefreshing = state.isRefreshing;
          } else if (state is AddressActionFailure) {
            displayAddresses = state.previousAddresses;
          }

          if (displayAddresses != null) {
            if (displayAddresses.isEmpty) {
              return _buildEmptyState(context, isDark);
            }
            
            return Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayAddresses.length,
                  itemBuilder: (context, index) {
                    final address = displayAddresses![index];
                    return AddressCard(
                      address: address,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddressFormPage(addressToEdit: address),
                          ),
                        );
                      },
                      onDelete: () => _showDeleteConfirmDialog(context, address.id, isDark),
                    );
                  },
                ),
                if (isRefreshing)
                  Positioned.fill(
                    child: Container(
                      color: isDark ? Colors.black45 : Colors.white60,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            );
          } else if (state is AddressError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Không thể tải dữ liệu:\n${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<AddressBloc>().add(LoadAddressesEvent()),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressFormPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Text(
              context.tr('address_add_btn'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/address_empty.png',
              height: 200,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.location_off_rounded,
                size: 100,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('address_empty_title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('address_empty_desc'),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
