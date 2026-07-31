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
  });

  final String id;
  final String sender;
  final String body;
  final DateTime date;
  final int amountPaise;
  final String bankName;
  final String accountHint;
  final TransactionType transactionType;
  final double confidence;

  bool get isCredit => transactionType == TransactionType.income;
}
