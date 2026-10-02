import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habito/core/widgets/ui_components.dart';
import 'package:habito/features/activities/presentation/providers.dart';
import 'package:habito/features/habits/presentation/providers.dart';
import 'package:habito/features/study/presentation/providers.dart';
import 'package:habito/features/lifestyle/presentation/providers.dart';
import 'package:habito/features/lifestyle/presentation/water_provider.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/wellbeing/presentation/providers.dart';
import 'package:habito/features/us/presentation/providers.dart';
import 'package:habito/features/journal/presentation/providers.dart';
import 'package:habito/features/screen_time/presentation/providers.dart';
import 'package:habito/features/goals/presentation/providers.dart';
import 'package:habito/core/database/enums.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning,',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        user?.name ?? 'User',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            const SectionHeader(title: "Today's Habits"),
            Consumer(
              builder: (context, ref, _) {
                final rate = ref.watch(habitCompletionRateProvider);
                if (rate == null) {
                  return const EmptyStateCard(message: 'No habits configured yet.');
                }
                
                final habits = ref.watch(habitsListProvider).value ?? [];
                final logs = ref.watch(todayHabitLogsProvider).value ?? [];
                final completedCount = logs.where((l) => l.isCompleted).length;
                
                return ProgressCard(
                  progress: rate,
                  label: '$completedCount / ${habits.length} Habits Completed',
                );
              }
            ),
            
            const SizedBox(height: 32),
            const SectionHeader(title: "Today's Activities"),
            Consumer(
              builder: (context, ref, _) {
                final completionAsync = ref.watch(dailyCompletionProvider);
                return ProgressCard(
                  progress: completionAsync ?? 0.0,
                  label: completionAsync == null ? 'No activities yet' : 'Activities Completion',
                );
              },
            ),
            
            const SizedBox(height: 32),
            const SectionHeader(title: 'Progress & Analytics'),
            Consumer(
              builder: (context, ref, _) {
                final activeAsync = ref.watch(activeGoalsProvider);
                
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.flag, size: 32, color: Colors.orange),
                        title: const Text('Personal Goals'),
                        subtitle: activeAsync.when(
                          data: (goals) => Text('${goals.length} active goals'),
                          loading: () => const Text('Loading...'),
                          error: (_, __) => const Text('Error'),
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () => context.push('/goals'),
                          child: const Text('View Goals'),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.insights, size: 32, color: Colors.indigo),
                        title: const Text('Analytics Dashboard'),
                        subtitle: const Text('Trends and insights'),
                        trailing: OutlinedButton(
                          onPressed: () => context.push('/analytics'),
                          child: const Text('View Analytics'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            const SectionHeader(title: 'Quick Stats'),
            Consumer(
              builder: (context, ref, _) {
                final studyDuration = ref.watch(todayStudyTotalDurationProvider);
                final studyGoal = ref.watch(dailyStudyGoalProvider);
                
                final meals = ref.watch(todayMealsProvider).value ?? [];
                final sleep = ref.watch(todaySleepProvider).value ?? [];
                final exercise = ref.watch(todayExerciseDurationProvider);
                final waterTotal = ref.watch(todayWaterTotalProvider);
                final waterGoal = ref.watch(dailyWaterGoalProvider);

                return Column(
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.school, size: 32),
                        title: const Text('Study'),
                        subtitle: Text('${studyDuration.inHours}h ${studyDuration.inMinutes.remainder(60)}m today'),
                        trailing: Text('${studyGoal.inHours}h Goal'),
                        onTap: () {
                          context.go('/study');
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.restaurant, size: 32),
                        title: const Text('Meals'),
                        subtitle: Text('${meals.length} logged today'),
                        onTap: () => context.go('/lifestyle/food'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.water_drop, size: 32, color: Colors.blue),
                        title: const Text('Water'),
                        subtitle: Text('${waterTotal.toInt()} ml / ${waterGoal.toInt()} ml'),
                        onTap: () => context.go('/lifestyle/water'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.bedtime, size: 32, color: Colors.deepPurple),
                        title: const Text('Sleep'),
                        subtitle: sleep.isNotEmpty 
                          ? Text('${(sleep.first.duration/3600).floor()}h ${((sleep.first.duration%3600)/60).floor()}m')
                          : const Text('No sleep recorded'),
                        onTap: () => context.go('/lifestyle/sleep'),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.fitness_center, size: 32, color: Colors.orange),
                        title: const Text('Exercise'),
                        subtitle: Text('${exercise.inMinutes} min today'),
                        onTap: () => context.go('/lifestyle/exercise'),
                      ),
                    ),
                  ],
                );
              }
            ),
            
            const SizedBox(height: 32),
            const SectionHeader(title: 'Screen Time'),
            Consumer(
              builder: (context, ref, _) {
                final summaryAsync = ref.watch(todayScreenTimeProvider);
                return summaryAsync.when(
                  data: (summary) {
                    if (summary == null) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.screen_lock_portrait),
                          title: const Text('Usage access required'),
                          trailing: const Text('Enable'),
                          onTap: () => context.go('/screen-time'),
                        ),
                      );
                    }
                    final topApp = summary.topApps.isNotEmpty ? summary.topApps.first : null;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.phone_android, size: 32),
                        title: Text('${summary.totalDuration.inHours}h ${summary.totalDuration.inMinutes.remainder(60)}m today'),
                        subtitle: topApp != null ? Text('Top app: ${topApp.appName} · ${topApp.duration.inMinutes}m') : const Text('No usage yet'),
                        trailing: const Text('View'),
                        onTap: () => context.go('/screen-time'),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => const Text('Error loading screen time'),
                );
              },
            ),
            
            const SizedBox(height: 32),
            const SectionHeader(title: 'Wellbeing'),
            Consumer(
              builder: (context, ref, _) {
                final moodAsync = ref.watch(todayMoodProvider);
                
                return moodAsync.when(
                  data: (mood) {
                    if (mood == null) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.favorite_border, size: 32, color: Colors.pink),
                          title: const Text('How are you feeling today?'),
                          subtitle: const Text('Check in on your wellbeing.'),
                          trailing: const Text('Check in'),
                          onTap: () => context.go('/wellbeing/check-in'),
                        ),
                      );
                    }
                    final moodEmoji = const ['😢', '😔', '😐', '🙂', '😊'][mood.moodRating - 1];
                    return Card(
                      child: ListTile(
                        leading: Text(moodEmoji, style: const TextStyle(fontSize: 32)),
                        title: const Text('Today\'s Mood'),
                        subtitle: Text('Energy: ${mood.energyRating}/5 • Stress: ${mood.stressRating}/5'),
                        onTap: () => context.go('/wellbeing'),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error: $e'),
                );
              },
            ),
            
            const SizedBox(height: 32),
            const SectionHeader(title: '❤️ Together'),
            Consumer(
              builder: (context, ref, _) {
                final goalsAsync = ref.watch(sharedGoalsProvider);
                final journalAsync = ref.watch(journalEntriesProvider);
                
                return Column(
                  children: [
                    goalsAsync.when(
                      data: (goals) {
                        if (goals.isEmpty) return const SizedBox.shrink();
                        final topGoal = goals.first;
                        final progress = topGoal.target > 0 ? (topGoal.currentProgress / topGoal.target) : 0.0;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.track_changes, color: Colors.purple),
                            title: Text(topGoal.title),
                            subtitle: Text('${(progress * 100).toInt()}% completed'),
                            onTap: () => context.go('/us'),
                          ),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, st) => const SizedBox.shrink(),
                    ),
                    journalAsync.when(
                      data: (entries) {
                        final shared = entries.where((e) => e.journalType == JournalType.shared).toList();
                        if (shared.isEmpty) return const SizedBox.shrink();
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.favorite, color: Colors.red),
                            title: const Text('New Our Journal Entry'),
                            subtitle: Text(shared.first.title ?? 'Recent memory...'),
                            onTap: () => context.go('/us'),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                    ),
                  ],
                );
              }
            ),

            const SizedBox(height: 32),
            const SectionHeader(title: 'Today\'s Plan'),
            Consumer(
              builder: (context, ref, _) {
                final activitiesAsync = ref.watch(activitiesForDateProvider);
                return activitiesAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return EmptyStateCard(
                        message: 'Nothing planned for today.',
                        actionLabel: 'Add Activity',
                        onAction: () => context.push('/activity/new'),
                      );
                    }
                    final preview = activities.take(3).toList();
                    return Column(
                      children: [
                        ...preview.map((a) => ActivityListTile(
                          title: a.title,
                          notes: a.notes,
                          time: a.scheduledStart,
                          isCompleted: a.isCompleted,
                          onToggle: () {
                            ref.read(activityRepositoryProvider).toggleActivityCompletion(a.id, !a.isCompleted);
                          },
                          onTap: () {
                          },
                        )),
                        if (activities.length > 3)
                          TextButton(
                            onPressed: () {
                              // Switch tab to Today
                            },
                            child: const Text('View All'),
                          )
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error: $e'),
                );
              }
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/activity/new'),
        icon: const Icon(Icons.add),
        label: const Text('Activity'),
      ),
    );
  }
}
