import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/utils/receipt_parser.dart';

class ReceiptScanner {
  static const _channel =
      MethodChannel('id.co.alchemist.beres/text_recognition');

  final ImagePicker _picker = ImagePicker();

  Future<ReceiptScan?> scan({required bool fromCamera}) async {
    final image = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return null;
    return parseReceipt(groupIntoVisualRows(await recognizeLines(image.path)));
  }

  static Future<List<ScannedLine>> recognizeLines(String path) async {
    final raw = await _channel.invokeListMethod<dynamic>(
      'recognize',
      {'path': path},
    );
    if (raw == null) return const [];

    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((entry) => ScannedLine(
              text: entry['text'] as String? ?? '',
              top: (entry['top'] as num?)?.toDouble() ?? 0,
              bottom: (entry['bottom'] as num?)?.toDouble() ?? 0,
              left: (entry['left'] as num?)?.toDouble() ?? 0,
            ))
        .where((line) => line.text.isNotEmpty)
        .toList(growable: false);
  }
}
