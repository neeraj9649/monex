import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_lock_providers.dart';
import '../providers/sms_import_providers.dart';

/// Covers the app with an unlock screen while the app lock is armed, and
/// picks up background-captured SMS whenever MONEX returns to the foreground.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(smsImportControllerProvider.notifier).restore();
    } else if (state == AppLifecycleState.paused) {
      ref.read(appLockControllerProvider.notifier).relock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockControllerProvider);

    // Blank rather than a spinner while the lock setting is read: this state
    // lasts a few milliseconds, and an indefinite animation would mean
    // pumpAndSettle can never settle in widget tests.
    if (lock.checking) return const _LockScaffold(child: SizedBox.shrink());
    if (!lock.shouldBlock) return widget.child;

    return _LockScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fingerprint_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'MONEX is locked',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                lock.failed
                    ? 'Verification was cancelled or did not match.'
                    : 'Verify with your fingerprint or screen lock to continue.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(appLockControllerProvider.notifier).unlock(),
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(lock.failed ? 'Try again' : 'Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockScaffold extends StatelessWidget {
  const _LockScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: child));
}
