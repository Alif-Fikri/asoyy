import 'package:flutter/material.dart';
import 'app_strings.dart';
import 'strings_en.dart';
import 'strings_id.dart';

class NexusLocalizations {
  final AppStrings strings;
  final Locale locale;

  NexusLocalizations(this.locale) : strings = _resolveStrings(locale);

  static AppStrings _resolveStrings(Locale locale) {
    return locale.languageCode == 'id' ? StringsId() : StringsEn();
  }

  static NexusLocalizations of(BuildContext context) {
    return Localizations.of<NexusLocalizations>(context, NexusLocalizations)!;
  }

  static const delegate = _NexusLocalizationsDelegate();
}

class _NexusLocalizationsDelegate
    extends LocalizationsDelegate<NexusLocalizations> {
  const _NexusLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'id'].contains(locale.languageCode);

  @override
  Future<NexusLocalizations> load(Locale locale) async =>
      NexusLocalizations(locale);

  @override
  bool shouldReload(_NexusLocalizationsDelegate old) => false;
}

extension LocalizationContext on BuildContext {
  AppStrings get strings => NexusLocalizations.of(this).strings;
  Locale get currentLocale => NexusLocalizations.of(this).locale;
}
