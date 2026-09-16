import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/domain/utils/bank_notification_parser.dart';

void main() {
  group('isKnownBankPackage', () {
    test('matches an exact known package', () {
      expect(isKnownBankPackage('id.co.bri.brimo'), isTrue);
    });

    test('matches SeaBank by its generic substring', () {
      expect(isKnownBankPackage('com.seabank.mobile.id'), isTrue);
    });

    test('matches a package that contains a known one as a substring', () {
      expect(isKnownBankPackage('com.gojek.app.debug'), isTrue);
    });

    test('rejects an unrelated package', () {
      expect(isKnownBankPackage('com.whatsapp'), isFalse);
    });
  });

  group('parseBankNotification', () {
    test('reads an incoming transfer as income', () {
      final result = parseBankNotification(
        title: 'BCA mobile',
        text: 'Anda menerima Rp 500.000 dari BUDI SANTOSO',
      );
      expect(result, isNotNull);
      expect(result!.type, TransactionType.income);
      expect(result.amount, 500000);
    });

    test('reads a successful payment as expense', () {
      final result = parseBankNotification(
        title: 'GoPay',
        text: 'Pembayaran berhasil sebesar Rp25.000 ke Indomaret',
      );
      expect(result, isNotNull);
      expect(result!.type, TransactionType.expense);
      expect(result.amount, 25000);
    });

    test('reads an outgoing transfer as expense', () {
      final result = parseBankNotification(
        title: 'Mandiri Livin',
        text: 'Anda mengirim Rp1.200.000 ke rekening 123456',
      );
      expect(result, isNotNull);
      expect(result!.type, TransactionType.expense);
      expect(result.amount, 1200000);
    });

    test('reads a debit card purchase as expense', () {
      final result = parseBankNotification(
        title: 'BRImo',
        text: 'Debit kartu Rp150.000 di TOKO ABC berhasil',
      );
      expect(result!.type, TransactionType.expense);
      expect(result.amount, 150000);
    });

    test('returns null when there is no amount', () {
      final result = parseBankNotification(
        title: 'BCA mobile',
        text: 'Anda menerima transfer dari BUDI SANTOSO',
      );
      expect(result, isNull);
    });

    test('returns null when the direction cannot be determined', () {
      final result = parseBankNotification(
        title: 'Some App',
        text: 'Your balance is Rp500.000',
      );
      expect(result, isNull);
    });

    test('returns null when both directions match (ambiguous)', () {
      final result = parseBankNotification(
        title: 'BCA mobile',
        text: 'Anda menerima Rp500.000, setelah membayar Rp100.000',
      );
      expect(result, isNull);
    });

    test('returns null for a zero amount', () {
      final result = parseBankNotification(
        title: 'BCA mobile',
        text: 'Anda menerima Rp0 dari testing',
      );
      expect(result, isNull);
    });

    test('falls back to the notification text when the title is blank', () {
      final result = parseBankNotification(
        title: '',
        text: 'Anda menerima Rp10.000 dari seseorang',
      );
      expect(result!.description, 'Anda menerima Rp10.000 dari seseorang');
    });

    test('uses the title as the description when present', () {
      final result = parseBankNotification(
        title: 'DANA',
        text: 'Anda menerima Rp10.000',
      );
      expect(result!.description, 'DANA');
    });
  });
}
