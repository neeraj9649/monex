/// Messages received while MONEX was not in the foreground.
///
/// The background isolate cannot touch app state, so it parks raw messages
/// under this key and the UI drains them on next resume. Declared here, next
/// to the model, so both the Android implementation and the platform neutral
/// store can reach it.
const pendingBackgroundSmsKey = 'monex.sms.background_queue';

/// A raw SMS lifted off the device, before any bank parsing.
class CapturedSms {
  const CapturedSms({
    required this.sender,
    required this.body,
    required this.receivedAt,
  });

  final String sender;
  final String body;
  final DateTime receivedAt;

  /// Stable identity used to avoid importing the same SMS twice.
  ///
  /// Deliberately not [Object.hashCode]: that is not guaranteed to be stable
  /// across runs or isolates, and this value is persisted to disk and produced
  /// by the background isolate.
  String get signature {
    final minute = receivedAt.millisecondsSinceEpoch ~/ 60000;
    return '${sender.trim().toUpperCase()}|$minute|${_fnv1a(body)}';
  }

  Map<String, dynamic> toJson() => {
    'sender': sender,
    'body': body,
    'receivedAt': receivedAt.millisecondsSinceEpoch,
  };

  static CapturedSms fromJson(Map<String, dynamic> json) => CapturedSms(
    sender: json['sender'] as String? ?? '',
    body: json['body'] as String? ?? '',
    receivedAt: DateTime.fromMillisecondsSinceEpoch(
      json['receivedAt'] as int? ?? 0,
    ),
  );

  /// FNV-1a, 32 bit. Small, dependency free, and stable across processes.
  static String _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
