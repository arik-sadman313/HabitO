import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/study/presentation/providers.dart';
import 'package:habito/features/lifestyle/presentation/providers.dart';
import 'package:habito/features/screen_time/presentation/providers.dart';
import 'package:habito/features/wellbeing/presentation/providers.dart';

class AnalyticsPeriodNotifier extends Notifier<AnalyticsPeriod> {
  @override
  AnalyticsPeriod build() {
    return AnalyticsPeriod.last7Days;
  }

  void setPeriod(AnalyticsPeriod period) {
    state = period;
  }
}

final analyticsPeriodProvider = NotifierProvider<AnalyticsPeriodNotifier, AnalyticsPeriod>(() => AnalyticsPeriodNotifier());

final studyAnalyticsProvider = FutureProvider.autoDispose<List<StudySession>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  final period = ref.watch(analyticsPeriodProvider);
  final days = period == AnalyticsPeriod.last7Days ? 7 : (period == AnalyticsPeriod.last30Days ? 30 : 90);
  final start = DateTime.now().subtract(Duration(days: days));
  final repo = ref.watch(studyRepositoryProvider);
  final sessions = await repo.watchSessions(userId).first;
  return sessions.where((s) => s.startedAt.isAfter(start)).toList();
});

final lifestyleAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return {};
  final period = ref.watch(analyticsPeriodProvider);
  final days = period == AnalyticsPeriod.last7Days ? 7 : (period == AnalyticsPeriod.last30Days ? 30 : 90);
  final start = DateTime.now().subtract(Duration(days: days));
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);
  final sleepRepo = ref.watch(sleepRepositoryProvider);
  
  final exercises = await exerciseRepo.watchExerciseForWeek(userId, DateTime.now()).first;
  final filteredExercises = exercises.where((s) => s.startedAt.isAfter(start)).toList();
  
  final sleep = await sleepRepo.watchSleepForWeek(userId, DateTime.now()).first;
  final filteredSleep = sleep.where((s) => s.sleepStart.isAfter(start)).toList();
  
  return {
    'exercises': filteredExercises,
    'sleep': filteredSleep,
  };
});

final wellbeingAnalyticsProvider = FutureProvider.autoDispose<List<MoodLog>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  final period = ref.watch(analyticsPeriodProvider);
  final days = period == AnalyticsPeriod.last7Days ? 7 : (period == AnalyticsPeriod.last30Days ? 30 : 90);
  final start = DateTime.now().subtract(Duration(days: days));
  final repo = ref.watch(moodRepositoryProvider);
  final logs = await repo.watchMoodHistory(userId, days).first;
  return logs.where((l) => l.date.isAfter(start)).toList();
});

final screenTimeAnalyticsProvider = FutureProvider.autoDispose<List<ScreenTimeDay>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return [];
  final period = ref.watch(analyticsPeriodProvider);
  final days = period == AnalyticsPeriod.last7Days ? 7 : (period == AnalyticsPeriod.last30Days ? 30 : 90);
  final start = DateTime.now().subtract(Duration(days: days));
  final repo = ref.watch(screenTimeRepositoryProvider);
  final logs = await repo.getWeeklyHistory(userId);
  return logs.where((l) => l.date.isAfter(start)).toList();
});
