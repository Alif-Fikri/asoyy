import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../data/auth_config_repository.dart';
import '../../domain/entities/auth_method.dart';
import '../widgets/pattern_lock.dart';
import '../widgets/pin_input.dart';

class PasswordAuthGate extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final AuthConfigRepository repo;

  const PasswordAuthGate({
    super.key,
    required this.onAuthenticated,
    required this.repo,
  });

  @override
  State<PasswordAuthGate> createState() => _PasswordAuthGateState();
}

class _PasswordAuthGateState extends State<PasswordAuthGate> {



  AuthMethod? _setupChoice;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: !widget.repo.isConfigured
            ? _buildSetupRoute()
            : _LockScreen(
                repo: widget.repo,
                method: widget.repo.currentMethod!,
                onSuccess: widget.onAuthenticated,
              ),
      ),
    );
  }

  Widget _buildSetupRoute() {
    if (_setupChoice == null) {
      return _SetupPicker(
        onChosen: (method) async {
          if (method == AuthMethod.biometric) {

            final ok = await _verifyBiometric(context);
            if (!ok || !mounted) return;
            await widget.repo.setMethod(AuthMethod.biometric);
            widget.onAuthenticated();
          } else {
            setState(() => _setupChoice = method);
          }
        },
      );
    }

    return _CreateSecretFlow(
      method: _setupChoice!,
      onCompleted: (secret) async {
        await widget.repo.setMethod(_setupChoice!, secret: secret);
        if (!mounted) return;
        widget.onAuthenticated();
      },
      onBack: () => setState(() => _setupChoice = null),
    );
  }
}

class _SetupPicker extends StatelessWidget {
  final void Function(AuthMethod) onChosen;
  const _SetupPicker({required this.onChosen});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.passwordColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              CupertinoIcons.lock,
              color: AppColors.passwordColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.auth_setup_title,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.auth_setup_subtitle,
            style: TextStyle(color: c.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 32),
          _MethodCard(
            icon: CupertinoIcons.lock_shield,
            iconColor: AppColors.income,
            title: s.auth_method_biometric,
            subtitle: s.auth_method_biometric_desc,
            onTap: () => onChosen(AuthMethod.biometric),
          ),
          const SizedBox(height: 12),
          _MethodCard(
            icon: CupertinoIcons.square_grid_3x2,
            iconColor: AppColors.primary,
            title: s.auth_method_pattern,
            subtitle: s.auth_method_pattern_desc,
            onTap: () => onChosen(AuthMethod.pattern),
          ),
          const SizedBox(height: 12),
          _MethodCard(
            icon: CupertinoIcons.number,
            iconColor: AppColors.calendarColor,
            title: s.auth_method_pin,
            subtitle: s.auth_method_pin_desc,
            onTap: () => onChosen(AuthMethod.pin),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: c.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 20, color: c.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateSecretFlow extends StatefulWidget {
  final AuthMethod method;
  final void Function(String secret) onCompleted;
  final VoidCallback onBack;

  const _CreateSecretFlow({
    required this.method,
    required this.onCompleted,
    required this.onBack,
  });

  @override
  State<_CreateSecretFlow> createState() => _CreateSecretFlowState();
}

class _CreateSecretFlowState extends State<_CreateSecretFlow> {
  String? _firstAttempt;
  String? _error;
  int _resetToken = 0;

  void _handle(String value) {
    if (_firstAttempt == null) {
      setState(() {
        _firstAttempt = value;
        _error = null;
        _resetToken++;
      });
    } else if (_firstAttempt == value) {
      widget.onCompleted(value);
    } else {
      setState(() {
        _error = widget.method == AuthMethod.pin
            ? context.strings.auth_pin_mismatch
            : context.strings.auth_pattern_mismatch;
        _firstAttempt = null;
        _resetToken++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final isFirstStep = _firstAttempt == null;
    final isPattern = widget.method == AuthMethod.pattern;

    final headline = isFirstStep
        ? (isPattern ? s.auth_pattern_create : s.auth_pin_create)
        : (isPattern ? s.auth_pattern_confirm : s.auth_pin_confirm);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: Icon(CupertinoIcons.back, color: c.textPrimary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 24),
          Text(
            headline,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 32),
          if (isPattern)
            PatternLock(
              onCompleted: _handle,
              errorText: _error,
              resetToken: _resetToken,
            )
          else
            PinInput(
              onCompleted: _handle,
              errorText: _error,
              resetToken: _resetToken,
            ),
        ],
      ),
    );
  }
}

class _LockScreen extends StatefulWidget {
  final AuthConfigRepository repo;
  final AuthMethod method;
  final VoidCallback onSuccess;

  const _LockScreen({
    required this.repo,
    required this.method,
    required this.onSuccess,
  });

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  String? _error;
  int _resetToken = 0;
  bool _biometricAttempting = false;

  @override
  void initState() {
    super.initState();


    if (widget.method == AuthMethod.biometric) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  Future<void> _tryBiometric() async {
    if (_biometricAttempting) return;
    setState(() => _biometricAttempting = true);
    final ok = await _verifyBiometric(context);
    if (!mounted) return;
    setState(() => _biometricAttempting = false);
    if (ok) {
      widget.onSuccess();
    } else {
      setState(() => _error = context.strings.pass_auth_failed);
    }
  }

  void _verify(String secret) {
    if (widget.repo.verify(secret)) {
      widget.onSuccess();
    } else {
      setState(() {
        _error = widget.method == AuthMethod.pin
            ? context.strings.auth_pin_mismatch
            : context.strings.auth_pattern_mismatch;
        _resetToken++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.passwordColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              CupertinoIcons.lock,
              color: AppColors.passwordColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.pass_auth_title,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _hintForMethod(s),
            style: TextStyle(color: c.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 36),
          Expanded(child: _buildInput()),
        ],
      ),
    );
  }

  String _hintForMethod(AppStrings s) {
    switch (widget.method) {
      case AuthMethod.biometric:
        return s.pass_auth_subtitle;
      case AuthMethod.pattern:
        return s.auth_pattern_enter;
      case AuthMethod.pin:
        return s.auth_pin_enter;
    }
  }

  Widget _buildInput() {
    switch (widget.method) {
      case AuthMethod.biometric:
        return _BiometricRetry(
          onRetry: _tryBiometric,
          attempting: _biometricAttempting,
          errorText: _error,
        );
      case AuthMethod.pattern:
        return PatternLock(
          onCompleted: _verify,
          errorText: _error,
          resetToken: _resetToken,
        );
      case AuthMethod.pin:
        return PinInput(
          onCompleted: _verify,
          errorText: _error,
          resetToken: _resetToken,
        );
    }
  }
}

class _BiometricRetry extends StatelessWidget {
  final VoidCallback onRetry;
  final bool attempting;
  final String? errorText;
  const _BiometricRetry({
    required this.onRetry,
    required this.attempting,
    required this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (attempting)
          const CircularProgressIndicator(color: AppColors.passwordColor)
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(CupertinoIcons.lock_shield),
              label: Text(s.pass_auth_unlock),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.passwordColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        if (errorText != null) ...[
          const SizedBox(height: 16),
          Text(
            errorText!,
            style: const TextStyle(color: AppColors.alarmColor, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

Future<bool> _verifyBiometric(BuildContext context) async {
  final auth = LocalAuthentication();
  try {
    return await auth.authenticate(
      localizedReason: context.strings.pass_auth_subtitle,
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  } catch (_) {
    return false;
  }
}

Future<bool> verifyCurrentAuth(
  BuildContext context,
  AuthConfigRepository repo,
) async {
  final method = repo.currentMethod;
  if (method == null) return true;

  if (method == AuthMethod.biometric) {
    return _verifyBiometric(context);
  }

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _VerifyDialog(method: method, repo: repo),
      ) ??
      false;
}

class _VerifyDialog extends StatefulWidget {
  final AuthMethod method;
  final AuthConfigRepository repo;
  const _VerifyDialog({required this.method, required this.repo});

  @override
  State<_VerifyDialog> createState() => _VerifyDialogState();
}

class _VerifyDialogState extends State<_VerifyDialog> {
  String? _error;
  int _resetToken = 0;

  void _onSecret(String secret) {
    if (widget.repo.verify(secret)) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = widget.method == AuthMethod.pin
            ? context.strings.auth_pin_mismatch
            : context.strings.auth_pattern_mismatch;
        _resetToken++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final isPattern = widget.method == AuthMethod.pattern;

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.auth_verify_first,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: Icon(CupertinoIcons.xmark, size: 18, color: c.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isPattern)
              PatternLock(
                onCompleted: _onSecret,
                errorText: _error,
                resetToken: _resetToken,
              )
            else
              PinInput(
                onCompleted: _onSecret,
                errorText: _error,
                resetToken: _resetToken,
              ),
          ],
        ),
      ),
    );
  }
}
