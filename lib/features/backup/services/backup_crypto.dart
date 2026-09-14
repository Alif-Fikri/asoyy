import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

const int backupSaltLength = 16;
const int backupIvLength = 16;
const int _pbkdf2Iterations = 10000;
const int _keyLength = 32;

Uint8List randomBytes(int length) {
  final rand = Random.secure();
  return Uint8List.fromList(List<int>.generate(length, (_) => rand.nextInt(256)));
}

Uint8List deriveKey(String passphrase, Uint8List salt) {
  final passwordBytes = utf8.encode(passphrase);
  final hmac = Hmac(sha256, passwordBytes);
  final blockCount = (_keyLength / 32).ceil();
  final derived = BytesBuilder();

  for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
    var block = Uint8List.fromList([
      ...salt,
      (blockIndex >> 24) & 0xff,
      (blockIndex >> 16) & 0xff,
      (blockIndex >> 8) & 0xff,
      blockIndex & 0xff,
    ]);
    var u = hmac.convert(block).bytes;
    var result = Uint8List.fromList(u);

    for (var i = 1; i < _pbkdf2Iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    derived.add(result);
  }

  return Uint8List.fromList(derived.toBytes().sublist(0, _keyLength));
}

Uint8List encryptBytes(Uint8List plain, Uint8List key, Uint8List iv) {
  final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
  return encrypter.encryptBytes(plain, iv: enc.IV(iv)).bytes;
}

Uint8List decryptBytes(Uint8List cipher, Uint8List key, Uint8List iv) {
  final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
  return Uint8List.fromList(
    encrypter.decryptBytes(enc.Encrypted(cipher), iv: enc.IV(iv)),
  );
}
