import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/store_entity.dart';
import '../../domain/repositories/store_repository.dart';

abstract class StoreLocatorEvent extends Equatable {
  const StoreLocatorEvent();

  @override
  List<Object?> get props => [];
}

class LoadStoresEvent extends StoreLocatorEvent {
  const LoadStoresEvent();
}

class SelectStoreEvent extends StoreLocatorEvent {
  final String storeId;

  const SelectStoreEvent(this.storeId);

  @override
  List<Object?> get props => [storeId];
}

abstract class StoreLocatorState extends Equatable {
  const StoreLocatorState();

  @override
  List<Object?> get props => [];
}

class StoreLocatorInitial extends StoreLocatorState {}

class StoreLocatorLoading extends StoreLocatorState {}

class StoreLocatorLoaded extends StoreLocatorState {
  final List<StoreEntity> stores;
  final String? selectedStoreId;
  final double? userLatitude;
  final double? userLongitude;
  final bool locationDenied;

  const StoreLocatorLoaded({
    required this.stores,
    this.selectedStoreId,
    this.userLatitude,
    this.userLongitude,
    this.locationDenied = false,
  });

  StoreLocatorLoaded copyWith({
    List<StoreEntity>? stores,
    String? selectedStoreId,
    double? userLatitude,
    double? userLongitude,
    bool? locationDenied,
  }) {
    return StoreLocatorLoaded(
      stores: stores ?? this.stores,
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      locationDenied: locationDenied ?? this.locationDenied,
    );
  }

  @override
  List<Object?> get props => [
        stores,
        selectedStoreId,
        userLatitude,
        userLongitude,
        locationDenied,
      ];
}

class StoreLocatorEmpty extends StoreLocatorState {}

class StoreLocatorError extends StoreLocatorState {
  final String message;

  const StoreLocatorError(this.message);

  @override
  List<Object?> get props => [message];
}

class StoreLocatorBloc extends Bloc<StoreLocatorEvent, StoreLocatorState> {
  final StoreRepository repository;

  StoreLocatorBloc({required this.repository}) : super(StoreLocatorInitial()) {
    on<LoadStoresEvent>(_onLoadStores);
    on<SelectStoreEvent>(_onSelectStore);
  }

  Future<void> _onLoadStores(
    LoadStoresEvent event,
    Emitter<StoreLocatorState> emit,
  ) async {
    emit(StoreLocatorLoading());

    try {
      double? userLat;
      double? userLng;
      var locationDenied = false;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          locationDenied = true;
        }
      } else if (permission == LocationPermission.deniedForever) {
        locationDenied = true;
      }

      if (!locationDenied) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 8),
            ),
          );
          userLat = position.latitude;
          userLng = position.longitude;
        } catch (_) {
          locationDenied = true;
        }
      }

      final stores = await repository.getStores(
        latitude: userLat,
        longitude: userLng,
      );

      if (stores.isEmpty) {
        emit(StoreLocatorEmpty());
        return;
      }

      emit(
        StoreLocatorLoaded(
          stores: stores,
          selectedStoreId: stores.first.id,
          userLatitude: userLat,
          userLongitude: userLng,
          locationDenied: locationDenied,
        ),
      );
    } catch (e) {
      emit(StoreLocatorError(e.toString()));
    }
  }

  void _onSelectStore(SelectStoreEvent event, Emitter<StoreLocatorState> emit) {
    final current = state;
    if (current is! StoreLocatorLoaded) return;
    emit(current.copyWith(selectedStoreId: event.storeId));
  }
}
