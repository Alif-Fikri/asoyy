import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/auth_throttle.dart';

class AuthThrottleRepository {
  static const _failuresKey = 'auth_failures';
  static const _lockedUntilKey = 'auth_locked_until';

  Box get _box => Hive.box(AppConstants.settingsBox);

  int get failures {
    final raw = _box.get(_failuresKey);
    return raw is int && raw > 0 ? raw : 0;
  }

  DateTime? get lockedUntil {
    final raw = _box.get(_lockedUntilKey);
    if (raw is! int) return null;
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  Duration remainingLockout(DateTime now) {
    final until = lockedUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isLockedOut(DateTime now) => remainingLockout(now) > Duration.zero;

  Future<Duration> registerFailure(DateTime now) async {
    final next = failures + 1;
    await _box.put(_failuresKey, next);
    final lockout = lockoutForFailures(next);
    if (lockout > Duration.zero) {
      await _box.put(
        _lockedUntilKey,
        now.add(lockout).millisecondsSinceEpoch,
      );
    }
    return lockout;
  }

  Future<void> reset() async {
    await _box.delete(_failuresKey);
    await _box.delete(_lockedUntilKey);
  }
}
