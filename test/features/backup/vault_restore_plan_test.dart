import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/backup/domain/vault_restore_plan.dart';

Uint8List _key(int length) =>
    Uint8List.fromList(List<int>.generate(length, (i) => i));

Uint8List _state(bool encrypted) => Uint8List.fromList([encrypted ? 1 : 0]);

void main() {
  group('planVaultRestore', () {
    test('a backup carrying the key restores it', () {
      final plan = planVaultRestore(
        backedUpKey: _key(32),
        vaultState: _state(true),
        expectedKeyLength: 32,
      );
      expect(plan, VaultRestorePlan.useBackedUpKey);
    });

    test('an encrypted vault with no key in the backup stays locked', () {
      final plan = planVaultRestore(
        backedUpKey: null,
        vaultState: _state(true),
        expectedKeyLength: 32,
      );
      expect(plan, VaultRestorePlan.keepLocked);
    });

    test('a truncated key is not trusted and the vault stays locked', () {
      final plan = planVaultRestore(
        backedUpKey: _key(16),
        vaultState: _state(true),
        expectedKeyLength: 32,
      );
      expect(plan, VaultRestorePlan.keepLocked);
    });

    test('a vault that was plaintext is migrated as before', () {
      final plan = planVaultRestore(
        backedUpKey: null,
        vaultState: _state(false),
        expectedKeyLength: 32,
      );
      expect(plan, VaultRestorePlan.migratePlaintext);
    });

    test('an old backup with no state recorded is treated as plaintext', () {
      final plan = planVaultRestore(
        backedUpKey: null,
        vaultState: null,
        expectedKeyLength: 32,
      );
      expect(plan, VaultRestorePlan.migratePlaintext);
    });

    test('an empty state entry is treated as plaintext', () {
      final plan = planVaultRestore(
        backedUpKey: null,
        vaultState: Uint8List(0),
        expectedKeyLength: 32,
      );
      expect(plan, VaultRestorePlan.migratePlaintext);
    });

    test('an encrypted vault is never migrated, whatever the key looks like',
        () {
      for (final key in <Uint8List?>[null, Uint8List(0), _key(8), _key(31)]) {
        expect(
          planVaultRestore(
            backedUpKey: key,
            vaultState: _state(true),
            expectedKeyLength: 32,
          ),
          isNot(VaultRestorePlan.migratePlaintext),
          reason: 'migrating over an encrypted vault destroys it',
        );
      }
    });
  });
}
