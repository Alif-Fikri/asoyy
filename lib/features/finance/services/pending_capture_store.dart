import 'dart:convert';

import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/entities/pending_capture.dart';
import '../domain/utils/pending_capture_merge.dart';

class PendingCaptureStore {
  static const _key = 'pending_captured_transactions';

  Box get _box => Hive.box(AppConstants.settingsBox);

  List<PendingCapture> getAll() {
    final raw = _box.get(_key) as String?;
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => PendingCapture.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> addAll(List<PendingCapture> incoming) async {
    final existing = getAll();
    final merged = mergeNewCaptures(existing, incoming);
    await _save(merged);
    return merged.length - existing.length;
  }

  Future<void> remove(String id) async {
    final remaining = getAll().where((c) => c.id != id).toList();
    await _save(remaining);
  }

  Future<void> removeMany(Iterable<String> ids) async {
    final idSet = ids.toSet();
    final remaining = getAll().where((c) => !idSet.contains(c.id)).toList();
    await _save(remaining);
  }

  Future<void> _save(List<PendingCapture> captures) async {
    final encoded = jsonEncode(captures.map((c) => c.toJson()).toList());
    await _box.put(_key, encoded);
  }
}
