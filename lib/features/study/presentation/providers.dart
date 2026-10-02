import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/study/data/study_repository.dart';
import 'package:habito/features/study/presentation/timer_notifier.dart';

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  final database = db.AppDatabase();
  return StudyRepositoryImpl(database);
});

final studySubjectsProvider = StreamProvider<List<StudySubject>>((ref) {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return Stream.value([]);
  
  return ref.watch(studyRepositoryProvider).watchSubjects(userId);
});

final todayStudySessionsProvider = StreamProvider<List<StudySession>>((ref) {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return Stream.value([]);
  
  return ref.watch(studyRepositoryProvider).watchSessionsForDate(userId, DateTime.now());
});

final todayStudyTotalDurationProvider = Provider<Duration>((ref) {
  final sessionsAsync = ref.watch(todayStudySessionsProvider);
  final sessions = sessionsAsync.value ?? [];
  
  int totalSeconds = sessions.fold(0, (sum, session) => sum + session.duration);
  return Duration(seconds: totalSeconds);
});

// A hardcoded simple goal for Phase 6 MVP
final dailyStudyGoalProvider = Provider<Duration>((ref) {
  return const Duration(hours: 3);
});

final studyTimerProvider = NotifierProvider<StudyTimerNotifier, StudyTimerState>(() {
  return StudyTimerNotifier();
});
