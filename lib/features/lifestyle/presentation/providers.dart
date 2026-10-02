import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/lifestyle/data/lifestyle_repositories.dart';

// --- Repositories ---

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepositoryImpl(db.AppDatabase());
});

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  return SleepRepositoryImpl(db.AppDatabase());
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepositoryImpl(db.AppDatabase());
});

// --- Today Providers ---

final todayMealsProvider = StreamProvider<List<Meal>>((ref) {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return Stream.value([]);
  return ref.watch(mealRepositoryProvider).watchMealsForDate(userId, DateTime.now());
});

final todaySleepProvider = StreamProvider<List<SleepRecord>>((ref) {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return Stream.value([]);
  return ref.watch(sleepRepositoryProvider).watchSleepForDate(userId, DateTime.now());
});

final todayExerciseProvider = StreamProvider<List<ExerciseSession>>((ref) {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return Stream.value([]);
  return ref.watch(exerciseRepositoryProvider).watchExerciseForDate(userId, DateTime.now());
});

// --- Summaries ---

final todayExerciseDurationProvider = Provider<Duration>((ref) {
  final sessions = ref.watch(todayExerciseProvider).value ?? [];
  final totalSeconds = sessions.fold(0, (sum, session) => sum + session.duration);
  return Duration(seconds: totalSeconds);
});
