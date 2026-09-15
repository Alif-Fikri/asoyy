import 'dart:io';

import 'package:asoyy/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

const _boxConstantPattern = r'static const String (\w+Box) =';

void main() {
  group('backup coverage', () {
    test('every declared box is included in a backup', () {
      final source = File('lib/core/constants/app_constants.dart')
          .readAsStringSync();

      final declared = RegExp(_boxConstantPattern)
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toSet();

      expect(declared, isNotEmpty, reason: 'sanity: found no box constants');

      final byName = <String, String>{
        'eventsBox': AppConstants.eventsBox,
        'alarmsBox': AppConstants.alarmsBox,
        'passwordsBox': AppConstants.passwordsBox,
        'transactionsBox': AppConstants.transactionsBox,
        'settingsBox': AppConstants.settingsBox,
        'billsBox': AppConstants.billsBox,
        'debtsBox': AppConstants.debtsBox,
        'accountsBox': AppConstants.accountsBox,
        'notesBox': AppConstants.notesBox,
      };

      expect(
        declared.difference(byName.keys.toSet()),
        isEmpty,
        reason: 'a new box was added - list it here and in allDataBoxes',
      );

      for (final entry in byName.entries) {
        expect(
          AppConstants.allDataBoxes,
          contains(entry.value),
          reason: '${entry.key} would not survive a restore',
        );
      }
    });

    test('the wallet and note boxes are covered', () {
      expect(AppConstants.allDataBoxes, contains(AppConstants.accountsBox));
      expect(AppConstants.allDataBoxes, contains(AppConstants.notesBox));
    });

    test('no box is listed twice', () {
      expect(
        AppConstants.allDataBoxes.toSet().length,
        AppConstants.allDataBoxes.length,
      );
    });
  });
}
