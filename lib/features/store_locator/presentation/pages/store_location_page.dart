import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/store_entity.dart';
import '../bloc/store_locator_bloc.dart';
import '../utils/store_locator_actions.dart';
import '../widgets/store_card.dart';

class StoreLocationPage extends StatefulWidget {
  const StoreLocationPage({super.key});

  @override
  State<StoreLocationPage> createState() => _StoreLocationPageState();
}

class _StoreLocationPageState extends State<StoreLocationPage> {
  GoogleMapController? _mapController;
  late final PageController _pageController;
  bool _didRequestLoad = false;
  bool _locationDeniedShown = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _ensureStoresLoaded() {
    if (_didRequestLoad) return;
    _didRequestLoad = true;
    context.read<StoreLocatorBloc>().add(const LoadStoresEvent());
  }

  Future<void> _animateToStore(StoreEntity store) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(store.latitude, store.longitude),
        14,
      ),
    );
  }

  Set<Marker> _buildMarkers(StoreLocatorLoaded state) {
    return state.stores.map((store) {
      final isSelected = store.id == state.selectedStoreId;
      return Marker(
        markerId: MarkerId(store.id),
        position: LatLng(store.latitude, store.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: store.name,
          snippet: store.address,
        ),
        onTap: () {
          context.read<StoreLocatorBloc>().add(SelectStoreEvent(store.id));
        },
      );
    }).toSet();
  }

  CameraPosition _initialCamera(StoreLocatorLoaded state) {
    final selected = state.stores.firstWhere(
      (s) => s.id == state.selectedStoreId,
      orElse: () => state.stores.first,
    );

    if (state.userLatitude != null && state.userLongitude != null) {
      return CameraPosition(
        target: LatLng(state.userLatitude!, state.userLongitude!),
        zoom: 12,
      );
    }

    return CameraPosition(
      target: LatLng(selected.latitude, selected.longitude),
      zoom: 12,
    );
  }

  Future<void> _handleCall(StoreEntity store) async {
    final ok = await callStorePhone(store.phone);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.trRead('store_locator_call_failed')),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _handleDirections(StoreEntity store) async {
    final ok = await openStoreDirections(store);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.trRead('store_locator_directions_failed')),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureStoresLoaded();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('store_locator_search_hint'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: BlocConsumer<StoreLocatorBloc, StoreLocatorState>(
        listenWhen: (prev, curr) {
          if (curr is! StoreLocatorLoaded) return false;
          if (prev is! StoreLocatorLoaded) return true;
          return prev.selectedStoreId != curr.selectedStoreId;
        },
        listener: (context, state) {
          if (state is! StoreLocatorLoaded) return;

          if (state.locationDenied && !_locationDeniedShown) {
            _locationDeniedShown = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.trRead('store_locator_location_denied'))),
            );
          }

          final index = state.stores.indexWhere((s) => s.id == state.selectedStoreId);
          if (index != -1 && _pageController.hasClients) {
            final current = _pageController.page?.round();
            if (current != index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }

          final selected = state.stores.firstWhere(
            (s) => s.id == state.selectedStoreId,
            orElse: () => state.stores.first,
          );
          _animateToStore(selected);
        },
        builder: (context, state) {
          if (state is StoreLocatorLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StoreLocatorError) {
            return _buildMessageState(
              context,
              icon: Icons.error_outline_rounded,
              title: context.tr('store_locator_error'),
              subtitle: state.message,
              actionLabel: context.tr('store_locator_retry'),
              onAction: () => context.read<StoreLocatorBloc>().add(const LoadStoresEvent()),
              isDark: isDark,
            );
          }

          if (state is StoreLocatorEmpty) {
            return _buildMessageState(
              context,
              icon: Icons.store_mall_directory_outlined,
              title: context.tr('store_locator_empty_title'),
              subtitle: context.tr('store_locator_empty_desc'),
              actionLabel: context.tr('store_locator_retry'),
              onAction: () => context.read<StoreLocatorBloc>().add(const LoadStoresEvent()),
              isDark: isDark,
            );
          }

          if (state is! StoreLocatorLoaded) {
            return const SizedBox.shrink();
          }

          return Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: _initialCamera(state),
                  markers: _buildMarkers(state),
                  myLocationEnabled: !kIsWeb && state.userLatitude != null,
                  myLocationButtonEnabled: !kIsWeb,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    final selected = state.stores.firstWhere(
                      (s) => s.id == state.selectedStoreId,
                      orElse: () => state.stores.first,
                    );
                    _animateToStore(selected);
                  },
                ),
              ),
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                height: 220,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: state.stores.length,
                  onPageChanged: (index) {
                    context.read<StoreLocatorBloc>().add(
                          SelectStoreEvent(state.stores[index].id),
                        );
                  },
                  itemBuilder: (context, index) {
                    final store = state.stores[index];
                    return StoreCard(
                      store: store,
                      isSelected: store.id == state.selectedStoreId,
                      onCall: () => _handleCall(store),
                      onDirections: () => _handleDirections(store),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
