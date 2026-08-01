import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'captured_sms.dart';

/// Remembers which messages MONEX has already handled, so a message is never
/// turned into a second transaction after an import, a dismissal, or a rescan.
class SmsImportStore {
  static const _processedKey = 'monex.sms.processed_signatures';
  static const _lastScanKey = 'monex.sms.last_scan_at';
  static const _enabledKey = 'monex.sms.auto_capture_enabled';

  /// Keeps the processed list bounded; older entries fall out of the inbox
  /// window anyway.
  static const _maxProcessed = 1000;

  Future<Set<String>> readProcessed() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_processedKey) ?? const <String>[]).toSet();
  }

  Future<void> markProcessed(Iterable<String> signatures) async {
    if (signatures.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_processedKey) ?? <String>[];
    existing.addAll(signatures);
    final trimmed = existing.length > _maxProcessed
        ? existing.sublist(existing.length - _maxProcessed)
        : existing;
    await prefs.setStringList(_processedKey, trimmed);
  }

  Future<DateTime?> readLastScan() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastScanKey);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> writeLastScan(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastScanKey, value.millisecondsSinceEpoch);
  }

  Future<bool> readAutoCaptureEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> writeAutoCaptureEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  /// Takes everything the background isolate queued and clears the queue.
  Future<List<CapturedSms>> drainBackgroundQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(pendingBackgroundSmsKey) ?? const <String>[];
    if (raw.isEmpty) return const [];
    await prefs.remove(pendingBackgroundSmsKey);

    final drained = <CapturedSms>[];
    for (final entry in raw) {
      try {
        drained.add(
          CapturedSms.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        );
      } on FormatException {
        // A corrupt queue entry must not block the rest of the import.
        continue;
      }
    }
    return drained;
  }
}
