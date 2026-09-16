import '../entities/pending_capture.dart';

List<PendingCapture> mergeNewCaptures(
  List<PendingCapture> existing,
  List<PendingCapture> incoming,
) {
  final existingIds = existing.map((c) => c.id).toSet();
  final toAdd = incoming.where((c) => !existingIds.contains(c.id));
  return [...existing, ...toAdd];
}

String captureId({required String packageName, required int postTime}) =>
    '$packageName-$postTime';
