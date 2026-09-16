import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/services/notification_capture_service.dart';
import 'package:asoyy/features/finance/services/notification_capture_sync_service.dart';

void main() {
  group('buildPendingCaptures', () {
    test('parses the readable notifications and skips the rest', () {
      final raw = [
        const CapturedNotification(
          packageName: 'com.bca.mybca',
          title: 'BCA mobile',
          text: 'Anda menerima Rp500.000 dari BUDI',
          postTime: 1000,
        ),
        const CapturedNotification(
          packageName: 'com.gojek.app',
          title: 'GoPay',
          text: 'Saldo GoPay kamu berhasil diperbarui',
          postTime: 1001,
        ),
        const CapturedNotification(
          packageName: 'id.co.bri.brimo',
          title: 'BRImo',
          text: 'Pembayaran berhasil Rp75.000 ke Toko Kelontong',
          postTime: 1002,
        ),
      ];

      final result = buildPendingCaptures(raw);

      expect(result.length, 2);
      expect(result[0].amount, 500000);
      expect(result[0].type, TransactionType.income);
      expect(result[1].amount, 75000);
      expect(result[1].type, TransactionType.expense);
    });

    test('an empty input yields an empty output', () {
      expect(buildPendingCaptures(const []), isEmpty);
    });

    test('generates a stable id from package and postTime', () {
      final result = buildPendingCaptures([
        const CapturedNotification(
          packageName: 'com.bca.mybca',
          title: 'BCA',
          text: 'Anda menerima Rp1.000',
          postTime: 42,
        ),
      ]);
      expect(result.single.id, 'com.bca.mybca-42');
    });
  });
}
