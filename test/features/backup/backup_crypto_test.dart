import 'dart:convert';
import 'dart:typed_data';

import 'package:asoyy/features/backup/services/backup_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      // RFC-style vector: P="password", S="salt", c=10000, dkLen=32
      final key = deriveKey('password', Uint8List.fromList(utf8.encode('salt')));
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
        // padding check rejected it, which is the outcome we want
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
