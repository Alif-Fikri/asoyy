import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/auto_backup_schedule.dart';

class AutoBackupSettings {
  static const _enabledKey = 'auto_backup_enabled';
  static const _frequencyKey = 'auto_backup_frequency';
  static const _folderKey = 'auto_backup_folder';
  static const _lastRunKey = 'auto_backup_last_run';
  static const _lastErrorKey = 'auto_backup_last_error';
  static const _passphraseKey = 'auto_backup_passphrase';
  static const _firstSeenKey = 'backup_reminder_first_seen';
  static const _lastNaggedKey = 'backup_reminder_last_nagged';

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Box get _box => Hive.box(AppConstants.settingsBox);

  bool get enabled => _box.get(_enabledKey) == true;

  Future<void> setEnabled(bool value) => _box.put(_enabledKey, value);

  BackupFrequency get frequency =>
      frequencyFromName(_box.get(_frequencyKey) as String?);

  Future<void> setFrequency(BackupFrequency value) =>
      _box.put(_frequencyKey, value.name);

  String? get folder => _box.get(_folderKey) as String?;

  Future<void> setFolder(String? value) => value == null
      ? _box.delete(_folderKey)
      : _box.put(_folderKey, value);

  DateTime? get lastRun {
    final raw = _box.get(_lastRunKey);
    return raw is int ? DateTime.fromMillisecondsSinceEpoch(raw) : null;
  }

  Future<void> setLastRun(DateTime value) =>
      _box.put(_lastRunKey, value.millisecondsSinceEpoch);

  DateTime ensureFirstSeen() {
    final raw = _box.get(_firstSeenKey);
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    final now = DateTime.now();
    _box.put(_firstSeenKey, now.millisecondsSinceEpoch);
    return now;
  }

  DateTime? get lastNagged {
    final raw = _box.get(_lastNaggedKey);
    return raw is int ? DateTime.fromMillisecondsSinceEpoch(raw) : null;
  }

  Future<void> setLastNagged(DateTime value) =>
      _box.put(_lastNaggedKey, value.millisecondsSinceEpoch);

  String? get lastError => _box.get(_lastErrorKey) as String?;

  Future<void> setLastError(String? value) => value == null
      ? _box.delete(_lastErrorKey)
      : _box.put(_lastErrorKey, value);

  Future<String?> readPassphrase() async {
    try {
      return await _storage.read(key: _passphraseKey);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> writePassphrase(String value) async {
    await _storage.write(key: _passphraseKey, value: value);
  }

  Future<void> clearPassphrase() async {
    try {
      await _storage.delete(key: _passphraseKey);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
