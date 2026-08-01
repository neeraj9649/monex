import 'package:flutter_test/flutter_test.dart';
import 'package:founder_finance_manager/core/imports/account_matcher.dart';
import 'package:founder_finance_manager/core/imports/bank_sms_parser.dart';
import 'package:founder_finance_manager/shared/models/enums.dart';
import 'package:founder_finance_manager/shared/models/finance_models.dart';

void main() {
  Account account(
    String id,
    String name, {
    String? institution,
    String? accountNumber,
  }) => Account(
    id: id,
    name: name,
    type: AccountType.bank,
    scope: FinanceScope.personal,
    balancePaise: 0,
    institution: institution,
    accountNumber: accountNumber,
  );

  final idbiMessage = BankSmsParser.parse(
    sender: 'AD-IDBIBK',
    body:
        'IDBI Bank Acct XX330 debited for Rs 2000.00 on 31-Jul-26; '
        'Bal Rs 18239.89 PREM BANGELS ST credited. UPI:433702683217',
    date: DateTime(2026, 7, 31),
  )!;

  test('matches on the account number printed in the SMS', () {
    final id = AccountMatcher.match(
      message: idbiMessage,
      accounts: [
        account('a', 'ICICI Savings', accountNumber: 'XX789'),
        account('b', 'IDBI Current', accountNumber: 'XX330'),
      ],
    );
    expect(id, 'b');
  });

  test('matches when the stored number is longer than the masked hint', () {
    final id = AccountMatcher.match(
      message: idbiMessage,
      accounts: [account('b', 'IDBI Current', accountNumber: '12345330')],
    );
    expect(id, 'b');
  });

  test('falls back to the bank when no account number is stored', () {
    final id = AccountMatcher.match(
      message: idbiMessage,
      accounts: [
        account('a', 'ICICI Savings', institution: 'ICICI Bank'),
        account('b', 'Primary', institution: 'IDBI Bank'),
      ],
    );
    expect(id, 'b');
  });

  test('matches the bank on the account name too', () {
    final id = AccountMatcher.match(
      message: idbiMessage,
      accounts: [account('b', 'IDBI business account')],
    );
    expect(id, 'b');
  });

  test('returns null when two accounts at the same bank are ambiguous', () {
    final id = AccountMatcher.match(
      message: idbiMessage,
      accounts: [
        account('a', 'IDBI One', institution: 'IDBI Bank'),
        account('b', 'IDBI Two', institution: 'IDBI Bank'),
      ],
    );
    expect(id, isNull);
  });

  test('digits win over a competing bank name match', () {
    final id = AccountMatcher.match(
      message: idbiMessage,
      accounts: [
        account('a', 'IDBI Two', institution: 'IDBI Bank'),
        account('b', 'Other bank', accountNumber: 'XX330'),
      ],
    );
    expect(id, 'b');
  });

  test('returns null when nothing resembles the message', () {
    final id = AccountMatcher.match(
      message: idbiMessage,
      accounts: [account('a', 'HDFC Salary', institution: 'HDFC Bank')],
    );
    expect(id, isNull);
  });

  test('returns null with no accounts at all', () {
    expect(
      AccountMatcher.match(message: idbiMessage, accounts: const []),
      isNull,
    );
  });
}
