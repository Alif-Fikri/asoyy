import 'package:flutter/material.dart';
import '../../data/auth_config_repository.dart';
import '../../services/secure_screen.dart';
import '../widgets/auto_lock_gate.dart';
import 'password_auth_gate.dart';
import 'password_page.dart';

class PasswordFlowPage extends StatelessWidget {
  const PasswordFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AuthConfigRepository();
    return AutoLockGate(
      onMount: SecureScreen.enable,
      onUnmount: SecureScreen.disable,
      locked: (context, unlock) => PasswordAuthGate(
        repo: repo,
        onAuthenticated: unlock,
      ),
      unlocked: (context) => PasswordPage(authRepo: repo),
    );
  }
}
