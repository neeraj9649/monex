import 'dart:convert';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'captured_sms.dart';
import 'sms_capture_service.dart';

/// Runs in a separate isolate when an SMS arrives and MONEX is backgrounded.
///
/// Must stay top level, cheap, and annotated so AOT keeps it alive.
@pragma('vm:entry-point')
Future<void> monexBackgroundSmsHandler(SmsMessage message) async {
  final body = message.body;
  if (body == null || body.isEmpty) return;

  final captured = CapturedSms(
    sender: message.address ?? 'Unknown',
    body: body,
    receivedAt: message.date == null
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(message.date!),
  );

  final prefs = await SharedPreferences.getInstance();
  final queue = prefs.getStringList(pendingBackgroundSmsKey) ?? <String>[];
  queue.add(jsonEncode(captured.toJson()));
  // Cap the queue so a burst of messages cannot grow it without bound.
  final trimmed = queue.length > 200
      ? queue.sublist(queue.length - 200)
      : queue;
  await prefs.setStringList(pendingBackgroundSmsKey, trimmed);
}

class SmsCaptureServiceImpl implements SmsCaptureService {
  /// Android has no silent "is SMS permission granted" query, so the outcome
  /// of the last request is remembered and corrected if a read later fails.
  static const _grantedKey = 'monex.sms.permission_granted';

  final Telephony _telephony = Telephony.instance;
  bool _listening = false;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_grantedKey) ?? false;
  }

  @override
  Future<bool> ensurePermission() async {
    if (!isSupported) return false;
    try {
      final granted = await _telephony.requestSmsPermissions ?? false;
      await _setGranted(granted);
      return granted;
    } on Exception {
      await _setGranted(false);
      return false;
    }
  }

  @override
  Future<List<CapturedSms>> readInbox({
    DateTime? since,
    int limit = 200,
  }) async {
    // ensurePermission rather than hasPermission: Android returns immediately
    // without a dialog when the permission is already granted, so this also
    // repairs a stale saved flag instead of silently reading nothing.
    if (!isSupported || !await ensurePermission()) return const [];

    try {
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: since == null
            ? null
            : SmsFilter.where(
                SmsColumn.DATE,
              ).greaterThan(since.millisecondsSinceEpoch.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      return messages
          .where((message) => (message.body ?? '').isNotEmpty)
          .take(limit)
          .map(
            (message) => CapturedSms(
              sender: message.address ?? 'Unknown',
              body: message.body!,
              receivedAt: message.date == null
                  ? DateTime.now()
                  : DateTime.fromMillisecondsSinceEpoch(message.date!),
            ),
          )
          .toList();
    } on Exception {
      // Permission was revoked in Android settings after we recorded it.
      await _setGranted(false);
      return const [];
    }
  }

  @override
  Future<void> startListening({
    required void Function(CapturedSms) onForegroundMessage,
  }) async {
    if (!isSupported || _listening) return;
    if (!await ensurePermission()) return;

    try {
      _telephony.listenIncomingSms(
        // Delivered on the main isolate while MONEX is on screen, so this
        // hands the message straight to the UI instead of parking it in the
        // queue where nothing would drain it until the next resume.
        onNewMessage: (message) {
          final captured = _toCaptured(message);
          if (captured != null) onForegroundMessage(captured);
        },
        onBackgroundMessage: monexBackgroundSmsHandler,
      );
      _listening = true;
    } on Exception {
      _listening = false;
    }
  }

  static CapturedSms? _toCaptured(SmsMessage message) {
    final body = message.body;
    if (body == null || body.isEmpty) return null;
    return CapturedSms(
      sender: message.address ?? 'Unknown',
      body: body,
      receivedAt: message.date == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(message.date!),
    );
  }

  Future<void> _setGranted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_grantedKey, value);
  }
}
