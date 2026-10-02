import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/features/wellbeing/presentation/providers.dart';
import 'package:habito/core/widgets/ui_components.dart';
import 'package:intl/intl.dart';

class WellbeingScreen extends ConsumerWidget {
  const WellbeingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(moodHistoryProvider(7));

    return Scaffold(
      appBar: AppBar(title: const Text('Wellbeing')),
      body: historyAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const EmptyStateCard(
              message: 'No check-ins yet.',
              actionLabel: 'Check In',
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final moodEmoji = const ['😢', '😔', '😐', '🙂', '😊'][log.moodRating - 1];
              
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat.yMMMd().format(log.date), style: Theme.of(context).textTheme.titleSmall),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: [const Text('Mood'), Text(moodEmoji, style: const TextStyle(fontSize: 24))]),
                          Column(children: [const Text('Energy'), Text('${log.energyRating}/5', style: Theme.of(context).textTheme.titleLarge)]),
                          Column(children: [const Text('Stress'), Text('${log.stressRating}/5', style: Theme.of(context).textTheme.titleLarge)]),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/wellbeing/check-in'),
        icon: const Icon(Icons.favorite),
        label: const Text('Check In'),
      ),
    );
  }
}
