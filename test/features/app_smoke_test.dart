import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:founder_finance_manager/app/founder_finance_app.dart';
import 'package:founder_finance_manager/core/security/app_lock_service.dart';
import 'package:founder_finance_manager/core/storage/secure_session_store.dart';
import 'package:founder_finance_manager/shared/providers/app_lock_providers.dart';
import 'package:founder_finance_manager/shared/providers/finance_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders secure login flow', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureSessionStoreProvider.overrideWithValue(_FakeSessionStore()),
          // Without this the lock gate waits on the local_auth platform
          // channel, which never answers under flutter test.
          appLockServiceProvider.overrideWithValue(_FakeAppLockService()),
        ],
        child: const FounderFinanceApp(),
      ),
    );
    // The app lock gate reads its setting asynchronously before releasing the
    // first route, so settle rather than pumping a fixed number of frames.
    await tester.pumpAndSettle();

    expect(find.text('Sign in to MONEX'), findsOneWidget);
    expect(find.text('Continue in local mode'), findsNothing);
    expect(find.text('Create new account'), findsOneWidget);
  });
}

/// A device with no biometric hardware, so the gate never blocks.
class _FakeAppLockService implements AppLockService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> hasBiometrics() async => false;

  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<void> setEnabled(bool value) async {}

  @override
  Future<bool> authenticate({String reason = ''}) async => true;
}

class _FakeSessionStore implements SecureSessionStore {
  String? _token;

  @override
  Future<void> clear() async {
    _token = null;
  }

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }
}
