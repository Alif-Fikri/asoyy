import 'package:hive/hive.dart';
import '../constants/app_constants.dart';

class TourPreferences {
  static const _seenKey = 'tour_seen';

  Box get _box => Hive.box(AppConstants.settingsBox);

  bool get hasSeen => _box.get(_seenKey) == true;

  bool get shouldShowOnLaunch => !hasSeen;

  Future<void> markSeen() => _box.put(_seenKey, true);

  Future<void> reset() => _box.delete(_seenKey);
}
