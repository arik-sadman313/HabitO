import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/features/lifestyle/presentation/providers.dart';
import 'package:habito/core/widgets/ui_components.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/database/enums.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:uuid/uuid.dart';

class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(todayExerciseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: exerciseAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const EmptyStateCard(message: 'No exercise recorded.', actionLabel: '+ Log Exercise',);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final durMins = (session.duration / 60).round();
              
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(session.exerciseType),
                  trailing: Text('$durMins min', style: Theme.of(context).textTheme.titleMedium),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logMockExercise(ref),
        icon: const Icon(Icons.add),
        label: const Text('Log Exercise'),
      ),
    );
  }

  void _logMockExercise(WidgetRef ref) {
    final repo = ref.read(exerciseRepositoryProvider);
    final userId = ref.read(authNotifierProvider).user!.id;
    
    final end = DateTime.now();
    final start = end.subtract(const Duration(minutes: 45));
    
    final session = ExerciseSession(
      id: const Uuid().v4(),
      userId: userId,
      exerciseType: 'Gym',
      startedAt: start,
      endedAt: end,
      duration: 45 * 60,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
    );
    
    repo.saveExercise(session);
  }
}
