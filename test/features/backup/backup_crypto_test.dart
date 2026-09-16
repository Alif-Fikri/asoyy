import 'dart:convert';
import 'dart:typed_data';

import 'package:asoyy/features/backup/services/backup_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _authenticatedBackupTests();
  group('randomBytes', () {
    test('returns the requested length', () {
      expect(randomBytes(backupSaltLength).length, backupSaltLength);
      expect(randomBytes(backupIvLength).length, backupIvLength);
    });

    test('does not repeat itself', () {
      final a = randomBytes(16);
      final b = randomBytes(16);
      expect(a, isNot(equals(b)));
    });
  });

  group('deriveKey', () {
    final salt = Uint8List.fromList(List<int>.generate(16, (i) => i));

    test('produces a 256-bit key', () {
      expect(deriveKey('rahasia', salt).length, 32);
    });

    test('is deterministic for the same passphrase and salt', () {
      expect(deriveKey('rahasia', salt), equals(deriveKey('rahasia', salt)));
    });

    test('a different passphrase gives a different key', () {
      expect(deriveKey('rahasia', salt), isNot(equals(deriveKey('rahasia2', salt))));
    });

    test('a different salt gives a different key', () {
      final other = Uint8List.fromList(List<int>.generate(16, (i) => i + 1));
      expect(deriveKey('rahasia', salt), isNot(equals(deriveKey('rahasia', other))));
    });

    test('matches the PBKDF2-HMAC-SHA256 reference vector', () {
      final key = deriveKey(
        'password',
        Uint8List.fromList(utf8.encode('salt')),
        iterations: 10000,
      );
      expect(
        key.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        '5ec02b91a4b59c6f59dd5fbe4ca649ece4fa8568cdb8ba36cf41426e8805522b',
      );
    });
  });

  group('encrypt/decrypt round trip', () {
    final key = deriveKey('passphrase-ku', randomBytes(backupSaltLength));
    final iv = randomBytes(backupIvLength);

    test('recovers the original bytes', () {
      final plain = Uint8List.fromList(utf8.encode('{"transactions":[]}'));
      final restored = decryptBytes(encryptBytes(plain, key, iv), key, iv);
      expect(restored, equals(plain));
    });

    test('handles a payload larger than one AES block', () {
      final plain = Uint8List.fromList(
        utf8.encode(List.filled(500, 'data-backup-asoyy').join(',')),
      );
      final restored = decryptBytes(encryptBytes(plain, key, iv), key, iv);
      expect(restored, equals(plain));
    });

    test('ciphertext does not leak the plaintext', () {
      final plain = Uint8List.fromList(utf8.encode('saldo rahasia 12345678'));
      final cipher = encryptBytes(plain, key, iv);
      expect(utf8.decode(cipher, allowMalformed: true), isNot(contains('12345678')));
    });

    test('the wrong passphrase does not recover the data', () {
      final plain = Uint8List.fromList(utf8.encode('saldo rahasia 12345678'));
      final cipher = encryptBytes(plain, key, iv);
      final wrongKey = deriveKey('salah', randomBytes(backupSaltLength));
      Uint8List? restored;
      try {
        restored = decryptBytes(cipher, wrongKey, iv);
      } catch (_) {
      }
      expect(restored, isNot(equals(plain)));
    });

    test('the wrong IV corrupts the first block', () {
      final plain = Uint8List.fromList(
        utf8.encode('blok-pertama-harus-rusak-total-kalau-iv-beda'),
      );
      final cipher = encryptBytes(plain, key, iv);
      final restored = decryptBytes(cipher, key, randomBytes(backupIvLength));
      expect(restored.sublist(0, 16), isNot(equals(plain.sublist(0, 16))));
    });
  });
}

void _authenticatedBackupTests() {
  group('key material', () {
    test('the first half of a 64-byte derivation matches the old 32-byte key',
        () {
      final salt = Uint8List.fromList(List<int>.generate(16, (i) => i));
      final legacy = deriveKey('rahasia', salt, iterations: 1000);
      final extended = deriveKey('rahasia', salt, iterations: 1000, length: 64);

      expect(extended.length, 64);
      expect(extended.sublist(0, 32), legacy,
          reason: 'old backups must still decrypt with the same key');
    });

    test('the mac half differs from the encryption half', () {
      final salt = Uint8List.fromList(List<int>.generate(16, (i) => i));
      final material = deriveKey('rahasia', salt, iterations: 1000, length: 64);
      expect(material.sublist(0, 32), isNot(material.sublist(32, 64)));
    });
  });

  group('backup tag', () {
    final macKey = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final header = List<int>.generate(24, (i) => i);
    final cipher = Uint8List.fromList(List<int>.generate(48, (i) => i * 3 % 256));

    test('is stable for the same inputs', () {
      expect(
        computeBackupTag(macKey: macKey, header: header, cipher: cipher),
        computeBackupTag(macKey: macKey, header: header, cipher: cipher),
      );
    });

    test('changes when a single ciphertext byte is flipped', () {
      final tampered = Uint8List.fromList(cipher);
      tampered[10] ^= 0x01;

      expect(
        computeBackupTag(macKey: macKey, header: header, cipher: tampered),
        isNot(computeBackupTag(macKey: macKey, header: header, cipher: cipher)),
      );
    });

    test('changes when the header is altered', () {
      final tampered = List<int>.from(header)..[2] ^= 0x01;

      expect(
        computeBackupTag(macKey: macKey, header: tampered, cipher: cipher),
        isNot(computeBackupTag(macKey: macKey, header: header, cipher: cipher)),
      );
    });

    test('a different mac key gives a different tag', () {
      final otherKey = Uint8List.fromList(List<int>.filled(32, 7));
      expect(
        computeBackupTag(macKey: otherKey, header: header, cipher: cipher),
        isNot(computeBackupTag(macKey: macKey, header: header, cipher: cipher)),
      );
    });
  });

  group('constantTimeEquals', () {
    test('accepts identical byte lists', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    });

    test('rejects a single differing byte', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
    });

    test('rejects different lengths', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2]), isFalse);
    });
  });
}
