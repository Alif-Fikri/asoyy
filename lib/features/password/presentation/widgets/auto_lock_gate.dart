import 'package:flutter/widgets.dart';

class AutoLockGate extends StatefulWidget {
  final Widget Function(BuildContext context, VoidCallback unlock) locked;
  final WidgetBuilder unlocked;
  final VoidCallback? onMount;
  final VoidCallback? onUnmount;

  const AutoLockGate({
    super.key,
    required this.locked,
    required this.unlocked,
    this.onMount,
    this.onUnmount,
  });

  @override
  State<AutoLockGate> createState() => _AutoLockGateState();
}

class _AutoLockGateState extends State<AutoLockGate>
    with WidgetsBindingObserver {
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.onMount?.call();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.onUnmount?.call();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!shouldLockOnLifecycle(state)) return;
    if (!_authenticated) return;
    setState(() => _authenticated = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) return widget.unlocked(context);
    return widget.locked(
      context,
      () => setState(() => _authenticated = true),
    );
  }
}

bool shouldLockOnLifecycle(AppLifecycleState state) =>
    state == AppLifecycleState.paused ||
    state == AppLifecycleState.detached ||
    state == AppLifecycleState.hidden;
