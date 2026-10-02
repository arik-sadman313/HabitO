import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/widgets/ui_components.dart';
import 'package:habito/features/habits/presentation/providers.dart';
import 'package:habito/features/trackers/presentation/providers.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:uuid/uuid.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/activities/presentation/providers.dart';

class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsListProvider);
    final trackersAsync = ref.watch(trackersListProvider);
    final todayLogsAsync = ref.watch(todayHabitLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Track')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SectionHeader(title: 'My Habits'),
          habitsAsync.when(
            data: (habits) {
              if (habits.isEmpty) {
                return EmptyStateCard(
                  message: 'No habits yet.',
                  actionLabel: 'Create Habit',
                  onAction: () => _showAddHabitDialog(context, ref),
                );
              }
              
              final logs = todayLogsAsync.value ?? [];
              
              return Column(
                children: habits.map((habit) {
                  final log = logs.cast<HabitLog?>().firstWhere((l) => l?.habitId == habit.id, orElse: () => null);
                  final isCompleted = log?.isCompleted ?? false;
                  
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isCompleted ? Icons.check_circle : Icons.circle_outlined,
                        color: isCompleted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                      ),
                      title: Text(habit.title, style: TextStyle(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      )),
                      subtitle: Text(habit.description ?? ''),
                      onTap: () {
                        // Toggle completion for today
                        final repo = ref.read(habitRepositoryProvider);
                        final userId = ref.read(authNotifierProvider).user!.id;
                        final date = ref.read(selectedDateProvider);
                        
                        final newLog = HabitLog(
                          id: log?.id ?? const Uuid().v4(),
                          habitId: habit.id,
                          userId: userId,
                          date: date,
                          isCompleted: !isCompleted,
                          progressValue: 1.0,
                          createdAt: log?.createdAt ?? DateTime.now(),
                          updatedAt: DateTime.now(),
                          syncStatus: SyncStatus.pendingUpdate,
                        );
                        
                        repo.saveHabitLog(newLog);
                      },
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
          ),
          
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Habit'),
              onPressed: () => _showAddHabitDialog(context, ref),
            ),
          ),
          
          const SizedBox(height: 32),
          const SectionHeader(title: 'My Trackers'),
          trackersAsync.when(
            data: (trackers) {
              if (trackers.isEmpty) {
                return EmptyStateCard(
                  message: 'No custom trackers.',
                  actionLabel: 'Create Tracker',
                  onAction: () => _showAddTrackerDialog(context, ref),
                );
              }
              
              return Column(
                children: trackers.map((tracker) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.assessment),
                      title: Text(tracker.name),
                      subtitle: Text(tracker.type.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to Tracker Detail
                      },
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
          ),
          
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Tracker'),
              onPressed: () => _showAddTrackerDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, WidgetRef ref) {
    // Quick and simple dialog for adding a habit for Phase 5 MVP
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Habit'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Habit Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              
              final userId = ref.read(authNotifierProvider).user!.id;
              final repo = ref.read(habitRepositoryProvider);
              
              // We need a dummy tracker for the habit per DB schema constraints
              // Real implementation would allow selecting or creating a tracker
              final dummyTrackerId = const Uuid().v4();
              
              repo.saveHabit(Habit(
                id: const Uuid().v4(),
                userId: userId,
                trackerId: dummyTrackerId, // Need a valid tracker ID in a real scenario
                title: titleController.text,
                frequency: HabitFrequency.daily,
                targetValue: 1.0,
                startDate: DateTime.now(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                syncStatus: SyncStatus.pendingUpdate,
              ));
              
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddTrackerDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Tracker'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Tracker Name (e.g. Water)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              
              final userId = ref.read(authNotifierProvider).user!.id;
              final repo = ref.read(trackerRepositoryProvider);
              
              repo.saveTracker(Tracker(
                id: const Uuid().v4(),
                userId: userId,
                name: titleController.text,
                icon: 'water_drop',
                color: 'blue',
                type: TrackerType.decimal,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                syncStatus: SyncStatus.pendingUpdate,
              ));
              
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
