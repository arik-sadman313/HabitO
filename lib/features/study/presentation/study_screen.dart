import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/widgets/ui_components.dart';
import 'package:habito/features/study/presentation/providers.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/database/enums.dart';
import 'package:uuid/uuid.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(studySubjectsProvider);
    final todayDuration = ref.watch(todayStudyTotalDurationProvider);
    final goalDuration = ref.watch(dailyStudyGoalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Study')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SectionHeader(title: "Today's Study"),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _formatDuration(todayDuration),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (todayDuration.inSeconds / goalDuration.inSeconds).clamp(0.0, 1.0),
                  ),
                  const SizedBox(height: 8),
                  Text('Goal: ${_formatDuration(goalDuration)}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/study/timer'),
                    icon: const Icon(Icons.timer),
                    label: const Text('Start Study'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          const SectionHeader(title: "Subjects"),
          subjectsAsync.when(
            data: (subjects) {
              if (subjects.isEmpty) {
                return EmptyStateCard(
                  message: 'No study subjects yet.',
                  actionLabel: 'Create Subject',
                  onAction: () => _createDummySubject(ref), // MVP convenience
                );
              }
              return Column(
                children: subjects.map((sub) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(sub.name),
                    subtitle: Text(sub.description ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Future: Open subject detail
                    },
                  ),
                )).toList(),
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
              label: const Text('Add Subject'),
              onPressed: () => _createDummySubject(ref),
            ),
          ),
        ],
      ),
    );
  }
  
  void _createDummySubject(WidgetRef ref) {
    final repo = ref.read(studyRepositoryProvider);
    final userId = ref.read(authNotifierProvider).user!.id;
    repo.saveSubject(StudySubject(
      id: const Uuid().v4(),
      userId: userId,
      name: 'Programming',
      description: 'Flutter & Dart',
      icon: 'code',
      color: 'blue',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
    ));
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
