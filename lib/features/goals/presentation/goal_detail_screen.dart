import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/goals/presentation/providers.dart';
import 'package:habito/core/database/enums.dart';

class GoalDetailScreen extends ConsumerWidget {
  final String goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(goalByIdProvider(goalId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Detail'),
      ),
      body: goalAsync.when(
        data: (goal) {
          if (goal == null) return const Center(child: Text('Goal not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(label: Text(goal.status.name.toUpperCase())),
                    const SizedBox(width: 8),
                    if (goal.targetDate != null)
                      Chip(label: Text('Ends ${_formatDate(goal.targetDate!)}')),
                  ],
                ),
                if (goal.description != null && goal.description!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Description', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(goal.description!, style: Theme.of(context).textTheme.bodyLarge),
                ],
                const SizedBox(height: 32),
                Text('Progress', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                _ProgressSection(goal: goal),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ProgressSection extends ConsumerWidget {
  final PersonalGoal goal;
  const _ProgressSection({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(goalProgressProvider(goal));

    return progressAsync.when(
      data: (progress) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.actual.toStringAsFixed(1)} / ${progress.target.toStringAsFixed(1)} ${goal.unit ?? ""}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('${progress.percentage}%', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.dataAvailability == DataAvailability.unavailable ? 0 : progress.progressRatio,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getDataSourceExplanation(goal.goalType),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (progress.percentage >= 100 && goal.status == GoalStatus.active)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Mark completed
                    final updatedGoal = PersonalGoal(
                      id: goal.id,
                      userId: goal.userId,
                      title: goal.title,
                      description: goal.description,
                      goalType: goal.goalType,
                      targetValue: goal.targetValue,
                      currentValue: goal.currentValue,
                      unit: goal.unit,
                      startDate: goal.startDate,
                      targetDate: goal.targetDate,
                      status: GoalStatus.completed,
                      createdAt: goal.createdAt,
                      updatedAt: DateTime.now(),
                      syncStatus: goal.syncStatus,
                    );
                    ref.read(personalGoalRepositoryProvider).updateGoal(updatedGoal);
                    context.pop();
                  },
                  child: const Text('Mark as Completed'),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading progress'),
    );
  }

  String _getDataSourceExplanation(GoalType type) {
    switch (type) {
      case GoalType.studyDuration:
        return 'Calculated automatically from your recorded study sessions.';
      case GoalType.exerciseDuration:
        return 'Calculated automatically from your recorded exercise sessions.';
      case GoalType.sleepDuration:
        return 'Calculated automatically from your recorded sleep history.';
      case GoalType.screenTimeReduction:
        return 'Calculated automatically from your device screen time data.';
      case GoalType.waterIntake:
        return 'Calculated from your water tracking records.';
      default:
        return 'Manually tracked goal progress.';
    }
  }
}
