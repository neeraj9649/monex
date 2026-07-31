import 'dart:math';

class EmiCalculator {
  const EmiCalculator._();

  static int calculateMonthlyEmi({
    required int principalPaise,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    if (principalPaise <= 0 || tenureMonths <= 0) return 0;
    final monthlyRate = annualInterestRate / 12 / 100;
    if (monthlyRate == 0) return (principalPaise / tenureMonths).round();
    final factor = pow(1 + monthlyRate, tenureMonths);
    return (principalPaise * monthlyRate * factor / (factor - 1)).round();
  }

  static List<EmiScheduleItem> buildSchedule({
    required int principalPaise,
    required double annualInterestRate,
    required int tenureMonths,
    required DateTime startDate,
    int paidCount = 0,
  }) {
    final emi = calculateMonthlyEmi(
      principalPaise: principalPaise,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
    );
    final monthlyRate = annualInterestRate / 12 / 100;
    var balance = principalPaise;
    final items = <EmiScheduleItem>[];

    for (var i = 1; i <= tenureMonths; i++) {
      final interest = (balance * monthlyRate).round();
      var principal = emi - interest;
      if (i == tenureMonths || principal > balance) {
        principal = balance;
      }
      final payment = principal + interest;
      balance = (balance - principal).clamp(0, principalPaise);
      items.add(
        EmiScheduleItem(
          index: i,
          dueDate: DateTime(startDate.year, startDate.month + i, startDate.day),
          amountPaise: payment,
          principalPaise: principal,
          interestPaise: interest,
          remainingBalancePaise: balance,
          isPaid: i <= paidCount,
        ),
      );
    }
    return items;
  }
}

class EmiScheduleItem {
  const EmiScheduleItem({
    required this.index,
    required this.dueDate,
    required this.amountPaise,
    required this.principalPaise,
    required this.interestPaise,
    required this.remainingBalancePaise,
    required this.isPaid,
  });

  final int index;
  final DateTime dueDate;
  final int amountPaise;
  final int principalPaise;
  final int interestPaise;
  final int remainingBalancePaise;
  final bool isPaid;
}
