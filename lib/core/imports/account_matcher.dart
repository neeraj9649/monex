import '../../shared/models/finance_models.dart';
import '../../shared/models/imported_bank_message.dart';

/// Decides which stored account an imported bank message belongs to.
class AccountMatcher {
  const AccountMatcher._();

  /// Returns the best matching account id, or `null` when nothing is
  /// confident enough to pick.
  ///
  /// Digits win over names: two accounts at the same bank are only told apart
  /// by the number printed in the SMS.
  static String? match({
    required ImportedBankMessage message,
    required List<Account> accounts,
  }) {
    if (accounts.isEmpty) return null;

    final digits = message.accountHintDigits;
    if (digits.isNotEmpty) {
      final byDigits = accounts.where((account) {
        final stored = account.accountNumberDigits;
        if (stored.isEmpty) return false;
        // Banks mask to varying lengths, so accept either side as the suffix.
        return stored.endsWith(digits) || digits.endsWith(stored);
      }).toList();

      if (byDigits.length == 1) return byDigits.first.id;
      if (byDigits.length > 1) {
        // Ambiguous digits: fall back to the one whose bank also agrees.
        final refined = byDigits
            .where((account) => _bankMatches(message.bankName, account))
            .toList();
        if (refined.length == 1) return refined.first.id;
        return null;
      }
    }

    final byBank = accounts
        .where((account) => _bankMatches(message.bankName, account))
        .toList();
    return byBank.length == 1 ? byBank.first.id : null;
  }

  static bool _bankMatches(String bankName, Account account) {
    final bank = bankName.toLowerCase().trim();
    if (bank.isEmpty) return false;

    final institution = (account.institution ?? '').toLowerCase().trim();
    if (institution.isNotEmpty &&
        (bank.contains(institution) || institution.contains(bank))) {
      return true;
    }

    // Compare on the distinctive first word: "IDBI Bank" -> "idbi", which
    // still matches an account named "IDBI Current".
    final token = bank.split(RegExp(r'\s+')).first;
    if (token.length < 3) return false;
    return account.name.toLowerCase().contains(token);
  }
}
