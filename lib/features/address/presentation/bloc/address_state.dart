part of 'address_bloc.dart';

abstract class AddressState extends Equatable {
  const AddressState();

  @override
  List<Object?> get props => [];
}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {}

class AddressLoaded extends AddressState {
  final List<Address> addresses;
  final bool isRefreshing;

  const AddressLoaded({
    required this.addresses,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [addresses, isRefreshing];
}

class AddressError extends AddressState {
  final String message;

  const AddressError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AddressActionFailure extends AddressState {
  final String message;
  final List<Address> previousAddresses;

  const AddressActionFailure({
    required this.message,
    required this.previousAddresses,
  });

  @override
  List<Object?> get props => [message, previousAddresses];
}
