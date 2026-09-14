import 'package:asoyy/features/password/presentation/widgets/auto_lock_gate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldLockOnLifecycle', () {
    test('locks when the app leaves the foreground', () {
      expect(shouldLockOnLifecycle(AppLifecycleState.paused), isTrue);
      expect(shouldLockOnLifecycle(AppLifecycleState.detached), isTrue);
      expect(shouldLockOnLifecycle(AppLifecycleState.hidden), isTrue);
    });

    test('does not lock on a transient interruption', () {
      expect(shouldLockOnLifecycle(AppLifecycleState.inactive), isFalse);
      expect(shouldLockOnLifecycle(AppLifecycleState.resumed), isFalse);
    });
  });

  group('AutoLockGate', () {
    Widget gate({VoidCallback? onMount, VoidCallback? onUnmount}) =>
        Directionality(
          textDirection: TextDirection.ltr,
          child: AutoLockGate(
            onMount: onMount,
            onUnmount: onUnmount,
            locked: (context, unlock) => GestureDetector(
              onTap: unlock,
              child: const Text('LOCKED'),
            ),
            unlocked: (context) => const Text('VAULT'),
          ),
        );

    Future<void> unlock(WidgetTester tester) async {
      await tester.tap(find.text('LOCKED'));
      await tester.pump();
    }

    Future<void> background(WidgetTester tester) async {
      for (final state in [
        AppLifecycleState.resumed,
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
    }

    Future<void> foreground(WidgetTester tester) async {
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }
    }

    testWidgets('starts locked', (tester) async {
      await tester.pumpWidget(gate());
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('VAULT'), findsNothing);
    });

    testWidgets('unlocks when the gate says so', (tester) async {
      await tester.pumpWidget(gate());
      await unlock(tester);
      expect(find.text('VAULT'), findsOneWidget);
    });

    testWidgets('relocks after the app has been backgrounded', (tester) async {
      await tester.pumpWidget(gate());
      await unlock(tester);

      await background(tester);
      await foreground(tester);

      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('VAULT'), findsNothing);
    });

    testWidgets('stays unlocked through a transient interruption',
        (tester) async {
      await tester.pumpWidget(gate());
      await unlock(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(find.text('VAULT'), findsOneWidget);
    });

    testWidgets('an unauthenticated gate is untouched by backgrounding',
        (tester) async {
      await tester.pumpWidget(gate());

      await background(tester);
      await foreground(tester);

      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('VAULT'), findsNothing);
    });

    testWidgets('backgrounding twice is harmless', (tester) async {
      await tester.pumpWidget(gate());
      await unlock(tester);

      await background(tester);
      await foreground(tester);
      await background(tester);
      await foreground(tester);

      expect(find.text('LOCKED'), findsOneWidget);
    });

    testWidgets('the screen guard is raised on mount and dropped on unmount',
        (tester) async {
      var mounted = 0;
      var unmounted = 0;
      await tester.pumpWidget(
        gate(onMount: () => mounted++, onUnmount: () => unmounted++),
      );
      expect(mounted, 1);
      expect(unmounted, 0);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('elsewhere'),
        ),
      );
      expect(unmounted, 1);
    });
  });
}
