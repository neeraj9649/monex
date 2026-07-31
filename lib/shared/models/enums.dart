enum FinanceScope { personal, company }

enum TransactionType {
  expense,
  income,
  transfer,
  loan,
  emiPayment,
  moneyBorrowed,
  moneyLent,
  repayment,
  receivableCollection,
}

enum TransactionStatus { paid, pending, overdue, settled, partial, draft }

enum AccountType {
  cash,
  bank,
  creditCard,
  debitCard,
  upi,
  wallet,
  companyBank,
  investment,
  custom,
}

enum PaymentMethod {
  cash,
  bankTransfer,
  creditCard,
  debitCard,
  upi,
  wallet,
  cheque,
}

enum LoanType {
  personal,
  business,
  home,
  vehicle,
  creditCardEmi,
  education,
  friendsFamily,
  custom,
}

enum ReminderType {
  emi,
  loan,
  creditCard,
  payable,
  receivable,
  recurringBill,
  subscription,
  expectedIncome,
  budget,
  overdue,
}

extension EnumLabel on Enum {
  String get label {
    final value = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return value[0].toUpperCase() + value.substring(1);
  }
}
