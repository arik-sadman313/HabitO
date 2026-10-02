import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/goals/presentation/providers.dart';

class GoalsDashboardScreen extends ConsumerWidget {
  const GoalsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personal Goals'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/goals/new'),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _ActiveGoalsTab(),
            _CompletedGoalsTab(),
          ],
        ),
      ),
    );
  }
}

class _ActiveGoalsTab extends ConsumerWidget {
  const _ActiveGoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoalsAsync = ref.watch(activeGoalsProvider);

    return activeGoalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return const Center(
            child: Text('No active goals.\nTap + to create one!', textAlign: TextAlign.center),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            return _GoalCard(goal: goals[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _CompletedGoalsTab extends ConsumerWidget {
  const _CompletedGoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedGoalsAsync = ref.watch(completedGoalsProvider);

    return completedGoalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return const Center(child: Text('No completed goals yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            return _GoalCard(goal: goals[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final PersonalGoal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(goalProgressProvider(goal));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/goals/${goal.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(goal.title, style: Theme.of(context).textTheme.titleMedium),
              if (goal.description != null && goal.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(goal.description!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              progressAsync.when(
                data: (progress) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            progress.dataAvailability == DataAvailability.unavailable
                                ? 'Progress unavailable'
                                : '${progress.actual.toStringAsFixed(1)} / ${progress.target.toStringAsFixed(1)} ${goal.unit ?? ""}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (progress.dataAvailability != DataAvailability.unavailable)
                            Text('${progress.percentage}%', style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress.dataAvailability == DataAvailability.unavailable ? 0 : progress.progressRatio,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      if (goal.targetDate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _formatRemainingDays(goal.targetDate!),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading progress'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRemainingDays(DateTime target) {
    final now = DateTime.now();
    final diff = target.difference(now).inDays;
    if (diff < 0) return 'Deadline passed';
    if (diff == 0) return 'Ends today';
    return '$diff days remaining';
  }
}
