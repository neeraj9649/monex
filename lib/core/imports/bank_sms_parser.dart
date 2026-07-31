import 'package:uuid/uuid.dart';

import '../../shared/models/enums.dart';
import '../../shared/models/imported_bank_message.dart';

class BankSmsParser {
  static const _uuid = Uuid();

  static ImportedBankMessage? parse({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    final normalized = body.replaceAll('\n', ' ');
    final amount = _amountFrom(normalized);
    if (amount == null) return null;

    final lower = normalized.toLowerCase();
    final isDebit = RegExp(
      r'\b(debited|spent|paid|withdrawn|dr|purchase|sent)\b',
    ).hasMatch(lower);
    final isCredit = RegExp(
      r'\b(credited|received|deposited|cr|refund|cashback)\b',
    ).hasMatch(lower);
    if (!isDebit && !isCredit) return null;

    return ImportedBankMessage(
      id: _uuid.v4(),
      sender: sender,
      body: body,
      date: date,
      amountPaise: amount,
      bankName: _bankName(sender, normalized),
      accountHint: _accountHint(normalized),
      transactionType: isCredit
          ? TransactionType.income
          : TransactionType.expense,
      confidence: isDebit && isCredit ? .62 : .86,
    );
  }

  static int? _amountFrom(String text) {
    final match = RegExp(
      r'(?:INR|Rs\.?|₹)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    final amount = double.tryParse(match.group(1)!.replaceAll(',', ''));
    return amount == null ? null : (amount * 100).round();
  }

  static String _accountHint(String text) {
    final match = RegExp(
      r'(?:A/c|Acct|account|card|xx|ending)\s*(?:no\.?)?\s*([xX*\d -]{3,12})',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1)?.trim() ?? 'Not detected';
  }

  static String _bankName(String sender, String text) {
    final source = '$sender $text'.toUpperCase();
    const banks = {
      'HDFC': 'HDFC Bank',
      'ICICI': 'ICICI Bank',
      'AXIS': 'Axis Bank',
      'SBI': 'State Bank of India',
      'KOTAK': 'Kotak Mahindra Bank',
      'YES': 'Yes Bank',
      'IDFC': 'IDFC First Bank',
      'INDUS': 'IndusInd Bank',
      'BOB': 'Bank of Baroda',
    };
    for (final entry in banks.entries) {
      if (source.contains(entry.key)) return entry.value;
    }
    return sender;
  }
}
