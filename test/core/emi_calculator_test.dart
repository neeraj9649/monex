import 'package:flutter_test/flutter_test.dart';
import 'package:founder_finance_manager/core/calculations/emi_calculator.dart';

void main() {
  group('EmiCalculator', () {
    test('calculates zero-interest EMI using equal principal split', () {
      final emi = EmiCalculator.calculateMonthlyEmi(
        principalPaise: 12000000,
        annualInterestRate: 0,
        tenureMonths: 12,
      );

      expect(emi, 1000000);
    });

    test('builds a schedule that fully amortizes the loan', () {
      final schedule = EmiCalculator.buildSchedule(
        principalPaise: 100000000,
        annualInterestRate: 10,
        tenureMonths: 12,
        startDate: DateTime(2026),
        paidCount: 3,
      );

      expect(schedule, hasLength(12));
      expect(schedule.take(3).every((item) => item.isPaid), isTrue);
      expect(schedule.last.remainingBalancePaise, 0);
      expect(
        schedule.fold<int>(0, (sum, item) => sum + item.principalPaise),
        100000000,
      );
    });
  });
}
