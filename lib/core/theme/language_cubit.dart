import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageCubit extends Cubit<String> {
  final FlutterSecureStorage _storage;
  static const String _langKey = 'language_code';

  LanguageCubit(String initialLang, this._storage) : super(initialLang);

  void changeLanguage(String langCode) async {
    await _storage.write(key: _langKey, value: langCode);
    emit(langCode);
  }
}
