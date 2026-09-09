import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';

Future<void> shareCsvSnackBar(BuildContext context, File file) async {
  final isId = context.currentLocale.languageCode == 'id';
  final screenSize = MediaQuery.of(context).size;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(isId ? 'CSV disimpan' : 'CSV saved'),
      action: SnackBarAction(
        label: isId ? 'Bagikan' : 'Share',
        onPressed: () => Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv')],
          sharePositionOrigin: Rect.fromLTWH(
            0,
            screenSize.height - 100,
            screenSize.width,
            100,
          ),
        ),
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}
