import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/features/journal/presentation/providers.dart';
import 'package:intl/intl.dart';

class JournalDetailScreen extends ConsumerWidget {
  final String entryId;

  const JournalDetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider);
    
    return entriesAsync.when(
      data: (entries) {
        final entry = entries.firstWhere((e) => e.id == entryId);
        
        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteEntry(context, ref, entryId),
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd().add_jm().format(entry.date),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
                    ),
                    if (entry.journalType == JournalType.shared)
                      const Chip(label: Text('Our Journal'), avatar: Icon(Icons.favorite, size: 16))
                    else
                      const Chip(label: Text('My Journal'), avatar: Icon(Icons.person, size: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                if (entry.title != null && entry.title!.isNotEmpty) ...[
                  Text(entry.title!, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                ],
                Text(
                  entry.body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                if (entry.tags != null && entry.tags!.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: entry.tags!.split(',').map((t) => Chip(label: Text(t.trim()))).toList(),
                  )
                ]
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
  
  Future<void> _deleteEntry(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    
    if (confirm == true) {
      final repo = ref.read(journalRepositoryProvider);
      await repo.deleteEntry(id);
      if (context.mounted) context.pop();
    }
  }
}
