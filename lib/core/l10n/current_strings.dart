import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import 'app_strings.dart';
import 'strings_en.dart';
import 'strings_id.dart';

AppStrings currentStrings() {
  final code = Hive.isBoxOpen(AppConstants.settingsBox)
      ? Hive.box(AppConstants.settingsBox).get('locale', defaultValue: 'en') as String
      : 'en';
  return code == 'id' ? StringsId() : StringsEn();
}
