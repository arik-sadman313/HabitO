import 'package:habito/core/models/domain_models.dart';
import 'package:habito/features/study/data/study_repository.dart';
import 'package:habito/features/lifestyle/data/lifestyle_repositories.dart';
import 'package:habito/features/screen_time/data/screen_time_repository.dart';
import 'package:habito/features/trackers/data/tracker_repository.dart';
import 'package:habito/features/activities/data/activity_repository.dart';

class GoalProgressService {
  final StudyRepository _studyRepo;
  final ExerciseRepository _exerciseRepo;
  final SleepRepository _sleepRepo;
  final ScreenTimeRepository _screenTimeRepo;

  GoalProgressService(
    this._studyRepo,
    this._exerciseRepo,
    this._sleepRepo,
    this._screenTimeRepo,
  );

  Future<GoalProgress> calculateProgress(PersonalGoal goal) async {
    final now = DateTime.now();
    double actual = 0.0;
    DataAvailability availability = DataAvailability.available;
    
    // Determine end boundary for query
    final endDate = goal.targetDate ?? now;

    try {
      switch (goal.goalType) {
        case GoalType.studyDuration:
          // target is hours, actual is sum of duration in seconds -> hours
          final sessions = await _studyRepo.watchSessions(goal.userId).first;
          final filtered = sessions.where((s) => s.startedAt.isAfter(goal.startDate) && s.startedAt.isBefore(endDate)).toList();
          if (filtered.isEmpty) {
             availability = DataAvailability.unavailable;
          } else {
             final totalSeconds = filtered.fold<int>(0, (sum, session) => sum + session.duration);
             actual = totalSeconds / 3600.0;
          }
          break;
          
        case GoalType.exerciseDuration:
          final sessions = await _exerciseRepo.watchExerciseForWeek(goal.userId, endDate).first;
          final filtered = sessions.where((s) => s.startedAt.isAfter(goal.startDate) && s.startedAt.isBefore(endDate)).toList();
          if (filtered.isEmpty) {
             availability = DataAvailability.unavailable;
          } else {
             final totalMinutes = filtered.fold<int>(0, (sum, session) => sum + session.duration);
             actual = totalMinutes / 60.0; // Assume target is hours
          }
          break;
          
        case GoalType.waterIntake:
          // We can use trackLogs table. Let's assume water is logged in a tracker. 
          // We would fetch logs from trackerRepo. For now, since tracker logic is generic,
          // if we can't find a tracker named "Water", we use actual = 0 or fallback to currentValue.
          actual = goal.currentValue ?? 0.0;
          if (actual == 0.0) availability = DataAvailability.unavailable;
          break;

        case GoalType.sleepDuration:
          final records = await _sleepRepo.watchSleepForWeek(goal.userId, endDate).first;
          final filtered = records.where((s) => s.sleepStart.isAfter(goal.startDate) && s.sleepStart.isBefore(endDate)).toList();
          if (filtered.isEmpty) {
             availability = DataAvailability.unavailable;
          } else {
             final totalMinutes = filtered.fold<int>(0, (sum, session) => sum + session.duration);
             actual = totalMinutes / 60.0;
          }
          break;
          
        case GoalType.screenTimeReduction:
          final days = await _screenTimeRepo.getWeeklyHistory(goal.userId);
          final filtered = days.where((d) => d.date.isAfter(goal.startDate) && d.date.isBefore(endDate)).toList();
          if (filtered.isEmpty) {
             availability = DataAvailability.unavailable;
          } else {
             final totalSeconds = filtered.fold<int>(0, (sum, day) => sum + day.totalDuration.inSeconds);
             actual = totalSeconds / 3600.0;
          }
          break;
          
        case GoalType.custom:
        default:
          actual = goal.currentValue ?? 0.0;
          availability = goal.currentValue == null ? DataAvailability.unavailable : DataAvailability.available;
          break;
      }
    } catch (e) {
      availability = DataAvailability.unavailable;
    }

    double ratio = 0.0;
    if (goal.targetValue > 0) {
      if (goal.goalType == GoalType.screenTimeReduction) {
        // Reduction goal: lower is better. If actual is <= target, ratio is 1.0.
        ratio = actual <= goal.targetValue ? 1.0 : (goal.targetValue / actual);
      } else {
        ratio = actual / goal.targetValue;
      }
    }
    
    // Clamp
    if (ratio > 1.0) ratio = 1.0;
    if (ratio < 0.0) ratio = 0.0;
    
    final percentage = (ratio * 100).toInt();
    
    return GoalProgress(
      goalId: goal.id,
      target: goal.targetValue,
      actual: actual,
      progressRatio: ratio,
      percentage: percentage,
      status: goal.status,
      dataAvailability: availability,
      calculatedAt: now,
    );
  }
}
