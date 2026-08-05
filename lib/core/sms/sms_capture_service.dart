import 'captured_sms.dart';
import 'sms_capture_service_stub.dart'
    if (dart.library.io) 'sms_capture_service_native.dart';

/// Reads bank SMS off the device.
///
/// Android only. The web and desktop builds get [UnsupportedSmsCaptureService]
/// through a conditional import, so `another_telephony` (and its non web safe
/// transitive dependencies) never reach the web compiler.
abstract class SmsCaptureService {
  factory SmsCaptureService() = SmsCaptureServiceImpl;

  /// Whether this platform can read SMS at all.
  bool get isSupported;

  /// Requests READ_SMS/RECEIVE_SMS. Returns false if the user declined.
  Future<bool> ensurePermission();

  /// Whether permission has already been granted, without prompting.
  Future<bool> hasPermission();

  /// Reads the device inbox, newest first.
  Future<List<CapturedSms>> readInbox({DateTime? since, int limit = 200});

  /// Starts delivery of new messages.
  ///
  /// [onForegroundMessage] is called immediately while MONEX is on screen.
  /// Messages that arrive while it is backgrounded are queued to disk instead
  /// and picked up by [SmsImportStore.drainBackgroundQueue] on next resume.
  Future<void> startListening({
    required void Function(CapturedSms) onForegroundMessage,
  });
}
