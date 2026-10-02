import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/goals/data/personal_goal_repository.dart';
import 'package:habito/features/goals/domain/goal_progress_service.dart';
import 'package:habito/features/study/presentation/providers.dart';
import 'package:habito/features/lifestyle/presentation/providers.dart';
import 'package:habito/features/screen_time/presentation/providers.dart';
import 'package:habito/features/trackers/presentation/providers.dart';
import 'package:habito/features/activities/presentation/providers.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final personalGoalRepositoryProvider = Provider<PersonalGoalRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PersonalGoalRepositoryImpl(db);
});

final goalProgressServiceProvider = Provider<GoalProgressService>((ref) {
  return GoalProgressService(
    ref.watch(studyRepositoryProvider),
    ref.watch(exerciseRepositoryProvider),
    ref.watch(sleepRepositoryProvider),
    ref.watch(screenTimeRepositoryProvider),
  );
});

final activeGoalsProvider = StreamProvider.autoDispose<List<PersonalGoal>>((ref) {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return const Stream.empty();
  return ref.watch(personalGoalRepositoryProvider).watchActiveGoals(userId);
});

final completedGoalsProvider = StreamProvider.autoDispose<List<PersonalGoal>>((ref) {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return const Stream.empty();
  return ref.watch(personalGoalRepositoryProvider).watchCompletedGoals(userId);
});

final goalByIdProvider = StreamProvider.family.autoDispose<PersonalGoal?, String>((ref, id) {
  return ref.watch(personalGoalRepositoryProvider).watchGoal(id);
});

final goalProgressProvider = FutureProvider.family.autoDispose<GoalProgress, PersonalGoal>((ref, goal) {
  return ref.watch(goalProgressServiceProvider).calculateProgress(goal);
});
