import 'dart:convert';

import 'package:flutter/services.dart';

class CapturedNotification {
  final String packageName;
  final String title;
  final String text;
  final int postTime;

  const CapturedNotification({
    required this.packageName,
    required this.title,
    required this.text,
    required this.postTime,
  });

  factory CapturedNotification.fromJson(Map<String, dynamic> json) => CapturedNotification(
        packageName: json['packageName'] as String? ?? '',
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
        postTime: (json['postTime'] as num?)?.toInt() ?? 0,
      );
}

class NotificationCaptureService {
  static const _channel = MethodChannel('id.co.alchemist.beres/notification_capture');

  Future<bool> isAccessGranted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessGranted');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> openAccessSettings() async {
    try {
      await _channel.invokeMethod<void>('openAccessSettings');
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<List<CapturedNotification>> drainCaptured() async {
    try {
      final raw = await _channel.invokeMethod<String>('drainCaptured');
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => CapturedNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    } on FormatException {
      return const [];
    }
  }
}
