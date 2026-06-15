import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  // Bắt đầu với ThemeMode.system để tôn trọng cài đặt hệ thống
  // Nhưng cho phép người dùng thay đổi thủ công.
  ThemeCubit() : super(ThemeMode.system);

  void toggleTheme() {
    if (state == ThemeMode.light) {
      emit(ThemeMode.dark);
    } else if (state == ThemeMode.dark) {
      emit(ThemeMode.light);
    } else {
      // Nếu đang là system, dựa vào brightness hiện tại của device để switch
      // Nhưng do ở trong Cubit không có context để check MediaQuery, 
      // ta có thể mặc định đổi sang dark hoặc light tùy ý, ở đây mặc định sang Dark.
      emit(ThemeMode.dark);
    }
  }

  void setTheme(ThemeMode mode) => emit(mode);
}
