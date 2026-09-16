import '../domain/entities/pending_capture.dart';
import '../domain/utils/bank_notification_parser.dart';
import '../domain/utils/pending_capture_merge.dart';
import 'notification_capture_service.dart';
import 'pending_capture_store.dart';

List<PendingCapture> buildPendingCaptures(List<CapturedNotification> raw) {
  final result = <PendingCapture>[];
  for (final n in raw) {
    final parsed = parseBankNotification(title: n.title, text: n.text);
    if (parsed == null) continue;
    result.add(PendingCapture(
      id: captureId(packageName: n.packageName, postTime: n.postTime),
      description: parsed.description,
      amount: parsed.amount,
      type: parsed.type,
      postTime: n.postTime,
    ));
  }
  return result;
}

class NotificationCaptureSyncService {
  final NotificationCaptureService captureService;
  final PendingCaptureStore store;

  NotificationCaptureSyncService({
    NotificationCaptureService? captureService,
    PendingCaptureStore? store,
  })  : captureService = captureService ?? NotificationCaptureService(),
        store = store ?? PendingCaptureStore();

  Future<int> sync() async {
    final raw = await captureService.drainCaptured();
    if (raw.isEmpty) return 0;
    final parsed = buildPendingCaptures(raw);
    if (parsed.isEmpty) return 0;
    return store.addAll(parsed);
  }
}
