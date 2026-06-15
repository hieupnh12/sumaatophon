import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationBlocEvent {}
class LoadNotificationsEvent extends NotificationBlocEvent {}

class NotificationBlocState {}

class NotificationBloc extends Bloc<NotificationBlocEvent, NotificationBlocState> {
  NotificationBloc() : super(NotificationBlocState());
}

