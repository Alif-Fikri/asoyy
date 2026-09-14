import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/utils/receipt_parser.dart';

class ReceiptScanner {
  final ImagePicker _picker = ImagePicker();

  Future<ReceiptScan?> scan({required bool fromCamera}) async {
    final image = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(image.path));
      final scanned = <ScannedLine>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final box = line.boundingBox;
          scanned.add(ScannedLine(
            text: line.text,
            top: box.top.toDouble(),
            bottom: box.bottom.toDouble(),
            left: box.left.toDouble(),
          ));
        }
      }
      return parseReceipt(groupIntoVisualRows(scanned));
    } finally {
      await recognizer.close();
    }
  }
}
