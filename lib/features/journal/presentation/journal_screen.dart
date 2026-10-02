import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/features/journal/presentation/providers.dart';
import 'package:habito/core/widgets/ui_components.dart';
import 'package:intl/intl.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider);
    final filterType = ref.watch(journalFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              hintText: 'Search journal...',
              onChanged: (value) => ref.read(journalSearchQueryProvider.notifier).setSearch(value),
              leading: const Icon(Icons.search),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filterType == null,
                  onSelected: (_) => ref.read(journalFilterProvider.notifier).setFilter(null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('My Journal'),
                  selected: filterType == JournalType.personal,
                  onSelected: (_) => ref.read(journalFilterProvider.notifier).setFilter(JournalType.personal),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Our Journal'),
                  selected: filterType == JournalType.shared,
                  onSelected: (_) => ref.read(journalFilterProvider.notifier).setFilter(JournalType.shared),
                ),
              ],
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const EmptyStateCard(message: 'No entries yet.', actionLabel: 'Write',);
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => context.go('/journal/${entry.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat.yMMMd().format(entry.date),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (entry.journalType == JournalType.shared)
                                    const Icon(Icons.favorite, size: 16, color: Colors.redAccent)
                                  else
                                    const Icon(Icons.person, size: 16, color: Colors.blueAccent),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (entry.title != null && entry.title!.isNotEmpty)
                                Text(entry.title!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                entry.body,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/journal/new'),
        child: const Icon(Icons.edit),
      ),
    );
  }
}
