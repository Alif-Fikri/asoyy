import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocaleBloc extends Cubit<Locale> {
  LocaleBloc() : super(const Locale('id'));

  void setLocale(Locale locale) => emit(locale);

  void toggle() {
    emit(state.languageCode == 'id'
        ? const Locale('en')
        : const Locale('id'));
  }
}
