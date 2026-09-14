import 'dart:io';
import 'dart:ui' as ui;

import 'package:asoyy/features/finance/domain/utils/receipt_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

const _receiptLines = [
  'INDOMARET',
  'JL MERDEKA NO 12',
  '',
  'INDOMILK 190ML          13.000',
  'ROTI TAWAR              17.500',
  'SUB TOTAL               30.500',
  'DISKON                   1.000',
  'TOTAL                   29.500',
  'TUNAI                   50.000',
  'KEMBALI                 20.500',
  '14-09-2026 11:05',
];

Future<File> _renderReceipt() async {
  const width = 900.0;
  const lineHeight = 56.0;
  final height = lineHeight * _receiptLines.length + 80;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width, height),
    Paint()..color = const Color(0xFFFFFFFF),
  );

  var y = 40.0;
  for (final line in _receiptLines) {
    if (line.isNotEmpty) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontFamily: 'monospace',
        fontSize: 34,
      ))
        ..pushStyle(ui.TextStyle(color: const Color(0xFF000000)))
        ..addText(line);
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: width - 80));
      canvas.drawParagraph(paragraph, Offset(40, y));
    }
    y += lineHeight;
  }

  final image = await recorder
      .endRecording()
      .toImage(width.toInt(), height.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/receipt_fixture.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  return file;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the text recogniser is available on this platform',
      (tester) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    await recognizer.close();
  });

  testWidgets('reads a rendered receipt into a usable scan', (tester) async {
    final file = await _renderReceipt();
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(file.path));

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
      expect(scanned, isNotEmpty, reason: 'the recogniser read nothing at all');

      final scan = parseReceipt(groupIntoVisualRows(scanned));
      expect(scan.total, 29500, reason: 'the TOTAL line, not the subtotal');
      expect(scan.total, isNot(50000), reason: 'TUNAI is cash tendered');
      expect(scan.category, 'Belanja');
      expect(scan.merchant, contains('INDOMARET'));
    } finally {
      await recognizer.close();
    }
  });
}
