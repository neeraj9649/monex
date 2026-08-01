import 'captured_sms.dart';
import 'sms_capture_service.dart';

/// Web/desktop implementation: SMS is not available, so every call is a no-op.
class SmsCaptureServiceImpl implements SmsCaptureService {
  @override
  bool get isSupported => false;

  @override
  Future<bool> ensurePermission() async => false;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<List<CapturedSms>> readInbox({
    DateTime? since,
    int limit = 200,
  }) async => const [];

  @override
  Future<void> startListening() async {}
}
