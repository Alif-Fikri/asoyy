import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(_load());

  static ThemeMode _load() {
    final box = Hive.box(AppConstants.settingsBox);
    return box.get('theme_mode', defaultValue: 'dark') == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    Hive.box(AppConstants.settingsBox)
        .put('theme_mode', next == ThemeMode.dark ? 'dark' : 'light');
    emit(next);
  }
}
