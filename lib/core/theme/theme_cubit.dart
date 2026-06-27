import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final FlutterSecureStorage _storage;
  static const String _themeKey = 'theme_mode';

  ThemeCubit(ThemeMode initialMode, this._storage) : super(initialMode);

  void toggleTheme() async {
    ThemeMode nextMode;
    if (state == ThemeMode.light) {
      nextMode = ThemeMode.dark;
    } else if (state == ThemeMode.dark) {
      nextMode = ThemeMode.light;
    } else {
      nextMode = ThemeMode.dark;
    }
    
    await _storage.write(key: _themeKey, value: nextMode.name);
    emit(nextMode);
  }

  void setTheme(ThemeMode mode) async {
    await _storage.write(key: _themeKey, value: mode.name);
    emit(mode);
  }
}
