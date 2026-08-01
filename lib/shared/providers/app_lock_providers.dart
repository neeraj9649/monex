import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/app_lock_service.dart';

final appLockServiceProvider = Provider<AppLockService>(
  (ref) => AppLockService(),
);

class AppLockState {
  const AppLockState({
    this.enabled = false,
    this.available = false,
    this.hasBiometrics = false,
    this.unlocked = false,
    this.checking = true,
    this.failed = false,
  });

  final bool enabled;
  final bool available;
  final bool hasBiometrics;

  /// True once the current session has been unlocked.
  final bool unlocked;

  /// True while the initial settings read is in flight.
  final bool checking;

  /// True after a failed or cancelled prompt, so the gate can offer a retry.
  final bool failed;

  /// The gate should block the UI only when the lock is on and not yet passed.
  bool get shouldBlock => enabled && !unlocked;

  AppLockState copyWith({
    bool? enabled,
    bool? available,
    bool? hasBiometrics,
    bool? unlocked,
    bool? checking,
    bool? failed,
  }) => AppLockState(
    enabled: enabled ?? this.enabled,
    available: available ?? this.available,
    hasBiometrics: hasBiometrics ?? this.hasBiometrics,
    unlocked: unlocked ?? this.unlocked,
    checking: checking ?? this.checking,
    failed: failed ?? this.failed,
  );
}

class AppLockController extends Notifier<AppLockState> {
  @override
  AppLockState build() {
    Future.microtask(restore);
    return const AppLockState();
  }

  AppLockService get _service => ref.read(appLockServiceProvider);

  /// Only mobile builds get a lock; web and desktop have no enrolled
  /// biometrics to fall back on.
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> restore() async {
    if (!isSupported) {
      state = const AppLockState(checking: false, unlocked: true);
      return;
    }

    var enabled = false;
    try {
      final available = await _service.isAvailable();
      enabled = available && await _service.isEnabled();
      state = state.copyWith(
        available: available,
        hasBiometrics: await _service.hasBiometrics(),
        enabled: enabled,
        checking: false,
        unlocked: !enabled,
      );
    } on Exception {
      // Never strand the user on the loading screen because a platform
      // channel was unavailable: fail open rather than locking them out.
      state = const AppLockState(checking: false, unlocked: true);
      return;
    }

    if (enabled) await unlock();
  }

  /// Prompts for fingerprint / device credential.
  Future<void> unlock() async {
    final passed = await _service.authenticate();
    state = state.copyWith(unlocked: passed, failed: !passed);
  }

  /// Turning the lock on requires passing the prompt once, so a device that
  /// cannot actually authenticate never leaves you locked out.
  Future<String?> setEnabled(bool value) async {
    if (!isSupported) return 'App lock is available on mobile only';
    if (value && !await _service.isAvailable()) {
      return 'No fingerprint or screen lock is set up on this device';
    }

    if (value) {
      final passed = await _service.authenticate(
        reason: 'Confirm to turn on the MONEX app lock',
      );
      if (!passed) return 'Could not verify. App lock was not turned on.';
    }

    await _service.setEnabled(value);
    state = state.copyWith(enabled: value, unlocked: true, failed: false);
    return null;
  }

  /// Re-arms the lock, used when the app returns from the background.
  void relock() {
    if (!state.enabled) return;
    state = state.copyWith(unlocked: false, failed: false);
  }
}

final appLockControllerProvider =
    NotifierProvider<AppLockController, AppLockState>(AppLockController.new);
