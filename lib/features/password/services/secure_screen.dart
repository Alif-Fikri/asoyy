import 'package:flutter/services.dart';

class SecureScreen {
  static const _channel =
      MethodChannel('id.co.alchemist.beres/secure_screen');

  static Future<void> enable() => _invoke('enable');

  static Future<void> disable() => _invoke('disable');

  static Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
