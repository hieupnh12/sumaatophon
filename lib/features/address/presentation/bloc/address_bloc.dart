import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

part 'address_event.dart';
part 'address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final AddressRepository repository;
  final AuthBloc authBloc;

  AddressBloc({required this.repository, required this.authBloc}) : super(AddressInitial()) {
    on<LoadAddressesEvent>(_onLoadAddresses);
    on<AddAddressEvent>(_onAddAddress);
    on<UpdateAddressEvent>(_onUpdateAddress);
    on<DeleteAddressEvent>(_onDeleteAddress);
    on<SetDefaultAddressEvent>(_onSetDefaultAddress);
  }

  Future<void> _onLoadAddresses(LoadAddressesEvent event, Emitter<AddressState> emit) async {
    if (state is AddressLoaded) {
      emit(AddressLoaded(addresses: (state as AddressLoaded).addresses, isRefreshing: true));
    } else {
      emit(AddressLoading());
    }
    try {
      final authState = authBloc.state;
      if (authState is! AuthenticatedState) {
        emit(const AddressError(message: 'User not logged in'));
        return;
      }
      final customerId = authState.user.id;
      final addresses = await repository.getAddresses(customerId);
      emit(AddressLoaded(addresses: addresses));
    } catch (e) {
      if (state is AddressLoaded) {
        emit(AddressActionFailure(message: e.toString(), previousAddresses: (state as AddressLoaded).addresses));
        emit(AddressLoaded(addresses: (state as AddressLoaded).addresses));
      } else {
        emit(AddressError(message: e.toString()));
      }
    }
  }

  Future<void> _onAddAddress(AddAddressEvent event, Emitter<AddressState> emit) async {
    try {
      final authState = authBloc.state;
      if (authState is! AuthenticatedState) return;
      if (state is AddressLoaded) {
        emit(AddressLoaded(addresses: (state as AddressLoaded).addresses, isRefreshing: true));
      }
      await repository.addAddress(authState.user.id, event.address);
      add(LoadAddressesEvent());
    } catch (e) {
      if (state is AddressLoaded) {
        emit(AddressActionFailure(message: e.toString(), previousAddresses: (state as AddressLoaded).addresses));
        emit(AddressLoaded(addresses: (state as AddressLoaded).addresses));
      } else {
        emit(AddressError(message: e.toString()));
      }
    }
  }

  Future<void> _onUpdateAddress(UpdateAddressEvent event, Emitter<AddressState> emit) async {
    try {
      final authState = authBloc.state;
      if (authState is! AuthenticatedState) return;
      if (state is AddressLoaded) {
        emit(AddressLoaded(addresses: (state as AddressLoaded).addresses, isRefreshing: true));
      }
      await repository.updateAddress(authState.user.id, event.address);
      add(LoadAddressesEvent());
    } catch (e) {
      if (state is AddressLoaded) {
        emit(AddressActionFailure(message: e.toString(), previousAddresses: (state as AddressLoaded).addresses));
        emit(AddressLoaded(addresses: (state as AddressLoaded).addresses));
      } else {
        emit(AddressError(message: e.toString()));
      }
    }
  }

  Future<void> _onDeleteAddress(DeleteAddressEvent event, Emitter<AddressState> emit) async {
    try {
      final authState = authBloc.state;
      if (authState is! AuthenticatedState) return;
      if (state is AddressLoaded) {
        emit(AddressLoaded(addresses: (state as AddressLoaded).addresses, isRefreshing: true));
      }
      await repository.deleteAddress(authState.user.id, event.id);
      add(LoadAddressesEvent());
    } catch (e) {
      if (state is AddressLoaded) {
        emit(AddressActionFailure(message: e.toString(), previousAddresses: (state as AddressLoaded).addresses));
        emit(AddressLoaded(addresses: (state as AddressLoaded).addresses));
      } else {
        emit(AddressError(message: e.toString()));
      }
    }
  }

  Future<void> _onSetDefaultAddress(SetDefaultAddressEvent event, Emitter<AddressState> emit) async {
    try {
      final authState = authBloc.state;
      if (authState is! AuthenticatedState) return;
      if (state is AddressLoaded) {
        emit(AddressLoaded(addresses: (state as AddressLoaded).addresses, isRefreshing: true));
      }
      await repository.setDefaultAddress(authState.user.id, event.id);
      add(LoadAddressesEvent());
    } catch (e) {
      if (state is AddressLoaded) {
        emit(AddressActionFailure(message: e.toString(), previousAddresses: (state as AddressLoaded).addresses));
        emit(AddressLoaded(addresses: (state as AddressLoaded).addresses));
      } else {
        emit(AddressError(message: e.toString()));
      }
    }
  }
}
