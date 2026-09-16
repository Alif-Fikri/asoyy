import 'dart:typed_data';

enum VaultRestorePlan { useBackedUpKey, keepLocked, migratePlaintext }

VaultRestorePlan planVaultRestore({
  required Uint8List? backedUpKey,
  required Uint8List? vaultState,
  required int expectedKeyLength,
}) {
  if (backedUpKey != null && backedUpKey.length == expectedKeyLength) {
    return VaultRestorePlan.useBackedUpKey;
  }

  final wasEncrypted =
      vaultState != null && vaultState.isNotEmpty && vaultState.first == 1;

  return wasEncrypted
      ? VaultRestorePlan.keepLocked
      : VaultRestorePlan.migratePlaintext;
}
