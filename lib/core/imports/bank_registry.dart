/// Bank identification for incoming SMS.
///
/// Indian bank SMS arrives from alphanumeric sender IDs such as `AD-IDBIBK`
/// or `VM-ICICIB`. [BankRegistry.resolve] strips the carrier prefix and
/// matches the remaining token against [BankDefinition.aliases].
class BankDefinition {
  const BankDefinition({required this.name, required this.aliases});

  final String name;

  /// Uppercase fragments that identify this bank in a sender ID or body.
  final List<String> aliases;
}

class BankRegistry {
  const BankRegistry._();

  /// Ordered most-specific first: `IDBIBK` must win before a bare `IDBI`,
  /// and `BOBIBN` before `BOB`, otherwise a shorter alias swallows the match.
  static const banks = <BankDefinition>[
    BankDefinition(name: 'IDBI Bank', aliases: ['IDBIBK', 'IDBIBANK', 'IDBI']),
    BankDefinition(
      name: 'ICICI Bank',
      aliases: ['ICICIB', 'ICICIBANK', 'ICICI'],
    ),
    BankDefinition(name: 'HDFC Bank', aliases: ['HDFCBK', 'HDFCBANK', 'HDFC']),
    BankDefinition(
      name: 'State Bank of India',
      aliases: ['SBIINB', 'SBIUPI', 'SBIPSG', 'ATMSBI', 'SBICRD', 'SBI'],
    ),
    BankDefinition(name: 'Axis Bank', aliases: ['AXISBK', 'AXISBANK', 'AXIS']),
    BankDefinition(
      name: 'Kotak Mahindra Bank',
      aliases: ['KOTAKB', 'KOTAKBANK', 'KOTAK'],
    ),
    BankDefinition(
      name: 'Punjab National Bank',
      aliases: ['PNBSMS', 'PNBBNK', 'PNB'],
    ),
    BankDefinition(
      name: 'Bank of Baroda',
      aliases: ['BOBIBN', 'BOBTXN', 'BARODA', 'BOB'],
    ),
    BankDefinition(name: 'Canara Bank', aliases: ['CANBNK', 'CANARA']),
    BankDefinition(name: 'Union Bank of India', aliases: ['UNIONB', 'UNIONBK']),
    BankDefinition(name: 'IDFC First Bank', aliases: ['IDFCFB', 'IDFC']),
    BankDefinition(name: 'IndusInd Bank', aliases: ['INDUSB', 'INDUSIND']),
    BankDefinition(name: 'Yes Bank', aliases: ['YESBNK', 'YESBANK']),
    BankDefinition(name: 'RBL Bank', aliases: ['RBLBNK', 'RBLBANK']),
    BankDefinition(name: 'Federal Bank', aliases: ['FEDBNK', 'FEDERAL']),
    BankDefinition(name: 'Bank of India', aliases: ['BOIIND', 'BOISMS']),
    BankDefinition(name: 'Central Bank of India', aliases: ['CBIINB', 'CENTBK']),
    BankDefinition(name: 'Indian Bank', aliases: ['INDBNK', 'INDIANBK']),
    BankDefinition(name: 'UCO Bank', aliases: ['UCOBNK', 'UCOBANK']),
    BankDefinition(name: 'Paytm Payments Bank', aliases: ['PYTMBK', 'PAYTMB']),
    BankDefinition(name: 'Airtel Payments Bank', aliases: ['AIRBNK', 'AIRTELB']),
    BankDefinition(name: 'AU Small Finance Bank', aliases: ['AUBANK', 'AUSFBL']),
    BankDefinition(name: 'Bandhan Bank', aliases: ['BANDHN', 'BANDHAN']),
    BankDefinition(name: 'Karnataka Bank', aliases: ['KARBNK', 'KTKBNK']),
    BankDefinition(name: 'South Indian Bank', aliases: ['SIBSMS', 'SIBLTD']),
  ];

  /// Resolves a display name for the bank behind [sender].
  ///
  /// Falls back to scanning [body] (many banks sign off with their own name),
  /// then to the raw sender so nothing is silently dropped.
  static String resolve({required String sender, required String body}) {
    final senderToken = _senderToken(sender);
    for (final bank in banks) {
      for (final alias in bank.aliases) {
        if (senderToken.contains(alias)) return bank.name;
      }
    }

    final upperBody = body.toUpperCase();
    for (final bank in banks) {
      for (final alias in bank.aliases) {
        if (upperBody.contains(alias)) return bank.name;
      }
    }

    return sender.trim().isEmpty ? 'Unknown bank' : sender.trim();
  }

  /// `AD-IDBIBK-S` becomes `IDBIBK`; a plain sender is returned uppercased.
  static String _senderToken(String sender) {
    final upper = sender.toUpperCase();
    final parts = upper.split(RegExp(r'[-_\s]'));
    if (parts.length <= 1) return upper.replaceAll(RegExp(r'[^A-Z0-9]'), '');

    // Carrier prefixes are two characters (AD, VM, JD); the bank token is the
    // longest remaining part.
    final candidates = parts.where((part) => part.length > 2).toList();
    if (candidates.isEmpty) return upper.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first.replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}
