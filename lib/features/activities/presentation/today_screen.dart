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
import 'package:habito/features/journal/presentation/providers.dart';
import 'package:habito/features/wellbeing/presentation/providers.dart';
import 'package:habito/features/screen_time/presentation/providers.dart';
import 'package:habito/features/goals/presentation/providers.dart';
import 'package:habito/features/reminders/presentation/providers.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/core/database/enums.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final activitiesAsync = ref.watch(activitiesForDateProvider);
    final completionAsync = ref.watch(dailyCompletionProvider);

    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    final dateFormatted = isToday ? 'Today' : DateFormat('MMM d, yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Date Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    ref.read(selectedDateProvider.notifier).updateDate(selectedDate.subtract(const Duration(days: 1)));
                  },
                ),
                Column(
                  children: [
                    Text(
                      dateFormatted,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (completionAsync != null)
                      Text(
                        '${(completionAsync * 100).toInt()}% completed',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    ref.read(selectedDateProvider.notifier).updateDate(selectedDate.add(const Duration(days: 1)));
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          // Combined List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80.0), // space for FAB
              children: [
                if (isToday) ...[
                  const SectionHeader(title: 'Upcoming Reminders'),
                  Consumer(
                    builder: (context, ref, _) {
                      final reminders = ref.watch(enabledRemindersProvider);
                      final upcoming = reminders.where((r) {
                        if (r.recurrenceType == RecurrenceType.once && r.scheduledTime.isBefore(DateTime.now())) return false;
                        return true; // We simply show active ones for now
                      }).take(3).toList();
                      
                      if (upcoming.isEmpty) return const SizedBox.shrink();
                      
                      return Column(
                        children: upcoming.map((r) => ListTile(
                          leading: const Icon(Icons.notifications_active, color: Colors.blue),
                          title: Text(r.title),
                          subtitle: Text('${DateFormat.Hm().format(r.scheduledTime)} • ${r.type.value}'),
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(title: "Today's Goals"),
                  const _TodayGoalsSection(),
                  const SizedBox(height: 16),
                ],
                const SectionHeader(title: 'Study'),
                Consumer(
                  builder: (context, ref, _) {
                    final sessionsAsync = ref.watch(todayStudySessionsProvider);
                    final subjectsAsync = ref.watch(studySubjectsProvider);
                    
                    if (sessionsAsync.isLoading || subjectsAsync.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final sessions = sessionsAsync.value ?? [];
                    final subjects = subjectsAsync.value ?? [];
                    
                    if (sessions.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('No study sessions yet today.'),
                      );
                    }
                    
                    return Column(
                      children: sessions.map((session) {
                        final subject = subjects.firstWhere(
                          (s) => s.id == session.subjectId,
                          orElse: () => StudySubject(id: '', userId: '', name: 'Unknown', icon: '', color: '', isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now(), syncStatus: SyncStatus.synced),
                        );
                        
                        final startFormat = DateFormat.Hm().format(session.startedAt);
                        final endFormat = session.endedAt != null ? DateFormat.Hm().format(session.endedAt!) : 'Now';
                        final durMins = (session.duration / 60).floor();
                        
                        return ListTile(
                          leading: const Icon(Icons.menu_book),
                          title: Text(subject.name),
                          subtitle: Text('$startFormat - $endFormat'),
                          trailing: Text('${durMins}m', style: Theme.of(context).textTheme.bodyLarge),
                        );
                      }).toList(),
                    );
                  }
                ),
                
                const SectionHeader(title: 'Lifestyle'),
                Consumer(
                  builder: (context, ref, _) {
                    final meals = ref.watch(todayMealsProvider).value ?? [];
                    final sleep = ref.watch(todaySleepProvider).value ?? [];
                    final exerciseSessions = ref.watch(todayExerciseProvider).value ?? [];
                    final waterTotal = ref.watch(todayWaterTotalProvider);

                    return Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.restaurant),
                          title: const Text('Meals'),
                          trailing: Text('${meals.length} meals'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.water_drop),
                          title: const Text('Water'),
                          trailing: Text('${waterTotal.toInt()} ml'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.bedtime),
                          title: const Text('Sleep'),
                          trailing: sleep.isNotEmpty 
                            ? Text('${(sleep.first.duration/3600).floor()}h ${((sleep.first.duration%3600)/60).floor()}m')
                            : const Text('--'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: const Text('Exercise'),
                          trailing: Text('${exerciseSessions.fold(0, (sum, s) => sum + s.duration) ~/ 60} min'),
                        ),
                      ],
                    );
                  }
                ),

                const SectionHeader(title: '📱 Screen Time'),
                Consumer(
                  builder: (context, ref, _) {
                    final summaryAsync = ref.watch(todayScreenTimeProvider);
                    return summaryAsync.when(
                      data: (summary) {
                        if (summary == null) {
                          return ListTile(
                            title: const Text('Usage access required'),
                            trailing: const Text('Enable'),
                            onTap: () => context.go('/screen-time'),
                          );
                        }
                        final topApp = summary.topApps.isNotEmpty ? summary.topApps.first : null;
                        return ListTile(
                          title: Text('${summary.totalDuration.inHours}h ${summary.totalDuration.inMinutes.remainder(60)}m today'),
                          subtitle: topApp != null ? Text('Top app: ${topApp.appName} · ${topApp.duration.inMinutes}m') : null,
                          trailing: const Text('View'),
                          onTap: () => context.go('/screen-time'),
                        );
                      },
                      loading: () => const ListTile(title: Text('Loading screen time...')),
                      error: (e, st) => const ListTile(title: Text('Error loading screen time')),
                    );
                  }
                ),

                const SectionHeader(title: 'Wellbeing'),
                Consumer(
                  builder: (context, ref, _) {
                    final mood = ref.watch(todayMoodProvider).value;
                    if (mood == null) {
                      return const ListTile(title: Text('No check-in yet.'));
                    }
                    final moodEmoji = const ['😢', '😔', '😐', '🙂', '😊'][mood.moodRating - 1];
                    return ListTile(
                      leading: Text(moodEmoji, style: const TextStyle(fontSize: 24)),
                      title: const Text('Mood'),
                      subtitle: Text('Energy: ${mood.energyRating}/5, Stress: ${mood.stressRating}/5'),
                    );
                  }
                ),

                const SectionHeader(title: '❤️ Together'),
                Consumer(
                  builder: (context, ref, _) {
                    // Since sharedActivities are scoped by date, we might need a specific provider for that.
                    // For now, let's leave it as a placeholder as required:
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Partner data will appear here when sync is connected.', style: TextStyle(fontStyle: FontStyle.italic)),
                    );
                  }
                ),

                const SectionHeader(title: 'Journal'),
                Consumer(
                  builder: (context, ref, _) {
                    final entries = ref.watch(journalEntriesProvider).value ?? [];
                    final todayEntries = entries.where((e) => 
                      e.date.year == DateTime.now().year &&
                      e.date.month == DateTime.now().month &&
                      e.date.day == DateTime.now().day
                    ).toList();

                    if (todayEntries.isEmpty) {
                      return const ListTile(title: Text('No entries today.'));
                    }
                    return Column(
                      children: todayEntries.map((entry) => ListTile(
                        title: Text(entry.title ?? 'Journal Entry'),
                        subtitle: Text(entry.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => context.go('/journal/${entry.id}'),
                      )).toList(),
                    );
                  }
                ),
                
                const SectionHeader(title: 'Habits'),
                Consumer(
                  builder: (context, ref, _) {
                    final habitsAsync = ref.watch(habitsListProvider);
                    final logsAsync = ref.watch(todayHabitLogsProvider);
                    
                    if (habitsAsync.isLoading || logsAsync.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final habits = habitsAsync.value ?? [];
                    if (habits.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('No habits configured yet.'),
                      );
                    }
                    
                    final logs = logsAsync.value ?? [];
                    
                    return Column(
                      children: habits.map((habit) {
                        final log = logs.cast<HabitLog?>().firstWhere((l) => l?.habitId == habit.id, orElse: () => null);
                        final isCompleted = log?.isCompleted ?? false;
                        
                        return ListTile(
                          leading: Icon(
                            isCompleted ? Icons.check_circle : Icons.circle_outlined,
                            color: isCompleted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                          ),
                          title: Text(habit.title, style: TextStyle(
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          )),
                          onTap: () {
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
                        );
                      }).toList(),
                    );
                  }
                ),
                
                const SectionHeader(title: 'Timeline'),
                activitiesAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Nothing planned yet.'),
                      );
                    }
                    return Column(
                      children: activities.map((a) => ActivityListTile(
                        title: a.title,
                        notes: a.notes,
                        time: a.scheduledStart,
                        isCompleted: a.isCompleted,
                        onToggle: () {
                          ref.read(activityRepositoryProvider).toggleActivityCompletion(a.id, !a.isCompleted);
                        },
                        onTap: () {
                          context.push('/activity/edit', extra: a);
                        },
                      )).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/activity/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TodayGoalsSection extends ConsumerWidget {
  const _TodayGoalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoalsAsync = ref.watch(activeGoalsProvider);

    return activeGoalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) return const SizedBox.shrink();
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: goals.map((goal) => _TodayGoalTile(goal: goal)).toList(),
          ),
        );
      },
      loading: () => const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TodayGoalTile extends ConsumerWidget {
  final PersonalGoal goal;
  const _TodayGoalTile({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(goalProgressProvider(goal));

    return progressAsync.when(
      data: (progress) {
        if (progress.dataAvailability == DataAvailability.unavailable) {
          return const SizedBox.shrink();
        }
        return ListTile(
          title: Text(goal.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              LinearProgressIndicator(value: progress.progressRatio),
              const SizedBox(height: 4),
              Text('${progress.actual.toStringAsFixed(1)} / ${progress.target.toStringAsFixed(1)} ${goal.unit ?? ""}'),
            ],
          ),
          onTap: () => context.push('/goals/${goal.id}'),
        );
      },
      loading: () => const ListTile(title: LinearProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
