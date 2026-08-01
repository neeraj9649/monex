import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fingerprint / face / device-credential gate for MONEX.
class AppLockService {
  static const _enabledKey = 'monex.security.app_lock_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  /// How long to wait on a capability probe before assuming "no".
  ///
  /// These calls cross a platform channel. If that channel never answers,
  /// waiting forever would leave the unlock screen stuck, so they fail closed
  /// on a timer instead.
  static const _probeTimeout = Duration(seconds: 5);

  /// Whether the device can prompt for a biometric or device credential.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported().timeout(
        _probeTimeout,
        onTimeout: () => false,
      );
    } on Exception {
      return false;
    }
  }

  /// True when a fingerprint or face is actually enrolled.
  Future<bool> hasBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics.timeout(
        _probeTimeout,
        onTimeout: () => false,
      );
      if (!canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics().timeout(
        _probeTimeout,
        onTimeout: () => const [],
      );
      return enrolled.isNotEmpty;
    } on Exception {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  /// Shows the system prompt. Returns true only on a successful unlock.
  ///
  /// [biometricOnly] stays false so a device PIN or pattern still works when
  /// a fingerprint fails or is not enrolled, which avoids locking you out of
  /// your own ledger.
  Future<bool> authenticate({
    String reason = 'Unlock MONEX to view your finances',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on Exception {
      // No hardware, nothing enrolled, too many failed attempts, or the
      // platform channel is unavailable. Any of those means: stay locked.
      return false;
    }
  }
}
