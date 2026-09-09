import 'package:flutter/material.dart';
import '../../data/auth_config_repository.dart';
import 'password_auth_gate.dart';
import 'password_page.dart';

class PasswordFlowPage extends StatefulWidget {
  const PasswordFlowPage({super.key});

  @override
  State<PasswordFlowPage> createState() => _PasswordFlowPageState();
}

class _PasswordFlowPageState extends State<PasswordFlowPage> {
  final AuthConfigRepository _repo = AuthConfigRepository();
  bool _authenticated = false;

  @override
  Widget build(BuildContext context) {
    if (_authenticated) return PasswordPage(authRepo: _repo);
    return PasswordAuthGate(
      repo: _repo,
      onAuthenticated: () => setState(() => _authenticated = true),
    );
  }
}
