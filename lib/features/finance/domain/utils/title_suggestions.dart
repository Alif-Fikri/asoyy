import '../entities/transaction_entity.dart';

List<String> distinctTitles(List<TransactionEntity> all, {int limit = 50}) {
  final counts = <String, int>{};
  for (final t in all) {
    final title = t.title.trim();
    if (title.isEmpty) continue;
    counts[title] = (counts[title] ?? 0) + 1;
  }
  final titles = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  return titles.take(limit).toList();
}
