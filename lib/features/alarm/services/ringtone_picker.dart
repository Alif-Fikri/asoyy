import 'package:flutter/services.dart';

class RingtonePickResult {
  final String relativePath;
  final String name;

  const RingtonePickResult({required this.relativePath, required this.name});
}

class RingtonePicker {
  static const _channel = MethodChannel('id.co.alchemist.beres/ringtone');

  Future<RingtonePickResult?> pick() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'pickRingtone',
      );
      final path = result?['relativePath'] as String?;
      final name = result?['name'] as String?;
      if (path == null || name == null) return null;
      return RingtonePickResult(relativePath: path, name: name);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
