import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/language_cubit.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_vi.dart';

class AppLocalizations {
  static const Map<String, Map<String, String>> _localizedValues = {
    'vi': viLocalizations,
    'en': enLocalizations,
    'ja': jaLocalizations,
  };

  static String translate(String key, String langCode) {
    return _localizedValues[langCode]?[key] ?? key;
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    final langCode = watch<LanguageCubit>().state;
    return AppLocalizations.translate(key, langCode);
  }

  String trRead(String key) {
    final langCode = read<LanguageCubit>().state;
    return AppLocalizations.translate(key, langCode);
  }
}
