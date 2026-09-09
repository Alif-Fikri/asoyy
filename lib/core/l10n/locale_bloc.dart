import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';

class LocaleBloc extends Cubit<Locale> {
  LocaleBloc() : super(_load());

  static const _key = 'locale';

  static Locale _load() {
    final code = Hive.box(AppConstants.settingsBox)
        .get(_key, defaultValue: 'id') as String;
    return Locale(code == 'en' ? 'en' : 'id');
  }

  void setLocale(Locale locale) {
    Hive.box(AppConstants.settingsBox).put(_key, locale.languageCode);
    emit(locale);
  }

  void toggle() {
    setLocale(state.languageCode == 'id'
        ? const Locale('en')
        : const Locale('id'));
  }
}
