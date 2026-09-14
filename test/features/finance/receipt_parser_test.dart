import 'package:asoyy/features/finance/domain/utils/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const spbu = [
  'SPBU 34.12708',
  'Jl. Raya Bogor KM 30',
  'PERTAMINA',
  '14/09/2026 10:22',
  'Pompa/Nozzle : 03/2',
  'Produk : Pertamax',
  'Harga/Liter : 13.500',
  'Volume : 3,70 L',
  'Total : 50.000',
  'Terima kasih',
];

const indomaret = [
  'INDOMARET',
  'JL MERDEKA NO 12',
  'NPWP : 01.234.567.8-901.000',
  '',
  'INDOMILK 190ML       2 x 6.500   13.000',
  'ROTI TAWAR           1 x 17.500  17.500',
  'SUB TOTAL                       30.500',
  'DISKON                           1.000',
  'TOTAL                           29.500',
  'TUNAI                           50.000',
  'KEMBALI                         20.500',
  '14-09-2026 11:05',
];

const restoran = [
  'Warung Sate Pak Slamet',
  'Tanggal: 13/09/2026',
  'Sate Ayam 2 porsi        60.000',
  'Es Teh 2                 10.000',
  'PPN 11%                   7.700',
  'GRAND TOTAL              77.700',
];

void main() {
  final now = DateTime(2026, 9, 14, 12);

  group('parseReceiptAmount', () {
    test('reads Indonesian thousand separators', () {
      expect(parseReceiptAmount('187.350'), 187350);
      expect(parseReceiptAmount('1.250.000'), 1250000);
      expect(parseReceiptAmount('Rp 50.000'), 50000);
    });

    test('reads comma thousand separators', () {
      expect(parseReceiptAmount('187,350'), 187350);
    });

    test('treats a two digit tail as decimals', () {
      expect(parseReceiptAmount('187.350,00'), 187350);
      expect(parseReceiptAmount('29.500,50'), closeTo(29500.5, 0.001));
    });

    test('handles a plain number', () {
      expect(parseReceiptAmount('50000'), 50000);
    });

    test('returns null for junk', () {
      expect(parseReceiptAmount('abc'), isNull);
      expect(parseReceiptAmount(''), isNull);
    });
  });

  group('findReceiptTotal', () {
    test('takes the total, not the largest number on the receipt', () {
      expect(findReceiptTotal(indomaret), 29500);
    });

    test('ignores cash tendered and change', () {
      final total = findReceiptTotal(indomaret);
      expect(total, isNot(50000), reason: 'TUNAI is what the customer handed over');
      expect(total, isNot(20500), reason: 'KEMBALI is the change');
    });

    test('prefers the total over the subtotal', () {
      expect(findReceiptTotal(indomaret), isNot(30500));
    });

    test('ignores price per litre on a fuel receipt', () {
      final total = findReceiptTotal(spbu);
      expect(total, 50000);
      expect(total, isNot(13500), reason: 'that is the price per litre');
    });

    test('reads a grand total', () {
      expect(findReceiptTotal(restoran), 77700);
    });

    test('does not mistake the tax line for the total', () {
      expect(findReceiptTotal(restoran), isNot(7700));
    });

    test('falls back to the next line when the keyword line has no number', () {
      expect(findReceiptTotal(['TOTAL', '45.000']), 45000);
    });

    test('returns null when there is no total at all', () {
      expect(findReceiptTotal(['TOKO ABC', 'terima kasih']), isNull);
    });
  });

  group('findReceiptDate', () {
    test('reads slash and dash formats', () {
      expect(findReceiptDate(spbu, now), DateTime(2026, 9, 14));
      expect(findReceiptDate(indomaret, now), DateTime(2026, 9, 14));
      expect(findReceiptDate(restoran, now), DateTime(2026, 9, 13));
    });

    test('reads a two digit year', () {
      expect(findReceiptDate(['05/03/26'], now), DateTime(2026, 3, 5));
    });

    test('reads an ISO style date', () {
      expect(findReceiptDate(['2026-09-10'], now), DateTime(2026, 9, 10));
    });

    test('rejects an impossible date', () {
      expect(findReceiptDate(['32/13/2026'], now), isNull);
    });

    test('rejects a date far in the future', () {
      expect(findReceiptDate(['14/09/2099'], now), isNull);
    });

    test('returns null when there is no date', () {
      expect(findReceiptDate(['TOKO ABC'], now), isNull);
    });
  });

  group('findReceiptMerchant', () {
    test('takes the shop name from the top', () {
      expect(findReceiptMerchant(indomaret), 'INDOMARET');
      expect(findReceiptMerchant(restoran), 'Warung Sate Pak Slamet');
    });

    test('skips lines that are mostly digits', () {
      expect(findReceiptMerchant(['12345678', '0812-3456-7890', 'TOKO MAJU']),
          'TOKO MAJU');
    });
  });

  group('categoryForReceipt', () {
    test('recognises a fuel station', () {
      expect(categoryForReceipt(spbu), 'Transport');
    });

    test('recognises a minimarket', () {
      expect(categoryForReceipt(indomaret), 'Belanja');
    });

    test('recognises somewhere to eat', () {
      expect(categoryForReceipt(restoran), 'Makan');
    });

    test('gives up on an unknown shop', () {
      expect(categoryForReceipt(['TOKO SERBA ADA XYZ', 'TOTAL 10.000']), isNull);
    });

    test('the more specific name wins over a generic one', () {
      expect(categoryForReceipt(['Warung Bakso Pak Man']), 'Makan');
      expect(categoryForReceipt(['Apotek Kimia Farma']), 'Kesehatan');
    });
  });

  group('parseReceipt', () {
    test('reads a fuel receipt end to end', () {
      final scan = parseReceipt(spbu, now: now);
      expect(scan.total, 50000);
      expect(scan.date, DateTime(2026, 9, 14));
      expect(scan.category, 'Transport');
      expect(scan.merchant, isNotNull);
    });

    test('reads a minimarket receipt end to end', () {
      final scan = parseReceipt(indomaret, now: now);
      expect(scan.total, 29500);
      expect(scan.date, DateTime(2026, 9, 14));
      expect(scan.merchant, 'INDOMARET');
      expect(scan.category, 'Belanja');
    });

    test('an unreadable photo yields an empty scan', () {
      final scan = parseReceipt(['', '   ', '\n'], now: now);
      expect(scan.isEmpty, isTrue);
      expect(scan.total, isNull);
    });

    test('a partial read still returns what it found', () {
      final scan = parseReceipt(['ALFAMART', 'blur blur'], now: now);
      expect(scan.total, isNull);
      expect(scan.merchant, 'ALFAMART');
      expect(scan.category, 'Belanja');
    });
  });

  group('groupIntoVisualRows', () {
    ScannedLine at(String text, double top, double left) => ScannedLine(
          text: text,
          top: top,
          bottom: top + 20,
          left: left,
        );

    test('rejoins a label and its amount split across blocks', () {
      final rows = groupIntoVisualRows([
        at('SUB TOTAL', 100, 10),
        at('TOTAL', 130, 10),
        at('TUNAI', 160, 10),
        at('30.500', 100, 400),
        at('29.500', 130, 400),
        at('50.000', 160, 400),
      ]);

      expect(rows, [
        'SUB TOTAL 30.500',
        'TOTAL 29.500',
        'TUNAI 50.000',
      ]);
    });

    test('the regrouped rows give the right total', () {
      final rows = groupIntoVisualRows([
        at('TOTAL', 130, 10),
        at('TUNAI', 160, 10),
        at('29.500', 130, 400),
        at('50.000', 160, 400),
      ]);
      expect(findReceiptTotal(rows), 29500);
    });

    test('orders rows top to bottom and columns left to right', () {
      final rows = groupIntoVisualRows([
        at('KANAN', 50, 300),
        at('KIRI', 50, 10),
        at('ATAS', 10, 10),
      ]);
      expect(rows, ['ATAS', 'KIRI KANAN']);
    });

    test('keeps slightly misaligned text on the same row', () {
      final rows = groupIntoVisualRows([
        at('TOTAL', 100, 10),
        at('29.500', 104, 400),
      ]);
      expect(rows, ['TOTAL 29.500']);
    });

    test('separates rows that are clearly apart', () {
      final rows = groupIntoVisualRows([
        at('TOTAL', 100, 10),
        at('29.500', 140, 400),
      ]);
      expect(rows, hasLength(2));
    });

    test('handles an empty scan', () {
      expect(groupIntoVisualRows([]), isEmpty);
    });
  });
}
