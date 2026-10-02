import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/widgets/ui_components.dart';
import 'package:habito/features/us/presentation/providers.dart';
import 'package:habito/features/journal/presentation/providers.dart';
import 'package:habito/core/database/enums.dart';

class UsScreen extends ConsumerWidget {
  const UsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerAsync = ref.watch(partnerProvider);
    final sharedGoalsAsync = ref.watch(sharedGoalsProvider);
    final memoriesAsync = ref.watch(memoriesProvider);
    
    // We can filter journal entries by shared type
    final journalEntriesAsync = ref.watch(journalEntriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('❤️ Our Space'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Partner Header
            partnerAsync.when(
              data: (partner) {
                if (partner == null) {
                  return const EmptyStateCard(message: 'You are not paired with anyone yet.');
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'P',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontSize: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                partner.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Text('Partner'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
            
            const SizedBox(height: 32),
            const SectionHeader(title: 'TODAY TOGETHER'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Partner data will appear here when sync is connected.', style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const SectionHeader(title: 'SHARED GOALS'),
            sharedGoalsAsync.when(
              data: (goals) {
                if (goals.isEmpty) {
                  return EmptyStateCard(
                    message: 'No shared goals yet.',
                    actionLabel: '+ Create Goal',
                    onAction: () {
                      // context.push('/us/goals/new');
                    },
                  );
                }
                return Column(
                  children: goals.map((goal) {
                    final progress = goal.target > 0 ? (goal.currentProgress / goal.target) : 0.0;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('🎯 ${goal.title}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                Text('${goal.currentProgress.toInt()} / ${goal.target.toInt()} ${goal.unit ?? ""}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            const SizedBox(height: 4),
                            Text('${(progress * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
            
            const SizedBox(height: 32),
            const SectionHeader(title: 'MEMORIES'),
            memoriesAsync.when(
              data: (memories) {
                if (memories.isEmpty) {
                  return EmptyStateCard(
                    message: 'No memories yet.',
                    actionLabel: '+ Add Memory',
                    onAction: () {},
                  );
                }
                return Column(
                  children: memories.map((memory) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: Text(memory.title),
                      subtitle: Text(memory.date.toString().split(' ')[0]), // formatted date ideally
                    ),
                  )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
            
            const SizedBox(height: 32),
            const SectionHeader(title: 'OUR JOURNAL'),
            journalEntriesAsync.when(
              data: (entries) {
                final sharedEntries = entries.where((e) => e.journalType == JournalType.shared).toList();
                if (sharedEntries.isEmpty) {
                  return EmptyStateCard(
                    message: 'No shared journal entries yet.',
                    actionLabel: 'Write Entry',
                    onAction: () {
                      context.push('/journal/new');
                    },
                  );
                }
                final recent = sharedEntries.first;
                return Card(
                  child: ListTile(
                    title: Text(recent.title ?? 'Journal Entry'),
                    subtitle: Text(recent.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      context.go('/journal');
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
