import 'package:flutter_bloc/flutter_bloc.dart';

class Store {
  final int id;
  final String name;
  final String address;
  final String distance;
  final String openTime;
  final double topPos;
  final double leftPos;
  final String phone;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.openTime,
    required this.topPos,
    required this.leftPos,
    required this.phone,
  });
}

abstract class StoreLocatorBlocEvent {}

class LoadStoresEvent extends StoreLocatorBlocEvent {}

class SelectStoreEvent extends StoreLocatorBlocEvent {
  final int storeId;
  SelectStoreEvent(this.storeId);
}

class StoreLocatorBlocState {
  final List<Store> stores;
  final int selectedStoreId;

  StoreLocatorBlocState({
    this.stores = const [],
    this.selectedStoreId = 1,
  });

  StoreLocatorBlocState copyWith({
    List<Store>? stores,
    int? selectedStoreId,
  }) {
    return StoreLocatorBlocState(
      stores: stores ?? this.stores,
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
    );
  }
}

class StoreLocatorBloc extends Bloc<StoreLocatorBlocEvent, StoreLocatorBlocState> {
  StoreLocatorBloc() : super(StoreLocatorBlocState()) {
    on<LoadStoresEvent>((event, emit) {
      final stores = [
        Store(
          id: 1,
          name: 'phoneShop Premium Q1',
          address: '68 Lê Lợi, P. Bến Nghé, Quận 1, TP.HCM',
          distance: '1.2 km',
          openTime: '08:00 - 22:00',
          phone: '028 1234 5678',
          topPos: 0.3,
          leftPos: 0.4,
        ),
        Store(
          id: 2,
          name: 'phoneShop Mega Mall Q2',
          address: '159 Xa lộ Hà Nội, Thảo Điền, Quận 2, TP.HCM',
          distance: '5.5 km',
          openTime: '09:00 - 21:30',
          phone: '028 2345 6789',
          topPos: 0.25,
          leftPos: 0.7,
        ),
        Store(
          id: 3,
          name: 'phoneShop Hub Q7',
          address: '1058 Nguyễn Văn Linh, Tân Phong, Quận 7, TP.HCM',
          distance: '8.1 km',
          openTime: '08:00 - 22:00',
          phone: '028 3456 7890',
          topPos: 0.7,
          leftPos: 0.5,
        ),
      ];
      emit(state.copyWith(stores: stores, selectedStoreId: 1));
    });

    on<SelectStoreEvent>((event, emit) {
      emit(state.copyWith(selectedStoreId: event.storeId));
    });
  }
}
