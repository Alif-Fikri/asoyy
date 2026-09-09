import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';

class NotificationMuteRepository {
  static const _key = 'notif_muted_ids';

  Box get _box => Hive.box(AppConstants.settingsBox);

  Set<String> getMuted() {
    final raw = _box.get(_key);
    if (raw is List) return raw.whereType<String>().toSet();
    return {};
  }

  bool isMuted(String id) => getMuted().contains(id);

  Future<void> setMuted(String id, bool muted) async {
    final current = getMuted();
    if (muted) {
      current.add(id);
    } else {
      current.remove(id);
    }
    await _box.put(_key, current.toList());
  }
}
