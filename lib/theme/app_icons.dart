import 'package:flutter/material.dart';

import '../shared/models/enums.dart';

class AppIcons {
  const AppIcons._();

  static IconData transaction(TransactionType type) => switch (type) {
    TransactionType.expense => Icons.payments_rounded,
    TransactionType.income => Icons.trending_up_rounded,
    TransactionType.transfer => Icons.swap_horiz_rounded,
    TransactionType.emiPayment => Icons.event_repeat_rounded,
    TransactionType.moneyBorrowed => Icons.call_received_rounded,
    TransactionType.moneyLent => Icons.call_made_rounded,
    TransactionType.repayment => Icons.assignment_return_rounded,
    TransactionType.receivableCollection => Icons.task_alt_rounded,
    TransactionType.loan => Icons.account_balance_rounded,
  };

  static IconData account(AccountType type) => switch (type) {
    AccountType.cash => Icons.account_balance_wallet_rounded,
    AccountType.bank => Icons.account_balance_rounded,
    AccountType.creditCard => Icons.credit_card_rounded,
    AccountType.debitCard => Icons.credit_card_rounded,
    AccountType.upi => Icons.qr_code_2_rounded,
    AccountType.wallet => Icons.wallet_rounded,
    AccountType.companyBank => Icons.business_rounded,
    AccountType.investment => Icons.show_chart_rounded,
    AccountType.custom => Icons.account_balance_wallet_rounded,
  };

  static IconData scope(FinanceScope scope) => switch (scope) {
    FinanceScope.personal => Icons.person_rounded,
    FinanceScope.company => Icons.business_center_rounded,
  };
}
