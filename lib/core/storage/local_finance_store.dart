import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/finance_models.dart';

class LocalFinanceStore {
  static const _transactionsKey = 'founder_finance.transactions.v1';

  Future<List<FinanceTransaction>?> readTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_transactionsKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => FinanceTransaction.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveTransactions(List<FinanceTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      transactions.map((txn) => txn.toJson()).toList(),
    );
    await prefs.setString(_transactionsKey, payload);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_transactionsKey);
  }
}
