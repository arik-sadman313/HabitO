import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/habits/data/habit_repository.dart';
import 'package:habito/features/habits/domain/streak_calculator.dart';
import 'package:habito/features/activities/presentation/providers.dart'; // for selectedDateProvider

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final database = db.AppDatabase();
  return HabitRepositoryImpl(database);
});

final habitsListProvider = StreamProvider<List<Habit>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(habitRepositoryProvider);
  return repo.watchHabits(userId);
});

final todayHabitLogsProvider = StreamProvider<List<HabitLog>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;
  final date = ref.watch(selectedDateProvider);

  if (userId == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(habitRepositoryProvider);
  return repo.watchHabitLogsForDate(userId, date);
});

final habitLogsProvider = StreamProvider.family<List<HabitLog>, String>((ref, habitId) {
  final repo = ref.watch(habitRepositoryProvider);
  return repo.watchHabitLogs(habitId);
});

// Since habitRepository only has watchHabitLogs (not watchLogsForHabit), let's fix the name here
// Actually the repo has watchHabitLogs(String habitId)
final habitHistoryProvider = StreamProvider.family<List<HabitLog>, String>((ref, habitId) {
  final repo = ref.watch(habitRepositoryProvider);
  return repo.watchHabitLogs(habitId);
});

final habitAnalyticsProvider = Provider.family<AsyncValue<HabitAnalytics>, Habit>((ref, habit) {
  final logsAsync = ref.watch(habitHistoryProvider(habit.id));
  
  return logsAsync.whenData((logs) {
    return StreakCalculator.calculate(habit, logs);
  });
});

final habitCompletionRateProvider = Provider<double?>((ref) {
  final habitsAsync = ref.watch(habitsListProvider);
  final todayLogsAsync = ref.watch(todayHabitLogsProvider);
  
  if (habitsAsync is AsyncData && todayLogsAsync is AsyncData) {
    final habits = habitsAsync.value!;
    final logs = todayLogsAsync.value!;
    
    if (habits.isEmpty) return null;
    
    final completedCount = logs.where((l) => l.isCompleted).length;
    return completedCount / habits.length;
  }
  return null;
});
