import 'enums.dart';

class ImportedBankMessage {
  const ImportedBankMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.date,
    required this.amountPaise,
    required this.bankName,
    required this.accountHint,
    required this.transactionType,
    required this.confidence,
    this.balancePaise,
    this.merchant,
    this.referenceId,
    this.matchedAccountId,
    this.captureSignature,
  });

  final String id;
  final String sender;
  final String body;

  /// Transaction date taken from the message text when present, otherwise the
  /// timestamp the SMS was received.
  final DateTime date;
  final int amountPaise;
  final String bankName;

  /// Account digits as printed in the message, for example `XX330`.
  final String accountHint;
  final TransactionType transactionType;

  /// 0..1 estimate of how confidently the message was understood.
  final double confidence;

  /// Closing balance reported by the bank, when the message includes one.
  final int? balancePaise;

  /// Counterparty or merchant name, best effort.
  final String? merchant;

  /// UPI reference, cheque number, or transaction id.
  final String? referenceId;

  /// Account this message was matched to, resolved after parsing.
  final String? matchedAccountId;

  /// Identity of the SMS this draft came from.
  ///
  /// Carried rather than recomputed: [date] may hold the date printed inside
  /// the message, which differs from when the SMS arrived, so recomputing
  /// would produce a different value and defeat duplicate detection.
  final String? captureSignature;

  bool get isCredit => transactionType == TransactionType.income;

  /// Trailing digits of [accountHint], used to match against stored accounts.
  String get accountHintDigits => accountHint.replaceAll(RegExp(r'[^0-9]'), '');

  ImportedBankMessage copyWith({
    String? matchedAccountId,
    String? captureSignature,
  }) => ImportedBankMessage(
        id: id,
        sender: sender,
        body: body,
        date: date,
        amountPaise: amountPaise,
        bankName: bankName,
        accountHint: accountHint,
        transactionType: transactionType,
        confidence: confidence,
        balancePaise: balancePaise,
        merchant: merchant,
    referenceId: referenceId,
    matchedAccountId: matchedAccountId ?? this.matchedAccountId,
    captureSignature: captureSignature ?? this.captureSignature,
  );
}
