import 'package:flutter_test/flutter_test.dart';
import 'package:founder_finance_manager/core/imports/bank_sms_parser.dart';
import 'package:founder_finance_manager/shared/models/enums.dart';
import 'package:founder_finance_manager/shared/models/imported_bank_message.dart';

void main() {
  final received = DateTime(2026, 8, 1, 10, 30);

  ImportedBankMessage? parse(String body, {String sender = 'AD-IDBIBK'}) =>
      BankSmsParser.parse(sender: sender, body: body, date: received);

  group('IDBI UPI debit (the reported sample)', () {
    const body =
        'IDBI Bank Acct XX330 debited for Rs 2000.00 on 31-Jul-26; '
        'Bal Rs 18239.89 PREM BANGELS ST credited. UPI:433702683217. '
        'To Block UPI send SMS UPIBLOCK <Mob. No> to 07799000423 '
        'or call 18002094324-IDBI Bank';

    test('picks the transaction amount, not the closing balance', () {
      expect(parse(body)!.amountPaise, 200000);
    });

    test('resolves debit even though the payee was credited', () {
      expect(parse(body)!.transactionType, TransactionType.expense);
    });

    test('extracts bank, account, balance and UPI reference', () {
      final message = parse(body)!;
      expect(message.bankName, 'IDBI Bank');
      expect(message.accountHint, 'XX330');
      expect(message.accountHintDigits, '330');
      expect(message.balancePaise, 1823989);
      expect(message.referenceId, '433702683217');
    });

    test('uses the date printed in the message', () {
      expect(parse(body)!.date, DateTime(2026, 7, 31));
    });

    test('names the counterparty', () {
      expect(parse(body)!.merchant, 'PREM BANGELS ST');
    });
  });

  group('other banks', () {
    test('ICICI debit', () {
      final message = parse(
        'ICICI Bank Acct XX789 debited for Rs 1,250.50 on 15-Jun-26. '
        'Info: UPI/612345678901.',
        sender: 'VM-ICICIB',
      )!;
      expect(message.bankName, 'ICICI Bank');
      expect(message.amountPaise, 125050);
      expect(message.transactionType, TransactionType.expense);
      expect(message.accountHint, 'XX789');
    });

    test('HDFC credit keeps direction and balance apart', () {
      final message = parse(
        'Rs.5000.00 credited to HDFC Bank A/c XX4567 on 02-Aug-26. '
        'Avl Bal Rs.42350.75',
        sender: 'JD-HDFCBK',
      )!;
      expect(message.transactionType, TransactionType.income);
      expect(message.amountPaise, 500000);
      expect(message.balancePaise, 4235075);
    });

    test('SBI withdrawal', () {
      final message = parse(
        'Dear Customer, Rs.3000 withdrawn from A/c X1234 on 10-Jul-26. '
        'Avl Bal Rs 7500.00',
        sender: 'AX-SBIINB',
      )!;
      expect(message.bankName, 'State Bank of India');
      expect(message.transactionType, TransactionType.expense);
      expect(message.amountPaise, 300000);
    });

    test('unknown sender falls back without crashing', () {
      final message = parse(
        'Acct XX111 debited for INR 99 on 01-Aug-26',
        sender: 'ZZ-NOSUCH',
      )!;
      expect(message.amountPaise, 9900);
      expect(message.bankName, 'ZZ-NOSUCH');
    });
  });

  group('messages that must never become transactions', () {
    test('OTP', () {
      expect(
        parse('123456 is your OTP for a txn of Rs 2000 on your card'),
        isNull,
      );
    });

    test('UPI collect request', () {
      expect(
        parse('You have a collect request of Rs 500 from user@upi'),
        isNull,
      );
    });

    test('failed transaction', () {
      expect(
        parse('Your txn of Rs 2000 on Acct XX330 has failed'),
        isNull,
      );
    });

    test('payment due reminder', () {
      expect(
        parse('Total amount due Rs 5,600 on your card XX330 due on 05-Aug-26'),
        isNull,
      );
    });

    test('scheduled future debit', () {
      expect(
        parse('Rs 1200 will be debited from A/c XX330 towards SIP'),
        isNull,
      );
    });

    test('promotional offer', () {
      expect(
        parse('Congratulations! You are pre-approved for Rs 5,00,000. '
                'Apply now'),
        isNull,
      );
    });

    test('message with no amount', () {
      expect(parse('Your account statement is ready'), isNull);
    });

    test('amount with no direction word', () {
      expect(parse('Your balance on A/c XX330 is Rs 1000'), isNull);
    });
  });

  group('confidence', () {
    test('rises when the message is fully structured', () {
      final message = parse(
        'ICICI Bank Acct XX789 debited for Rs 100 on 15-Jun-26. '
        'Avl Bal Rs 900. UPI:123456789012',
        sender: 'VM-ICICIB',
      )!;
      expect(message.confidence, greaterThan(0.8));
    });

    test('stays lower when both directions appear', () {
      const body =
          'IDBI Bank Acct XX330 debited for Rs 2000.00 on 31-Jul-26; '
          'Bal Rs 18239.89 PREM BANGELS ST credited. UPI:433702683217';
      final message = parse(body)!;
      expect(message.confidence, lessThan(0.85));
    });
  });
}
