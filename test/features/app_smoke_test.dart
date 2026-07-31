import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:founder_finance_manager/app/founder_finance_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders secure login flow', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: FounderFinanceApp()));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to MONEX'), findsOneWidget);
    expect(find.text('Create new account'), findsOneWidget);
  });
}
