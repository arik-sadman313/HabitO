import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/features/lifestyle/presentation/providers.dart';
import 'package:habito/core/widgets/ui_components.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepAsync = ref.watch(todaySleepProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      body: sleepAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const EmptyStateCard(message: 'No sleep recorded for last night.', actionLabel: '+ Log Sleep',);
          }
          
          final record = records.first;
          final duration = Duration(seconds: record.duration);
          
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(title: 'Last Night'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Goal: 8h'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text('Bedtime'),
                                Text(DateFormat.Hm().format(record.sleepStart), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Wake time'),
                                Text(DateFormat.Hm().format(record.wakeTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Quality'),
                                Text('${record.quality}/5', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logMockSleep(ref),
        icon: const Icon(Icons.add),
        label: const Text('Log Last Night'),
      ),
    );
  }
  
  void _logMockSleep(WidgetRef ref) {
    final repo = ref.read(sleepRepositoryProvider);
    final userId = ref.read(authNotifierProvider).user!.id;
    
    final wakeTime = DateTime.now();
    final sleepStart = wakeTime.subtract(const Duration(hours: 7, minutes: 20));
    
    final sleep = SleepRecord(
      id: const Uuid().v4(),
      userId: userId,
      sleepStart: sleepStart,
      wakeTime: wakeTime,
      duration: wakeTime.difference(sleepStart).inSeconds,
      quality: 4,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
    );
    
    repo.saveSleep(sleep);
  }
}
