import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/imports/account_matcher.dart';
import '../../core/imports/bank_sms_parser.dart';
import '../../core/sms/captured_sms.dart';
import '../../core/sms/sms_capture_service.dart';
import '../../core/sms/sms_import_store.dart';
import '../models/imported_bank_message.dart';
import 'finance_providers.dart';

final smsCaptureServiceProvider = Provider<SmsCaptureService>(
  (ref) => SmsCaptureService(),
);

final smsImportStoreProvider = Provider<SmsImportStore>(
  (ref) => SmsImportStore(),
);

class SmsImportState {
  const SmsImportState({
    this.drafts = const [],
    this.autoCaptureEnabled = false,
    this.permissionGranted = false,
    this.isScanning = false,
    this.lastScanAt,
    this.message,
  });

  /// Parsed bank messages waiting for you to approve them.
  final List<ImportedBankMessage> drafts;
  final bool autoCaptureEnabled;
  final bool permissionGranted;
  final bool isScanning;
  final DateTime? lastScanAt;
  final String? message;

  bool get isSupported => true;

  SmsImportState copyWith({
    List<ImportedBankMessage>? drafts,
    bool? autoCaptureEnabled,
    bool? permissionGranted,
    bool? isScanning,
    DateTime? lastScanAt,
    String? message,
  }) => SmsImportState(
    drafts: drafts ?? this.drafts,
    autoCaptureEnabled: autoCaptureEnabled ?? this.autoCaptureEnabled,
    permissionGranted: permissionGranted ?? this.permissionGranted,
    isScanning: isScanning ?? this.isScanning,
    lastScanAt: lastScanAt ?? this.lastScanAt,
    message: message,
  );
}

class SmsImportController extends Notifier<SmsImportState> {
  @override
  SmsImportState build() {
    Future.microtask(restore);
    return const SmsImportState();
  }

  SmsCaptureService get _capture => ref.read(smsCaptureServiceProvider);
  SmsImportStore get _store => ref.read(smsImportStoreProvider);

  bool get isSupported => _capture.isSupported;

  /// Loads saved settings and picks up anything captured while MONEX was
  /// closed. Safe to call on every app resume.
  Future<void> restore() async {
    if (!_capture.isSupported) return;

    final enabled = await _store.readAutoCaptureEnabled();
    final granted = await _capture.hasPermission();
    state = state.copyWith(
      autoCaptureEnabled: enabled,
      permissionGranted: granted,
      lastScanAt: await _store.readLastScan(),
    );

    if (!enabled || !granted) return;
    await _capture.startListening();
    await drainBackground();
  }

  /// Turns auto capture on, requesting SMS permission the first time.
  Future<void> setAutoCapture(bool enabled) async {
    if (!_capture.isSupported) {
      state = state.copyWith(
        message: 'SMS import is available on Android only',
      );
      return;
    }

    if (!enabled) {
      await _store.writeAutoCaptureEnabled(false);
      state = state.copyWith(
        autoCaptureEnabled: false,
        message: 'Automatic bank SMS import turned off',
      );
      return;
    }

    final granted = await _capture.ensurePermission();
    if (!granted) {
      state = state.copyWith(
        autoCaptureEnabled: false,
        permissionGranted: false,
        message: 'SMS permission denied. Enable it in Android settings.',
      );
      return;
    }

    await _store.writeAutoCaptureEnabled(true);
    await _capture.startListening();
    state = state.copyWith(
      autoCaptureEnabled: true,
      permissionGranted: true,
      message: 'Automatic bank SMS import turned on',
    );
    await scanInbox();
  }

  /// Reads the device inbox and queues any new bank messages.
  Future<void> scanInbox({Duration window = const Duration(days: 30)}) async {
    if (!_capture.isSupported) return;
    if (!await _capture.hasPermission()) {
      state = state.copyWith(message: 'SMS permission not granted');
      return;
    }

    state = state.copyWith(isScanning: true, message: null);
    final since = state.lastScanAt ?? DateTime.now().subtract(window);
    final captured = await _capture.readInbox(since: since);
    final added = await _ingest(captured);

    final now = DateTime.now();
    await _store.writeLastScan(now);
    state = state.copyWith(
      isScanning: false,
      lastScanAt: now,
      message: added == 0
          ? 'No new bank messages found'
          : 'Found $added new bank ${added == 1 ? 'message' : 'messages'}',
    );
  }

  /// Pulls in messages the background receiver stored while MONEX was closed.
  Future<void> drainBackground() async {
    if (!_capture.isSupported) return;
    final queued = await _store.drainBackgroundQueue();
    if (queued.isEmpty) return;
    final added = await _ingest(queued);
    if (added > 0) {
      state = state.copyWith(
        message: 'Captured $added new bank ${added == 1 ? 'message' : 'messages'}',
      );
    }
  }

  /// Approves a draft and writes it into the ledger.
  Future<void> approve({
    required ImportedBankMessage message,
    required String category,
    required String accountId,
    required String description,
  }) async {
    await ref
        .read(financeControllerProvider.notifier)
        .addImportedBankMessage(
          message: message,
          category: category,
          accountId: accountId,
          description: description,
        );
    await _forget(message);
    state = state.copyWith(message: 'Added to ledger');
  }

  /// Drops a draft without creating a transaction.
  Future<void> dismiss(ImportedBankMessage message) async {
    await _forget(message);
    state = state.copyWith(message: 'Import dismissed');
  }

  Future<void> _forget(ImportedBankMessage message) async {
    await _store.markProcessed([_signatureOf(message)]);
    state = state.copyWith(
      drafts: state.drafts.where((item) => item.id != message.id).toList(),
    );
  }

  /// Parses raw messages, drops duplicates and non-transactions, and matches
  /// each survivor to an account. Returns how many drafts were added.
  Future<int> _ingest(List<CapturedSms> captured) async {
    if (captured.isEmpty) return 0;

    final processed = await _store.readProcessed();
    final queued = state.drafts.map(_signatureOf).toSet();
    final accounts = ref.read(financeControllerProvider).accounts;

    final fresh = <ImportedBankMessage>[];
    for (final sms in captured) {
      final signature = sms.signature;
      if (processed.contains(signature) || queued.contains(signature)) continue;

      final parsed = BankSmsParser.parse(
        sender: sms.sender,
        body: sms.body,
        date: sms.receivedAt,
      );
      if (parsed == null) continue;

      queued.add(signature);
      fresh.add(
        parsed.copyWith(
          captureSignature: signature,
          matchedAccountId: AccountMatcher.match(
            message: parsed,
            accounts: accounts,
          ),
        ),
      );
    }

    if (fresh.isEmpty) return 0;
    state = state.copyWith(drafts: [...fresh, ...state.drafts]);
    return fresh.length;
  }

  /// The capture signature attached at ingest time.
  ///
  /// Falls back to recomputing only for drafts created outside the capture
  /// pipeline, such as a message pasted by hand.
  String _signatureOf(ImportedBankMessage message) =>
      message.captureSignature ??
      CapturedSms(
        sender: message.sender,
        body: message.body,
        receivedAt: message.date,
      ).signature;
}

final smsImportControllerProvider =
    NotifierProvider<SmsImportController, SmsImportState>(
      SmsImportController.new,
    );
