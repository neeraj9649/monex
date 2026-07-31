import 'package:intl/intl.dart';

class Money {
  const Money._();

  static final NumberFormat _rupee = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static int fromRupees(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.-]'), '');
    final amount = double.tryParse(cleaned);
    if (amount == null) {
      throw const FormatException('Enter a valid amount');
    }
    return (amount * 100).round();
  }

  static String format(int paise, {bool compact = false}) {
    final rupees = paise / 100;
    if (!compact) return _rupee.format(rupees);
    final abs = rupees.abs();
    if (abs >= 10000000) return '₹${(rupees / 10000000).toStringAsFixed(2)} Cr';
    if (abs >= 100000) return '₹${(rupees / 100000).toStringAsFixed(2)} L';
    if (abs >= 1000) return '₹${(rupees / 1000).toStringAsFixed(1)} K';
    return _rupee.format(rupees);
  }

  static String signed(int paise) {
    if (paise == 0) return format(0);
    return '${paise > 0 ? '+' : '-'}${format(paise.abs())}';
  }
}
