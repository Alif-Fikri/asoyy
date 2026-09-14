import 'dart:typed_data';

import 'package:asoyy/features/password/services/secure_screen.dart';
import 'package:asoyy/features/password/services/vault_key_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const secureScreenChannel =
      MethodChannel('id.co.alchemist.beres/secure_screen');

  group('VaultKeyStore on the real platform', () {
    final store = VaultKeyStore();

    tearDown(() async {
      await store.delete();
    });

    testWidgets('creates a key and reads it back', (tester) async {
      await store.delete();
      expect(await store.read(), isNull);

      final created = await store.readOrCreate();
      expect(created.length, vaultKeyLength);

      final readBack = await store.read();
      expect(readBack, equals(created));
    });

    testWidgets('readOrCreate is stable across calls', (tester) async {
      final first = await store.readOrCreate();
      final second = await store.readOrCreate();
      expect(second, equals(first));
    });

    testWidgets('a written key survives being read by a new instance',
        (tester) async {
      final key = Uint8List.fromList(List<int>.generate(32, (i) => i));
      await store.write(key);
      expect(await VaultKeyStore().read(), equals(key));
    });

    testWidgets('delete really removes it', (tester) async {
      await store.readOrCreate();
      await store.delete();
      expect(await store.read(), isNull);
    });

    testWidgets('rejects a key of the wrong length', (tester) async {
      expect(
        () => store.write(Uint8List(16)),
        throwsArgumentError,
      );
    });
  });

  group('secure screen channel', () {
    testWidgets('the platform handles enable and disable', (tester) async {
      await secureScreenChannel.invokeMethod<void>('enable');
      await secureScreenChannel.invokeMethod<void>('disable');
    });

    testWidgets('an unknown method is reported as not implemented',
        (tester) async {
      await expectLater(
        secureScreenChannel.invokeMethod<void>('nonsense'),
        throwsA(isA<MissingPluginException>()),
      );
    });

    testWidgets('the wrapper never throws', (tester) async {
      await SecureScreen.enable();
      await SecureScreen.disable();
    });
  });
}
