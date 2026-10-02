import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';
import 'package:habito/features/wellbeing/data/mood_repository.dart';

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  return MoodRepositoryImpl(db.AppDatabase());
});

final todayMoodProvider = StreamProvider<MoodLog?>((ref) {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return Stream.value(null);

  final repo = ref.watch(moodRepositoryProvider);
  return repo.watchCheckInForDate(userId, DateTime.now());
});

final moodHistoryProvider = StreamProvider.family<List<MoodLog>, int>((ref, days) {
  final userId = ref.watch(authNotifierProvider).user?.id;
  if (userId == null) return Stream.value([]);

  final repo = ref.watch(moodRepositoryProvider);
  return repo.watchMoodHistory(userId, days);
});
