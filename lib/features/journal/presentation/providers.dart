import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/database/enums.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/journal/data/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepositoryImpl(db.AppDatabase());
});



class JournalFilterNotifier extends Notifier<JournalType?> {
  @override
  JournalType? build() => null;
  void setFilter(JournalType? type) => state = type;
}

final journalFilterProvider = NotifierProvider<JournalFilterNotifier, JournalType?>(JournalFilterNotifier.new);

class JournalSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setSearch(String q) => state = q;
}

final journalSearchQueryProvider = NotifierProvider<JournalSearchNotifier, String>(JournalSearchNotifier.new);

final journalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return Stream.value([]);

  final searchQuery = ref.watch(journalSearchQueryProvider);
  final repo = ref.watch(journalRepositoryProvider);

  if (searchQuery.isNotEmpty) {
    return repo.searchJournalEntries(userId, searchQuery);
  } else {
    final filterType = ref.watch(journalFilterProvider);
    return repo.watchJournalEntries(userId, filterType: filterType);
  }
});
