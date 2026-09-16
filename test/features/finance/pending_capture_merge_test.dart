import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/domain/entities/pending_capture.dart';
import 'package:asoyy/features/finance/domain/utils/pending_capture_merge.dart';

PendingCapture _capture(String id, {double amount = 1000}) => PendingCapture(
      id: id,
      description: 'desc-$id',
      amount: amount,
      type: TransactionType.income,
      postTime: 1,
    );

void main() {
  group('mergeNewCaptures', () {
    test('adds new captures to an empty list', () {
      final result = mergeNewCaptures([], [_capture('a')]);
      expect(result.map((c) => c.id), ['a']);
    });

    test('does not duplicate a capture with the same id', () {
      final result = mergeNewCaptures([_capture('a')], [_capture('a')]);
      expect(result.length, 1);
    });

    test('keeps existing captures and appends only the genuinely new ones', () {
      final result = mergeNewCaptures(
        [_capture('a'), _capture('b')],
        [_capture('b'), _capture('c')],
      );
      expect(result.map((c) => c.id).toList(), ['a', 'b', 'c']);
    });
  });

  group('captureId', () {
    test('is stable for the same package and postTime', () {
      expect(
        captureId(packageName: 'com.bca.mybca', postTime: 123),
        captureId(packageName: 'com.bca.mybca', postTime: 123),
      );
    });

    test('differs when the postTime differs', () {
      expect(
        captureId(packageName: 'com.bca.mybca', postTime: 123),
        isNot(captureId(packageName: 'com.bca.mybca', postTime: 124)),
      );
    });
  });
}
