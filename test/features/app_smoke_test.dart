import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:founder_finance_manager/app/founder_finance_app.dart';
import 'package:founder_finance_manager/core/storage/secure_session_store.dart';
import 'package:founder_finance_manager/shared/providers/finance_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders secure login flow', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureSessionStoreProvider.overrideWithValue(_FakeSessionStore()),
        ],
        child: const FounderFinanceApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Sign in to MONEX'), findsOneWidget);
    expect(find.text('Continue in local mode'), findsNothing);
    expect(find.text('Create new account'), findsOneWidget);
  });
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
