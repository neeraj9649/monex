import 'package:uuid/uuid.dart';

import '../../shared/models/enums.dart';
import '../../shared/models/imported_bank_message.dart';
import 'bank_registry.dart';

/// Parses Indian bank transaction SMS into a reviewable draft.
///
/// Returns `null` when the message is not a completed debit or credit, so
/// OTPs, payment requests, promotions and failure alerts never reach the
/// ledger.
class BankSmsParser {
  static const _uuid = Uuid();

  /// Words that mean money left the account.
  static final _debitWords = RegExp(
    r'\b(debited|debit|spent|withdrawn|withdrawal|paid|purchase|transferred|deducted|sent|dr)\b',
    caseSensitive: false,
  );

  /// Words that mean money entered the account.
  static final _creditWords = RegExp(
    r'\b(credited|credit|received|deposited|refund|refunded|cashback|reversed|cr)\b',
    caseSensitive: false,
  );

  /// Phrases that rule a message out even when it contains an amount.
  static final _rejectPatterns = RegExp(
    r'\b('
    r'otp|one[ -]?time[ -]?password|verification code|do not share|'
    r'will be (?:debited|deducted|charged)|'
    r'collect request|payment request|requesting|has requested|'
    r'is due|due on|minimum amount due|total amount due|'
    r'failed|declined|unsuccessful|insufficient|'
    r'apply now|click here|congratulations|pre-?approved|offer'
    r')\b',
    caseSensitive: false,
  );

  /// Trailing safety boilerplate; everything after it is noise for parsing.
  static final _trailerPatterns = RegExp(
    r'(to block|if not you|not you\?|to report|dispute|call 1800|'
    r'sms block|helpline|customer care|t&c apply)',
    caseSensitive: false,
  );

  static final _amountPattern = RegExp(
    r'(?:INR|Rs\.?|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  /// Balance wording that may immediately precede an amount.
  static final _balanceContext = RegExp(
    r'(bal|balance|limit|outstanding)[^0-9]{0,12}$',
    caseSensitive: false,
  );

  static ImportedBankMessage? parse({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return null;
    if (_rejectPatterns.hasMatch(normalized)) return null;

    final core = _stripTrailer(normalized);
    final amounts = _amountsIn(core);
    if (amounts.isEmpty) return null;

    final transaction = amounts.firstWhere(
      (amount) => !amount.isBalance,
      orElse: () => _Amount.none,
    );
    if (transaction.isNone) return null;

    final direction = _directionFor(core, transaction.offset);
    if (direction == null) return null;

    final balance = amounts.where((amount) => amount.isBalance).firstOrNull;
    final accountHint = _accountHint(core);
    final reference = _reference(core);
    final merchant = _merchant(core);

    return ImportedBankMessage(
      id: _uuid.v4(),
      sender: sender,
      body: body,
      date: _dateIn(core) ?? date,
      amountPaise: transaction.paise,
      bankName: BankRegistry.resolve(sender: sender, body: normalized),
      accountHint: accountHint ?? 'Not detected',
      transactionType: direction.isCredit
          ? TransactionType.income
          : TransactionType.expense,
      confidence: _confidence(
        unambiguous: direction.unambiguous,
        hasAccount: accountHint != null,
        hasBalance: balance != null,
        hasReference: reference != null,
      ),
      balancePaise: balance?.paise,
      merchant: merchant,
      referenceId: reference,
    );
  }

  static String _stripTrailer(String text) {
    final match = _trailerPatterns.firstMatch(text);
    if (match == null) return text;
    // Keep the trailer if cutting it would remove the whole message.
    return match.start < 20 ? text : text.substring(0, match.start).trim();
  }

  static List<_Amount> _amountsIn(String text) {
    return _amountPattern
        .allMatches(text)
        .map((match) {
          final raw = match.group(1)!.replaceAll(',', '');
          final value = double.tryParse(raw);
          final before = text.substring(0, match.start);
          return _Amount(
            paise: value == null ? 0 : (value * 100).round(),
            offset: match.start,
            isBalance: _balanceContext.hasMatch(before),
          );
        })
        .where((amount) => amount.paise > 0)
        .toList();
  }

  /// Picks the direction word closest to the transaction amount.
  ///
  /// Many messages mention both directions - `... debited for Rs 2000.00 ...
  /// PREM BANGELS ST credited` - so proximity to the amount, not mere
  /// presence, decides which one describes this account.
  static _Direction? _directionFor(String text, int amountOffset) {
    final debit = _nearestDistance(_debitWords, text, amountOffset);
    final credit = _nearestDistance(_creditWords, text, amountOffset);
    if (debit == null && credit == null) return null;
    if (credit == null) {
      return const _Direction(isCredit: false, unambiguous: true);
    }
    if (debit == null) {
      return const _Direction(isCredit: true, unambiguous: true);
    }
    return _Direction(isCredit: credit < debit, unambiguous: false);
  }

  static int? _nearestDistance(RegExp pattern, String text, int offset) {
    int? best;
    for (final match in pattern.allMatches(text)) {
      final distance = match.end <= offset
          ? offset - match.end
          : match.start - offset;
      final absolute = distance < 0 ? 0 : distance;
      if (best == null || absolute < best) best = absolute;
    }
    return best;
  }

  static String? _accountHint(String text) {
    final match = RegExp(
      r'(?:a/c|acct|account|card|ending(?:\s+with)?)\s*(?:no\.?|number)?[:\s]*'
      r'([xX*]{0,6}\s?\d{3,6})',
      caseSensitive: false,
    ).firstMatch(text);
    final value = match?.group(1)?.replaceAll(' ', '').trim();
    if (value != null && value.isNotEmpty) return value.toUpperCase();

    final bare = RegExp(r'\b([xX*]{2,6}\d{3,6})\b').firstMatch(text);
    return bare?.group(1)?.toUpperCase();
  }

  static String? _reference(String text) {
    final upi = RegExp(
      r'\b(?:upi|rrn)\s*(?:ref(?:erence)?)?\s*(?:no\.?|id)?[:\s-]*(\d{6,})',
      caseSensitive: false,
    ).firstMatch(text);
    if (upi != null) return upi.group(1);

    final ref = RegExp(
      r'\b(?:ref(?:erence)?|txn|transaction|utr|cheque|chq)\s*'
      r'(?:no\.?|id)?[:\s-]*([A-Za-z0-9]{4,})',
      caseSensitive: false,
    ).firstMatch(text);
    return ref?.group(1);
  }

  /// Best effort counterparty name. Returns `null` rather than guessing badly.
  static String? _merchant(String text) {
    // `Bal Rs 18239.89 PREM BANGELS ST credited` - the party is named after
    // the balance and before the second direction verb.
    final afterBalance = RegExp(
      r'(?:bal|balance)[^0-9]{0,12}(?:INR|Rs\.?|₹)?\s*[0-9][0-9,]*'
      r'(?:\.[0-9]{1,2})?\s+'
      r"([A-Za-z][A-Za-z0-9&.'\-/ ]{2,40}?)\s+(?:credited|debited)",
      caseSensitive: false,
    ).firstMatch(text);
    if (afterBalance != null) return _cleanMerchant(afterBalance.group(1));

    final directed = RegExp(
      r'\b(?:trf to|transfer to|sent to|paid to|payment to|at|to|from)\s+'
      r"([A-Za-z][A-Za-z0-9&.'\-/ ]{2,40}?)"
      r'(?=\s+(?:on|ref|upi|bal|via|dated|a/c|acct)\b|[.;,]|$)',
      caseSensitive: false,
    ).firstMatch(text);
    return _cleanMerchant(directed?.group(1));
  }

  static String? _cleanMerchant(String? value) {
    final cleaned = value?.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned == null || cleaned.length < 3) return null;
    if (RegExp(
      r'^(your|the|account|acct|card|bank|rs|inr)$',
      caseSensitive: false,
    ).hasMatch(cleaned)) {
      return null;
    }
    return cleaned;
  }

  static DateTime? _dateIn(String text) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final named = RegExp(
      r'\b(\d{1,2})[-/ ]([A-Za-z]{3})[a-z]*[-/ ](\d{2,4})\b',
    ).firstMatch(text);
    if (named != null) {
      final month = months[named.group(2)!.toLowerCase()];
      if (month != null) {
        return _build(
          int.parse(named.group(1)!),
          month,
          int.parse(named.group(3)!),
        );
      }
    }

    final numeric = RegExp(
      r'\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\b',
    ).firstMatch(text);
    if (numeric != null) {
      return _build(
        int.parse(numeric.group(1)!),
        int.parse(numeric.group(2)!),
        int.parse(numeric.group(3)!),
      );
    }
    return null;
  }

  static DateTime? _build(int day, int month, int year) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final fullYear = year < 100 ? 2000 + year : year;
    final date = DateTime(fullYear, month, day);
    // Guard against overflow such as 31 February rolling into March.
    if (date.day != day || date.month != month) return null;
    return date;
  }

  static double _confidence({
    required bool unambiguous,
    required bool hasAccount,
    required bool hasBalance,
    required bool hasReference,
  }) {
    var score = 0.5;
    if (unambiguous) score += 0.2;
    if (hasAccount) score += 0.15;
    if (hasBalance) score += 0.1;
    if (hasReference) score += 0.05;
    return score > 0.98 ? 0.98 : score;
  }
}

class _Amount {
  const _Amount({
    required this.paise,
    required this.offset,
    required this.isBalance,
  });

  static const none = _Amount(paise: -1, offset: -1, isBalance: false);

  final int paise;
  final int offset;
  final bool isBalance;

  bool get isNone => offset < 0;
}

class _Direction {
  const _Direction({required this.isCredit, required this.unambiguous});

  final bool isCredit;
  final bool unambiguous;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
