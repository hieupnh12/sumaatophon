import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageCubit extends Cubit<String> {
  // Default language is 'vi'
  LanguageCubit() : super('vi');

  void changeLanguage(String langCode) {
    emit(langCode);
  }
}
