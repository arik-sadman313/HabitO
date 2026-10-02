import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habito/core/database/app_database.dart' as db;
import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/activities/data/activity_repository.dart';
import 'package:habito/features/auth/presentation/auth_notifier.dart';

// Provides the repository
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final database = db.AppDatabase();
  return ActivityRepositoryImpl(database);
});

// The currently selected date for the Today view
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void updateDate(DateTime date) {
    state = date;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(() {
  return SelectedDateNotifier();
});

// Provides the list of activities for the selected date
final activitiesForDateProvider = StreamProvider<List<Activity>>((ref) {
  final date = ref.watch(selectedDateProvider);
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(activityRepositoryProvider);
  return repo.watchActivitiesForDate(userId, date);
});

// Calculates the daily completion percentage (0.0 to 1.0)
final dailyCompletionProvider = Provider<double?>((ref) {
  final activitiesAsync = ref.watch(activitiesForDateProvider);
  
  return activitiesAsync.when(
    data: (activities) {
      if (activities.isEmpty) return null; // Distinguish no activities from 0%
      final completed = activities.where((a) => a.isCompleted).length;
      return completed / activities.length;
    },
    loading: () => null,
    error: (e, st) => null,
  );
});
