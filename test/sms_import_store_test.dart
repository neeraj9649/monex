import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:founder_finance_manager/core/sms/captured_sms.dart';
import 'package:founder_finance_manager/core/sms/sms_import_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  CapturedSms sms(String body, {String sender = 'AD-IDBIBK', DateTime? at}) =>
      CapturedSms(
        sender: sender,
        body: body,
        receivedAt: at ?? DateTime(2026, 8, 2, 10, 30),
      );

  group('capture signature', () {
    test('is stable across separate object instances', () {
      expect(sms('Rs 100 debited').signature, sms('Rs 100 debited').signature);
    });

    test('differs when the body differs', () {
      expect(
        sms('Rs 100 debited').signature,
        isNot(sms('Rs 200 debited').signature),
      );
    });

    test('differs when the sender differs', () {
      expect(
        sms('Rs 100 debited', sender: 'AD-IDBIBK').signature,
        isNot(sms('Rs 100 debited', sender: 'VM-ICICIB').signature),
      );
    });

    test('tolerates a small delivery time difference within the same minute', () {
      expect(
        sms('Rs 100', at: DateTime(2026, 8, 2, 10, 30, 5)).signature,
        sms('Rs 100', at: DateTime(2026, 8, 2, 10, 30, 45)).signature,
      );
    });

    test('does not use Object.hashCode, which is unstable across runs', () {
      // The signature must survive being written to disk by the background
      // isolate and read back by the UI isolate.
      final restored = CapturedSms.fromJson(
        jsonDecode(jsonEncode(sms('Rs 100 debited').toJson()))
            as Map<String, dynamic>,
      );
      expect(restored.signature, sms('Rs 100 debited').signature);
    });
  });

  group('processed signatures', () {
    test('round-trips what was marked', () async {
      final store = SmsImportStore();
      await store.markProcessed(['a', 'b']);
      expect(await store.readProcessed(), {'a', 'b'});
    });

    test('accumulates across calls', () async {
      final store = SmsImportStore();
      await store.markProcessed(['a']);
      await store.markProcessed(['b']);
      expect(await store.readProcessed(), {'a', 'b'});
    });

    test('marking nothing is a no-op', () async {
      final store = SmsImportStore();
      await store.markProcessed(const []);
      expect(await store.readProcessed(), isEmpty);
    });

    test('stays bounded so the list cannot grow forever', () async {
      final store = SmsImportStore();
      await store.markProcessed(List.generate(1200, (i) => 'sig-$i'));
      final processed = await store.readProcessed();
      expect(processed.length, lessThanOrEqualTo(1000));
      // The newest entries are the ones that matter, so they must survive.
      expect(processed, contains('sig-1199'));
    });
  });

  group('background queue', () {
    test('drains what the background isolate wrote, then clears', () async {
      final store = SmsImportStore();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(pendingBackgroundSmsKey, [
        jsonEncode(sms('Rs 100 debited').toJson()),
        jsonEncode(sms('Rs 200 credited').toJson()),
      ]);

      final drained = await store.drainBackgroundQueue();
      expect(drained.map((item) => item.body), [
        'Rs 100 debited',
        'Rs 200 credited',
      ]);
      expect(await store.drainBackgroundQueue(), isEmpty);
    });

    test('a corrupt entry does not block the rest', () async {
      final store = SmsImportStore();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(pendingBackgroundSmsKey, [
        'not json at all',
        jsonEncode(sms('Rs 300 debited').toJson()),
      ]);

      final drained = await store.drainBackgroundQueue();
      expect(drained.map((item) => item.body), ['Rs 300 debited']);
    });

    test('empty queue returns nothing', () async {
      expect(await SmsImportStore().drainBackgroundQueue(), isEmpty);
    });
  });

  group('settings', () {
    test('auto capture defaults to off', () async {
      expect(await SmsImportStore().readAutoCaptureEnabled(), isFalse);
    });

    test('auto capture persists', () async {
      final store = SmsImportStore();
      await store.writeAutoCaptureEnabled(true);
      expect(await store.readAutoCaptureEnabled(), isTrue);
    });

    test('last scan round-trips to the second', () async {
      final store = SmsImportStore();
      final when = DateTime(2026, 8, 2, 9, 15);
      await store.writeLastScan(when);
      expect(await store.readLastScan(), when);
    });
  });
}
