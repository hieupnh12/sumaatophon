part of 'address_bloc.dart';

abstract class AddressEvent extends Equatable {
  const AddressEvent();

  @override
  List<Object?> get props => [];
}

class LoadAddressesEvent extends AddressEvent {}

class AddAddressEvent extends AddressEvent {
  final Address address;

  const AddAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class UpdateAddressEvent extends AddressEvent {
  final Address address;

  const UpdateAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class DeleteAddressEvent extends AddressEvent {
  final String id;

  const DeleteAddressEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SetDefaultAddressEvent extends AddressEvent {
  final String id;

  const SetDefaultAddressEvent(this.id);

  @override
  List<Object?> get props => [id];
}
