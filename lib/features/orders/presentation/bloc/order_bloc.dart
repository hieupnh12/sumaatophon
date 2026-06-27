import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_detail.dart';
import '../../domain/repositories/order_repository.dart';

// --- EVENTS ---
abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrdersEvent extends OrderEvent {
  final int customerId;
  const LoadOrdersEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class LoadOrderDetailEvent extends OrderEvent {
  final int orderId;
  final int customerId;

  const LoadOrderDetailEvent(this.orderId, this.customerId);

  @override
  List<Object?> get props => [orderId, customerId];
}

// --- STATES ---
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrdersLoaded extends OrderState {
  final List<Order> orders;
  const OrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderDetailLoaded extends OrderState {
  final OrderDetail orderDetail;
  const OrderDetailLoaded(this.orderDetail);

  @override
  List<Object?> get props => [orderDetail];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- BLOC ---
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository repository;

  OrderBloc({required this.repository}) : super(OrderInitial()) {
    on<LoadOrdersEvent>(_onLoadOrders);
    on<LoadOrderDetailEvent>(_onLoadOrderDetail);
  }

  Future<void> _onLoadOrders(LoadOrdersEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final orders = await repository.getOrders(event.customerId);
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onLoadOrderDetail(LoadOrderDetailEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final detail = await repository.getOrderDetail(event.orderId, event.customerId);
      emit(OrderDetailLoaded(detail));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }
}
